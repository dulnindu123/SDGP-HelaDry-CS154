#include <Arduino.h>
#include <WiFi.h>
#include <time.h>
#include <sys/time.h>
#include <Preferences.h>

#include <Wire.h>
#include <HX711.h>

#include <Adafruit_BME280.h>
#include <BH1750.h>

#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// ========================= USER CONFIG =========================
// WiFi
static const char* WIFI_SSID = "YOUR_WIFI_SSID";
static const char* WIFI_PASS = "YOUR_WIFI_PASSWORD";

// Firebase (Realtime Database)
static const char* API_KEY = "YOUR_FIREBASE_WEB_API_KEY";
static const char* DATABASE_URL = "https://YOUR_PROJECT_ID-default-rtdb.asia-southeast1.firebasedatabase.app/";

// Auth (Email/Password user in Firebase Auth)
static const char* USER_EMAIL = "device@heladry.com";
static const char* USER_PASSWORD = "YOUR_DEVICE_PASSWORD";

// Device ID (used as DB node)
static const char* DEVICE_ID = "heladry_01";
// ===============================================================

// ========================= PINOUT =========================
// Required by your spec
static const int PIN_HX_DT  = 18;
static const int PIN_HX_SCK = 19;

// Relay control
static const int PIN_RELAY_FAN    = 25; // fan relay input
static const int PIN_RELAY_HEATER = 26; // heater relay input (change if needed)

// I2C pins (ESP32 defaults)
static const int PIN_I2C_SDA = 21;
static const int PIN_I2C_SCL = 22;
// =========================================================

// ========================= TIMING =========================
static const uint32_t READ_INTERVAL_MS = 5000;   // read sensors every 5s
static const uint32_t COMMAND_POLL_MS  = 800;    // poll commands when stream not used / as backup
static const uint32_t WIFI_RETRY_MS    = 8000;   // retry WiFi every 8s if disconnected
// =========================================================

// ========================= FILTER =========================
static const size_t MA_WINDOW = 10; // 10 samples => smoother
float maBuf[MA_WINDOW];
size_t maIdx = 0;
size_t maCount = 0;
// =========================================================

// ========================= NVS =========================
Preferences prefs;
static const char* NVS_NS = "heladry";
static const char* NVS_KEY_CAL = "cal_factor";
static const char* NVS_KEY_RELAYLOW = "relay_low";
// =======================================================

// ========================= OBJECTS =========================
HX711 scale;
Adafruit_BME280 bme;
BH1750 lightMeter;

FirebaseData fbdo;
FirebaseData stream;
FirebaseAuth auth;
FirebaseConfig config;
// ==========================================================

// ========================= STATE =========================
float calibrationFactor = -7050.0f;  // default; overwrite via Firebase/NVS
bool relayActiveLow = true;          // many relay boards are active-low

bool fanOn = false;
bool heaterOn = false;

bool sessionActive = false;
float initialWeight_g = 0.0f;

uint32_t lastReadMs = 0;
uint32_t lastCmdPollMs = 0;
uint32_t lastWifiAttemptMs = 0;

// Stall detection (auto fan)
float minDrop_g_per_min = 1.0f; // expected minimum drying drop per minute
int stallMinutes = 5;           // window duration for stall detection
uint32_t lastTrendCheckMs = 0;
float lastTrendWeight_g = 0.0f;
// =========================================================

// ========================= HELPERS =========================
static String rootPath() {
  return String("/devices/") + DEVICE_ID;
}

static void logFirebaseError(FirebaseData &d, const char* ctx) {
  String reason = d.errorReason();
  Serial.printf("[Firebase] %s failed: %s\n", ctx, reason.c_str()); // fixed c_str usage
}

static void setRelayPin(int pin, bool on) {
  // Active-low relay: ON = LOW, OFF = HIGH
  if (relayActiveLow) digitalWrite(pin, on ? LOW : HIGH);
  else                digitalWrite(pin, on ? HIGH : LOW);
}

static void setFan(bool on) {
  fanOn = on;
  setRelayPin(PIN_RELAY_FAN, on);
}

static void setHeater(bool on) {
  heaterOn = on;
  setRelayPin(PIN_RELAY_HEATER, on);
}

static void ensureTime() {
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  for (int i = 0; i < 25; i++) {
    time_t now = time(nullptr);
    if (now > 1700000000) {
      Serial.println("[TIME] NTP synced");
      return;
    }
    delay(200);
  }
  Serial.println("[TIME] NTP not synced yet (will continue).");
}

static uint64_t nowEpochMs() {
  struct timeval tv;
  gettimeofday(&tv, nullptr);
  return (uint64_t)tv.tv_sec * 1000ULL + (uint64_t)(tv.tv_usec / 1000ULL);
}

static String nowISO8601() {
  time_t now = time(nullptr);
  struct tm t;
  gmtime_r(&now, &t);
  char buf[25];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &t);
  return String(buf);
}

static void wifiEnsureConnected() {
  if (WiFi.status() == WL_CONNECTED) return;

  uint32_t now = millis();
  if (now - lastWifiAttemptMs < WIFI_RETRY_MS) return;
  lastWifiAttemptMs = now;

  Serial.printf("[WiFi] Connecting to %s ...\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  uint32_t start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 12000) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[WiFi] Connected: %s\n", WiFi.localIP().toString().c_str());
    ensureTime();
  } else {
    Serial.println("[WiFi] Still not connected (will retry).");
  }
}

static float movingAverage(float x) {
  maBuf[maIdx] = x;
  maIdx = (maIdx + 1) % MA_WINDOW;
  if (maCount < MA_WINDOW) maCount++;

  float sum = 0;
  for (size_t i = 0; i < maCount; i++) sum += maBuf[i];
  return sum / (float)maCount;
}

static void loadSettingsFromNVS() {
  prefs.begin(NVS_NS, true);
  if (prefs.isKey(NVS_KEY_CAL)) {
    calibrationFactor = prefs.getFloat(NVS_KEY_CAL, calibrationFactor);
  }
  if (prefs.isKey(NVS_KEY_RELAYLOW)) {
    relayActiveLow = prefs.getBool(NVS_KEY_RELAYLOW, relayActiveLow);
  }
  prefs.end();

  Serial.printf("[NVS] calibrationFactor=%.4f relayActiveLow=%s\n",
                calibrationFactor, relayActiveLow ? "true" : "false");
}

static void saveCalibrationToNVS(float cf) {
  prefs.begin(NVS_NS, false);
  prefs.putFloat(NVS_KEY_CAL, cf);
  prefs.end();
}

static void saveRelayLogicToNVS(bool activeLow) {
  prefs.begin(NVS_NS, false);
  prefs.putBool(NVS_KEY_RELAYLOW, activeLow);
  prefs.end();
}

static bool firebaseReady() {
  return (WiFi.status() == WL_CONNECTED) && Firebase.ready();
}

static void firebaseInit() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  config.token_status_callback = tokenStatusCallback;

  Firebase.reconnectNetwork(true);
  fbdo.setResponseSize(4096);
  stream.setResponseSize(4096);

  Firebase.begin(&config, &auth);
}

// Push /live values (overwrite)
static void pushLive(float wRaw, float wFilt, float progress,
                     float tempC, float humPct, float lux) {
  String base = rootPath() + "/live";

  FirebaseJson json;
  json.set("weight_g_raw", wRaw);
  json.set("weight_g", wFilt);
  json.set("progress_pct", progress);
  json.set("fan_on", fanOn);
  json.set("heater_on", heaterOn);
  json.set("temp_c", tempC);
  json.set("hum_pct", humPct);
  json.set("lux", lux);
  json.set("timestamp_ms", (uint64_t)nowEpochMs());
  json.set("timestamp_iso", nowISO8601());

  if (!Firebase.RTDB.setJSON(&fbdo, base.c_str(), &json)) {
    logFirebaseError(fbdo, "setJSON(/live)");
  }
}

// Push /history log (append)
static void pushHistory(float wFilt, float progress,
                        float tempC, float humPct, float lux) {
  String base = rootPath() + "/history";

  FirebaseJson json;
  json.set("weight_g", wFilt);
  json.set("progress_pct", progress);
  json.set("fan_on", fanOn);
  json.set("heater_on", heaterOn);
  json.set("temp_c", tempC);
  json.set("hum_pct", humPct);
  json.set("lux", lux);
  json.set("timestamp_ms", (uint64_t)nowEpochMs());
  json.set("timestamp_iso", nowISO8601());

  if (!Firebase.RTDB.pushJSON(&fbdo, base.c_str(), &json)) {
    logFirebaseError(fbdo, "pushJSON(/history)");
  }
}

static float computeProgress(float current_g) {
  if (!sessionActive || initialWeight_g <= 0.1f) return 0.0f;
  float pct = (1.0f - (current_g / initialWeight_g)) * 100.0f;
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return pct;
}

// ===================== COMMAND HANDLING =====================
// Commands node: /devices/<id>/commands
static void handleCommandsOnce() {
  if (!firebaseReady()) return;

  String base = rootPath() + "/commands";

  // One-shot tare
  if (Firebase.RTDB.getBool(&fbdo, (base + "/tare").c_str())) {
    bool trig = fbdo.boolData();
    if (trig) {
      Serial.println("[CMD] tare");
      scale.tare();
      initialWeight_g = 0.0f;
      Firebase.RTDB.setBool(&fbdo, (base + "/tare").c_str(), false);
      Firebase.RTDB.setFloat(&fbdo, (rootPath() + "/session/initial_weight_g").c_str(), 0.0f);
    }
  }

  // Start session one-shot -> capture initial weight
  if (Firebase.RTDB.getBool(&fbdo, (base + "/start_session").c_str())) {
    bool trig = fbdo.boolData();
    if (trig) {
      sessionActive = true;
      float w = movingAverage(scale.get_units(10));
      if (fabs(w) < 1.0f) w = 0.0f;
      initialWeight_g = w > 0.1f ? w : 0.0f;
      Serial.printf("[CMD] start_session -> initialWeight=%.2f\n", initialWeight_g);

      Firebase.RTDB.setBool(&fbdo, (base + "/start_session").c_str(), false);
      Firebase.RTDB.setBool(&fbdo, (rootPath() + "/session/active").c_str(), sessionActive);
      Firebase.RTDB.setFloat(&fbdo, (rootPath() + "/session/initial_weight_g").c_str(), initialWeight_g);

      lastTrendCheckMs = 0; // reset stall state
    }
  }

  // Stop session
  if (Firebase.RTDB.getBool(&fbdo, (base + "/stop_session").c_str())) {
    bool trig = fbdo.boolData();
    if (trig) {
      Serial.println("[CMD] stop_session");
      sessionActive = false;
      initialWeight_g = 0.0f;
      setFan(false);
      setHeater(false);

      Firebase.RTDB.setBool(&fbdo, (base + "/stop_session").c_str(), false);
      Firebase.RTDB.setBool(&fbdo, (rootPath() + "/session/active").c_str(), sessionActive);
      Firebase.RTDB.setFloat(&fbdo, (rootPath() + "/session/initial_weight_g").c_str(), 0.0f);

      lastTrendCheckMs = 0;
    }
  }

  // Manual controls (continuous)
  if (Firebase.RTDB.getBool(&fbdo, (base + "/manual_fan").c_str())) {
    setFan(fbdo.boolData());
  }
  if (Firebase.RTDB.getBool(&fbdo, (base + "/manual_heater").c_str())) {
    setHeater(fbdo.boolData());
  }

  // One-shot manual trigger (if true => turn ON then reset false)
  if (Firebase.RTDB.getBool(&fbdo, (base + "/manual_fan_trigger").c_str())) {
    bool trig = fbdo.boolData();
    if (trig) {
      Serial.println("[CMD] manual_fan_trigger -> Fan ON");
      setFan(true);
      Firebase.RTDB.setBool(&fbdo, (base + "/manual_fan_trigger").c_str(), false);
    }
  }

  // Settings pull (optional poll)
  if (Firebase.RTDB.getFloat(&fbdo, (rootPath() + "/settings/calibration_factor").c_str())) {
    float cf = fbdo.floatData();
    if (isfinite(cf) && fabs(cf) > 0.01f && cf != calibrationFactor) {
      calibrationFactor = cf;
      scale.set_scale(calibrationFactor);
      saveCalibrationToNVS(calibrationFactor);
      Serial.printf("[SET] calibrationFactor updated: %.4f\n", calibrationFactor);
    }
  }

  if (Firebase.RTDB.getBool(&fbdo, (rootPath() + "/settings/relay_active_low").c_str())) {
    bool v = fbdo.boolData();
    if (v != relayActiveLow) {
      relayActiveLow = v;
      saveRelayLogicToNVS(relayActiveLow);
      setFan(fanOn);
      setHeater(heaterOn);
      Serial.printf("[SET] relayActiveLow=%s\n", relayActiveLow ? "true" : "false");
    }
  }

  if (Firebase.RTDB.getFloat(&fbdo, (rootPath() + "/settings/min_drop_g_per_min").c_str())) {
    float v = fbdo.floatData();
    if (isfinite(v) && v >= 0.0f) minDrop_g_per_min = v;
  }

  if (Firebase.RTDB.getInt(&fbdo, (rootPath() + "/settings/stall_minutes").c_str())) {
    int v = fbdo.intData();
    if (v >= 1 && v <= 60) stallMinutes = v;
  }
}
// ============================================================

// ========================= SENSOR READ =========================
static bool bmeOk = false;
static bool bhOk  = false;

static void initSensors() {
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);

  bmeOk = bme.begin(0x76);
  if (!bmeOk) {
    bmeOk = bme.begin(0x77);
  }
  Serial.printf("[BME280] %s\n", bmeOk ? "OK" : "NOT FOUND");

  bhOk = lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
  Serial.printf("[BH1750] %s\n", bhOk ? "OK" : "NOT FOUND");
}
// =============================================================

// ========================= SETUP/LOOP =========================
void setup() {
  Serial.begin(115200);
  delay(200);

  // Relay pins
  pinMode(PIN_RELAY_FAN, OUTPUT);
  pinMode(PIN_RELAY_HEATER, OUTPUT);

  // Default OFF safely (assume active-low first; corrected after NVS load)
  digitalWrite(PIN_RELAY_FAN, HIGH);
  digitalWrite(PIN_RELAY_HEATER, HIGH);

  loadSettingsFromNVS();

  // Apply safe OFF with correct logic
  setFan(false);
  setHeater(false);

  // WiFi + time
  wifiEnsureConnected();

  // HX711
  scale.begin(PIN_HX_DT, PIN_HX_SCK);
  scale.set_scale(calibrationFactor);
  scale.tare();
  Serial.printf("[HX711] scale ready, cal=%.4f\n", calibrationFactor);

  initSensors();

  // Firebase
  firebaseInit();

  // Initialize DB defaults (optional)
  if (firebaseReady()) {
    Firebase.RTDB.setBool(&fbdo, (rootPath() + "/session/active").c_str(), false);
    Firebase.RTDB.setFloat(&fbdo, (rootPath() + "/session/initial_weight_g").c_str(), 0.0f);
  }

  Serial.println("[SYSTEM] Ready");
}

void loop() {
  wifiEnsureConnected();

  // Keep Firebase token/network healthy
  // (Firebase.reconnectNetwork(true) is already enabled)
  if (firebaseReady()) {
    // Backup command poll (simple + reliable)
    uint32_t now = millis();
    if (now - lastCmdPollMs >= COMMAND_POLL_MS) {
      lastCmdPollMs = now;
      handleCommandsOnce();
    }
  }

  // Periodic sensor read + push
  uint32_t now = millis();
  if (now - lastReadMs >= READ_INTERVAL_MS) {
    lastReadMs = now;

    if (!scale.is_ready()) {
      Serial.println("[HX711] not ready");
      return;
    }

    float wRaw = scale.get_units(5);
    float wFilt = movingAverage(wRaw);

    // Optional: clamp tiny noise to 0
    if (fabs(wFilt) < 0.5f) wFilt = 0.0f;

    float tempC = NAN, humPct = NAN, lux = NAN;
    if (bmeOk) {
      tempC = bme.readTemperature();
      humPct = bme.readHumidity();
    }
    if (bhOk) {
      lux = lightMeter.readLightLevel();
    }

    // If session active and initial not set, capture a reasonable initial weight
    if (sessionActive && initialWeight_g <= 0.1f && wFilt > 1.0f) {
      initialWeight_g = wFilt;
      Serial.printf("[SESSION] initialWeight auto-set: %.2f g\n", initialWeight_g);
      if (firebaseReady()) {
        Firebase.RTDB.setFloat(&fbdo, (rootPath() + "/session/initial_weight_g").c_str(), initialWeight_g);
      }
      lastTrendCheckMs = 0;
    }

    float progress = computeProgress(wFilt);

    // Auto stall detection -> fan on
    if (sessionActive) {
      if (lastTrendCheckMs == 0) {
        lastTrendCheckMs = now;
        lastTrendWeight_g = wFilt;
      } else {
        uint32_t elapsed = now - lastTrendCheckMs;
        uint32_t windowMs = (uint32_t)stallMinutes * 60UL * 1000UL;
        if (elapsed >= windowMs) {
          float delta = wFilt - lastTrendWeight_g; // should be negative if drying
          float mins = (float)elapsed / 60000.0f;
          float dropPerMin = (-delta) / (mins > 0.01f ? mins : 1.0f);

          Serial.printf("[STALL] delta=%.2f g over %.2f min => drop/min=%.3f g (min=%.3f)\n",
                        delta, mins, dropPerMin, minDrop_g_per_min);

          if (dropPerMin < minDrop_g_per_min) {
            Serial.println("[AUTO] stall detected -> Fan ON");
            setFan(true);
          }

          lastTrendCheckMs = now;
          lastTrendWeight_g = wFilt;
        }
      }
    } else {
      lastTrendCheckMs = 0;
      lastTrendWeight_g = 0;
    }

    // Firebase pushes
    if (firebaseReady()) {
      pushLive(wRaw, wFilt, progress, tempC, humPct, lux);
      pushHistory(wFilt, progress, tempC, humPct, lux);
    }

    Serial.printf("[DATA] raw=%.2f g filt=%.2f g prog=%.1f%% fan=%s heater=%s\n",
                  wRaw, wFilt, progress,
                  fanOn ? "ON" : "OFF",
                  heaterOn ? "ON" : "OFF");
  }

  delay(5);
}