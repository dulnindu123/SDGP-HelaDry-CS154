/*
 * ============================================================
 *  HelaDry Firmware v2.1.6
 *  ESP32 — BLE + WiFi + Firebase + Sensors + Session Control
 * ============================================================
 *
 *  Features:
 *    - BLE service (advertised as HELADRY-xxxx)
 *    - BLE characteristics for state notification, commands, ACKs
 *    - Wi-Fi provisioning via BLE (SET_WIFI_CREDS command)
 *    - Wi-Fi auto-reconnect with Preferences-stored credentials
 *    - Session state machine: IDLE → RUNNING → PAUSED → FINISHED
 *    - Safety: over-temp alert (>75°C), low-battery (<11.5V), sensor fault
 *    - Fan PWM control 0–100%
 *    - Heater auto/manual relay control
 *    - LittleFS offline batch logging with Firebase sync
 *    - Firebase RTDB live + history push
 *    - HX711 load cell, BME280, BH1750 sensors
 *    - Battery ADC monitoring
 */

#include <Arduino.h>
#include <WiFi.h>
#include <Wire.h>
#include <Preferences.h>
#include <LittleFS.h>
#include <ArduinoJson.h>

// BLE
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Sensors
#include <HX711.h>
#include <Adafruit_BME280.h>
#include <BH1750.h>

// Firebase
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// Secrets
#include <secrets.h>

// Forward declarations
static void firebaseInitIfWiFi();
static void wifiMaintain();
static void bleMaintainAdvertising();

// ========================= FIRMWARE VERSION =========================
#define FW_VERSION "2.1.6"

// ========================= DEVICE =========================
// DEVICE_ID is now handled dynamically using bleDeviceName
#define BOOT_BTN  0

// ========================= PINOUT =========================
static const int PIN_I2C_SDA      = 21;
static const int PIN_I2C_SCL      = 22;
static const int PIN_HX_DT        = 18;
static const int PIN_HX_SCK       = 19;
static const int PIN_RELAY_HEATER = 26;
static const int PIN_FAN_PWM      = 25;   // PWM output for fan
static const int PIN_BAT_ADC      = 34;

// Fan PWM config
static const int   FAN_PWM_CHANNEL = 0;
static const int   FAN_PWM_FREQ    = 25000; // 25 kHz
static const int   FAN_PWM_RES     = 8;     // 8-bit (0–255)

// Relay logic
static const bool RELAY_ACTIVE_LOW = true;

// ========================= SAFETY THRESHOLDS =========================
static const float OVER_TEMP_THRESHOLD_C   = 75.0f;
static const float LOW_BATTERY_THRESHOLD_V = 11.5f;

// ========================= TIMING =========================
static const uint32_t SENSOR_READ_INTERVAL_MS    = 2000;
static const uint32_t FIREBASE_PUSH_INTERVAL_MS  = 5000;
static const uint32_t COMMAND_POLL_INTERVAL_MS   = 2000;
static const uint32_t BLE_NOTIFY_INTERVAL_MS     = 1000;
static const uint32_t WIFI_RECONNECT_INTERVAL_MS = 10000;
static const uint32_t LOG_SYNC_INTERVAL_MS       = 30000;
static const uint32_t WIFI_CONNECT_TIMEOUT_MS    = 15000;

// HX711 smoothing
static const size_t MA_WINDOW = 10;

// Heater hysteresis
static const float HEAT_HYST_C = 2.0f;

// ========================= BLE UUIDs =========================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define STATE_CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define ACK_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26aa"

// ========================= SESSION STATES =========================
enum SessionState {
  SESSION_IDLE,
  SESSION_RUNNING,
  SESSION_PAUSED,
  SESSION_FINISHED
};

static const char* sessionStateStr(SessionState s) {
  switch (s) {
    case SESSION_IDLE:     return "IDLE";
    case SESSION_RUNNING:  return "RUNNING";
    case SESSION_PAUSED:   return "PAUSED";
    case SESSION_FINISHED: return "FINISHED";
    default:               return "UNKNOWN";
  }
}

// ========================= ALERT FLAGS =========================
struct AlertFlags {
  bool overTemp;
  bool lowBattery;
  bool sensorFault;
};

// ========================= GLOBALS =========================
// Sensors
HX711           scale;
Adafruit_BME280 bme;
BH1750          lightMeter;
bool bme_ok = false;
bool bh_ok  = false;

// Firebase
FirebaseData   fbdo;
FirebaseAuth   fbAuth;
FirebaseConfig fbConfig;
static bool firebaseInitialized = false;

// Preferences (NVS)
Preferences prefs;

// Weight state
static float calibration_factor = -7050.0f;
static float initialWeight_g    = 0.0f;
static float currentWeight_g    = 0.0f;
static float filteredWeight_g   = 0.0f;

// Sensor state
static float temp_c    = NAN;
static float hum_pct   = NAN;
static float pres_hpa  = NAN;
static float lux_val   = NAN;
static float battery_v = NAN;

static float temp_offset = 0.0f;
static float hum_offset  = 0.0f;

// Control state
static bool    heater_on     = false;
static uint8_t fan_speed_pct = 0;   // 0–100

// Modes
static bool  manual_heater_mode = false;
static bool  auto_heat_enabled  = false;
static float target_temp_c      = 35.0f;

// Session state
static SessionState sessionState     = SESSION_IDLE;
static String       sessionCropName  = "";
static float        sessionTargetTemp = 50.0f;
static uint32_t     sessionStartMs   = 0;

// Alerts
static AlertFlags alerts = { false, false, false };

// Moving average buffer
static float  ma_buf[MA_WINDOW];
static size_t ma_idx   = 0;
static size_t ma_count = 0;

// Timers
static uint32_t lastSensorReadMs   = 0;
static uint32_t lastFirebasePushMs = 0;
static uint32_t lastCommandPollMs  = 0;
static uint32_t lastBleNotifyMs    = 0;
static uint32_t lastWiFiTryMs      = 0;
static uint32_t lastLogSyncMs      = 0;

// BLE
static BLEServer         *pServer       = nullptr;
static BLECharacteristic *pStateChar    = nullptr;
static BLECharacteristic *pCommandChar  = nullptr;
static BLECharacteristic *pAckChar      = nullptr;
static bool               bleConnected  = false;
static bool               bleAdvertising = false;
static String             bleDeviceName = "HELADRY-0000";
static String             deviceId = "";

// WiFi state
static bool wifiConnected = false;
static bool pendingWifiScan = false;
static bool pendingWifiConnect = false;
static uint32_t wifiConnectStartMs = 0;
static String provisioningSsid = "";
static String provisioningPass = "";
static bool     scanResultPending = false;
static uint32_t scanStartMs       = 0;

// LittleFS logging
static bool littlefs_ok = false;
static int  logFileIndex = 0;

// ========================= HELPERS =========================
static uint32_t nowMs() { return millis(); }

static String buildRootPath()    { return String("/devices/") + deviceId; }
static String buildPathLive()    { return buildRootPath() + "/live"; }
static String buildPathHistory() { return buildRootPath() + "/history"; }
static String buildPathCommands(){ return buildRootPath() + "/commands"; }
static String buildPathConfig()  { return buildRootPath() + "/config"; }

static void relayWrite(int pin, bool on) {
  if (RELAY_ACTIVE_LOW) digitalWrite(pin, on ? LOW : HIGH);
  else                  digitalWrite(pin, on ? HIGH : LOW);
}

static void setHeater(bool on) {
  heater_on = on;
  relayWrite(PIN_RELAY_HEATER, on);
}

static void setFanSpeed(uint8_t pct) {
  if (pct > 100) pct = 100;
  fan_speed_pct = pct;
  uint32_t duty = (uint32_t)(pct * 255 / 100);
  ledcWrite(FAN_PWM_CHANNEL, duty);
}

static void maReset() {
  ma_idx = 0;
  ma_count = 0;
  for (size_t i = 0; i < MA_WINDOW; i++) ma_buf[i] = 0.0f;
}

static float maAdd(float v) {
  ma_buf[ma_idx] = v;
  ma_idx = (ma_idx + 1) % MA_WINDOW;
  if (ma_count < MA_WINDOW) ma_count++;
  float sum = 0.0f;
  for (size_t i = 0; i < ma_count; i++) sum += ma_buf[i];
  return (ma_count > 0) ? (sum / (float)ma_count) : v;
}

static float dryingProgressPct(float initial_g, float current_g) {
  if (initial_g <= 1.0f) return 0.0f;
  float loss = initial_g - current_g;
  float pct = (loss / initial_g) * 100.0f;
  if (pct < 0.0f) pct = 0.0f;
  if (pct > 100.0f) pct = 100.0f;
  return pct;
}

// ========================= DEVICE ID GENERATION =========================
static String generateBleId() {
  uint8_t mac[6];
  esp_efuse_mac_get_default(mac);
  char id[5];
  snprintf(id, sizeof(id), "%02X%02X", mac[4], mac[5]);
  return String("HELADRY-") + id;
}

static String generateDeviceId() {
  uint8_t mac[6];
  esp_efuse_mac_get_default(mac);
  char id[20];
  snprintf(id, sizeof(id), "heladry_%02x%02x%02x", mac[3], mac[4], mac[5]);
  return String(id);
}

// ========================= BATTERY =========================
static const float BAT_DIVIDER_RATIO = 4.70f;
static const float ADC_REF_V         = 3.3f;
static const int   ADC_MAX           = 4095;

static float readBatteryVoltage() {
  uint32_t sum = 0;
  const int samples = 20;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(PIN_BAT_ADC);
    delay(2);
  }
  float adc = (float)sum / (float)samples;
  float v_adc = (adc / (float)ADC_MAX) * ADC_REF_V;
  return v_adc * BAT_DIVIDER_RATIO;
}

// ========================= HX711 (LOAD CELL) =========================
static void scaleInit() {
  scale.begin(PIN_HX_DT, PIN_HX_SCK);
  scale.set_scale(calibration_factor);
  scale.tare();
  maReset();
  Serial.println("[HX711] Initialized & tared");
}

static bool readWeightOnce(float &out_g) {
  if (!scale.is_ready()) return false;
  out_g = scale.get_units(5);
  return true;
}

static void tareScale() {
  scale.tare();
  maReset();
  float w = 0.0f;
  if (readWeightOnce(w)) filteredWeight_g = w;
  Serial.println("[HX711] Tare complete");
}

// ========================= I2C SENSORS =========================
static void sensorsInit() {
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);

  bme_ok = bme.begin(0x76);
  Serial.println(bme_ok ? "[BME280] OK" : "[BME280] NOT FOUND");

  bh_ok = lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
  Serial.println(bh_ok ? "[BH1750] OK" : "[BH1750] NOT FOUND");
}

static void readAllSensors() {
  // Weight
  float w = 0.0f;
  if (readWeightOnce(w)) {
    currentWeight_g  = w;
    filteredWeight_g = maAdd(w);
  }

  // BME280
  if (bme_ok) {
    temp_c   = bme.readTemperature() + temp_offset;
    hum_pct  = bme.readHumidity() + hum_offset;
    pres_hpa = bme.readPressure() / 100.0f;
  }

  // BH1750
  if (bh_ok) {
    lux_val = lightMeter.readLightLevel();
  }

  // Battery
  battery_v = readBatteryVoltage();
}

// ========================= SAFETY CHECK =========================
static void checkSafetyAlerts() {
  // Over-temperature
  bool prevOverTemp = alerts.overTemp;
  alerts.overTemp = (!isnan(temp_c) && temp_c > OVER_TEMP_THRESHOLD_C);
  if (alerts.overTemp && !prevOverTemp) {
    Serial.printf("[SAFETY] OVER-TEMP ALERT! %.1f°C > %.1f°C\n", temp_c, OVER_TEMP_THRESHOLD_C);
    // Safety cutoff: stop heater and reduce fan
    if (sessionState == SESSION_RUNNING) {
      setHeater(false);
      Serial.println("[SAFETY] Heater turned OFF due to over-temp");
    }
  }

  // Low battery
  bool prevLowBat = alerts.lowBattery;
  alerts.lowBattery = (!isnan(battery_v) && battery_v < LOW_BATTERY_THRESHOLD_V && battery_v > 0.5f);
  if (alerts.lowBattery && !prevLowBat) {
    Serial.printf("[SAFETY] LOW BATTERY ALERT! %.2fV < %.1fV\n", battery_v, LOW_BATTERY_THRESHOLD_V);
    // Safety cutoff: stop session if battery critically low
    if (battery_v < (LOW_BATTERY_THRESHOLD_V - 1.0f)) {
      if (sessionState == SESSION_RUNNING) {
        sessionState = SESSION_PAUSED;
        setHeater(false);
        setFanSpeed(0);
        Serial.println("[SAFETY] Session PAUSED — critically low battery");
      }
    }
  }

  // Sensor fault
  alerts.sensorFault = (!bme_ok && !bh_ok);
  if (alerts.sensorFault) {
    // Try re-init sensors periodically
    static uint32_t lastRetry = 0;
    if (nowMs() - lastRetry > 30000) {
      lastRetry = nowMs();
      sensorsInit();
      Serial.println("[SAFETY] Retrying sensor init...");
    }
  }
}

// ========================= HEATER CONTROL =========================
static void heaterControlLogic() {
  // Don't heat if over-temp alert active
  if (alerts.overTemp) {
    setHeater(false);
    return;
  }

  if (auto_heat_enabled && !manual_heater_mode) {
    if (isnan(temp_c)) {
      setHeater(false);
      return;
    }
    float target = (sessionState == SESSION_RUNNING) ? sessionTargetTemp : target_temp_c;
    if (!heater_on && temp_c < (target - HEAT_HYST_C)) {
      setHeater(true);
    } else if (heater_on && temp_c > (target + HEAT_HYST_C)) {
      setHeater(false);
    }
  }
}

// ========================= SESSION CONTROL =========================
static void startSession(const String &crop, float targetTemp, float weight) {
  if (sessionState == SESSION_RUNNING) return; // already running
  sessionState      = SESSION_RUNNING;
  sessionCropName   = crop;
  sessionTargetTemp = targetTemp;
  sessionStartMs    = nowMs();
  initialWeight_g   = weight > 0 ? weight : filteredWeight_g;
  auto_heat_enabled = true;
  setFanSpeed(80);  // default fan speed for session
  Serial.printf("[SESSION] Started: crop=%s target=%.1f°C weight=%.1fg\n",
                crop.c_str(), targetTemp, initialWeight_g);
}

static void stopSession() {
  sessionState = SESSION_FINISHED;
  setHeater(false);
  setFanSpeed(0);
  auto_heat_enabled = false;
  Serial.println("[SESSION] Stopped / Finished");
}

static void pauseSession() {
  if (sessionState == SESSION_RUNNING) {
    sessionState = SESSION_PAUSED;
    setHeater(false);
    setFanSpeed(0);
    Serial.println("[SESSION] Paused");
  }
}

static void resumeSession() {
  if (sessionState == SESSION_PAUSED) {
    sessionState = SESSION_RUNNING;
    auto_heat_enabled = true;
    setFanSpeed(80);
    Serial.println("[SESSION] Resumed");
  }
}

// ========================= LITTLEFS LOGGING =========================
static void littlefsInit() {
  if (LittleFS.begin(true)) {
    littlefs_ok = true;
    Serial.println("[LittleFS] Mounted OK");
    // Count existing log files
    File root = LittleFS.open("/logs");
    if (!root || !root.isDirectory()) {
      LittleFS.mkdir("/logs");
      logFileIndex = 0;
    } else {
      File f = root.openNextFile();
      int maxIdx = 0;
      while (f) {
        String fname = f.name();
        int idx = fname.substring(fname.lastIndexOf('_') + 1, fname.lastIndexOf('.')).toInt();
        if (idx > maxIdx) maxIdx = idx;
        f = root.openNextFile();
      }
      logFileIndex = maxIdx;
    }
  } else {
    Serial.println("[LittleFS] Mount FAILED");
  }
}

static void logBatchDataToFS() {
  if (!littlefs_ok) return;
  if (sessionState != SESSION_RUNNING) return;

  logFileIndex++;
  String path = "/logs/batch_" + String(logFileIndex) + ".json";

  JsonDocument doc;
  doc["ts"]         = nowMs();
  doc["crop"]       = sessionCropName;
  doc["temp_c"]     = isnan(temp_c)    ? 0.0f : temp_c;
  doc["hum_pct"]    = isnan(hum_pct)   ? 0.0f : hum_pct;
  doc["weight_g"]   = filteredWeight_g;
  doc["fan_pct"]    = fan_speed_pct;
  doc["heater"]     = heater_on;
  doc["battery_v"]  = isnan(battery_v) ? 0.0f : battery_v;
  doc["progress"]   = dryingProgressPct(initialWeight_g, filteredWeight_g);

  File f = LittleFS.open(path, "w");
  if (f) {
    serializeJson(doc, f);
    f.close();
    Serial.printf("[LittleFS] Logged -> %s\n", path.c_str());
  }
}

static void syncLogsToFirebase() {
  if (WiFi.status() != WL_CONNECTED) return;
  if (!Firebase.ready()) return;
  if (!littlefs_ok) return;

  File root = LittleFS.open("/logs");
  if (!root || !root.isDirectory()) return;

  File f = root.openNextFile();
  int synced = 0;
  while (f && synced < 5) { // sync up to 5 files per cycle
    String content = f.readString();
    String histPath = buildPathHistory();
    FirebaseJson json;
    json.setJsonData(content);
    if (Firebase.RTDB.pushJSON(&fbdo, histPath.c_str(), &json)) {
      String pathToRemove = String("/logs/") + f.name();
      f.close();
      LittleFS.remove(pathToRemove);
      synced++;
      Serial.printf("[LittleFS] Synced & removed: %s\n", pathToRemove.c_str());
    } else {
      f.close();
      break; // stop on error
    }
    f = root.openNextFile();
  }
}

// ========================= WIFI =========================
static void wifiSaveCredentials(const String &ssid, const String &pass) {
  prefs.begin("wifi", false);
  prefs.putString("ssid", ssid);
  prefs.putString("pass", pass);
  prefs.end();
  Serial.printf("[WiFi] Credentials saved: %s\n", ssid.c_str());
}

static bool wifiLoadCredentials(String &ssid, String &pass) {
  prefs.begin("wifi", true);
  ssid = prefs.getString("ssid", "");
  pass = prefs.getString("pass", "");
  prefs.end();
  return (ssid.length() > 0);
}

static void wifiInit() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(true);

  String ssid, pass;
  if (wifiLoadCredentials(ssid, pass)) {
    Serial.printf("[WiFi] Connecting to stored: %s\n", ssid.c_str());
    WiFi.begin(ssid.c_str(), pass.c_str());

    uint32_t t0 = nowMs();
    while (nowMs() - t0 < WIFI_CONNECT_TIMEOUT_MS) {
      if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        Serial.printf("[WiFi] Connected. IP: %s\n", WiFi.localIP().toString().c_str());
        return;
      }
      delay(200);
    }
    Serial.println("[WiFi] Stored creds failed. Falling back to BLE mode.");
  } else {
    Serial.println("[WiFi] No stored credentials. Starting in BLE-only mode.");
  }
  wifiConnected = false;
}

static void wifiMaintain() {
  bool nowOnline = (WiFi.status() == WL_CONNECTED);

  if (nowOnline) {
    if (!wifiConnected) {
      wifiConnected = true;
      Serial.printf("[WiFi] Connected. IP: %s\n", WiFi.localIP().toString().c_str());
      // [FIX-3] KEY FIX: init Firebase if not done yet
      if (!firebaseInitialized) {
        Serial.println("[WiFi] Late connection detected — initializing Firebase");
        firebaseInitIfWiFi();
      }
    }
    return;
  }

  // WiFi is down
  wifiConnected = false;
  if (nowMs() - lastWiFiTryMs < WIFI_RECONNECT_INTERVAL_MS) return;
  lastWiFiTryMs = nowMs();

  String ssid, pass;
  if (wifiLoadCredentials(ssid, pass)) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    Serial.println("[WiFi] Reconnecting...");
  }
}

// ========================= FIREBASE =========================
static void firebaseInitIfWiFi() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[Firebase] Skipped — no WiFi");
    return;
  }
  if (firebaseInitialized) {
    Serial.println("[Firebase] Already initialized");
    return;
  }

    fbConfig.api_key      = API_KEY;
    fbConfig.database_url = DATABASE_URL;

    // Anonymous auth — no email or password needed
    // Firebase issues a temporary token automatically
    // The Flutter app handles real user identity separately
    fbConfig.token_status_callback = tokenStatusCallback;

    Firebase.reconnectWiFi(true);
    Firebase.begin(&fbConfig, &fbAuth);

      // Sign in anonymously (signUp with empty email and password)
      if (Firebase.signUp(&fbConfig, &fbAuth, "", "")) {
        Serial.println("[Firebase] Anonymous sign-in initiated");
      } else {
        Serial.println("[Firebase] Anonymous sign-in failed — will retry");
      }

    fbdo.setResponseSize(4096);
    firebaseInitialized = true;
    Serial.println("[Firebase] Init done — using anonymous auth");
}

static void pushLiveToFirebase() {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;

  FirebaseJson json;
  json.set("device_id", deviceId);
  json.set("ble_name", bleDeviceName);
  json.set("wifi_connected", wifiConnected);
  json.set("fw_version", FW_VERSION);
  json.set("weight_g",         filteredWeight_g);
  json.set("fan_speed_pct",    fan_speed_pct);
  json.set("heater_on",        heater_on);
  json.set("temp_c",           isnan(temp_c)    ? 0.0f : temp_c);
  json.set("hum_pct",          isnan(hum_pct)   ? 0.0f : hum_pct);
  json.set("pres_hpa",         isnan(pres_hpa)  ? 0.0f : pres_hpa);
  json.set("lux",              isnan(lux_val)   ? 0.0f : lux_val);
  json.set("battery_v",        isnan(battery_v) ? 0.0f : battery_v);
  json.set("auto_heat_enabled",auto_heat_enabled);
  json.set("target_temp_c",    target_temp_c);
  json.set("initial_weight_g", initialWeight_g);
  json.set("progress_pct",     dryingProgressPct(initialWeight_g, filteredWeight_g));
  json.set("session_state",    sessionStateStr(sessionState));
  json.set("session_crop",     sessionCropName);
  json.set("alert_over_temp",  alerts.overTemp);
  json.set("alert_low_bat",    alerts.lowBattery);
  json.set("alert_sensor",     alerts.sensorFault);
  json.set("ts_ms",            (int)nowMs());

  json.set("ip_address", wifiConnected ? WiFi.localIP().toString() : String(""));

  if (!Firebase.RTDB.setJSON(&fbdo, buildPathLive().c_str(), &json)) {
    Serial.printf("[Firebase] Live push failed: %s\n", fbdo.errorReason().c_str());
  }
}

static void pushHistoryToFirebase() {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;
  if (sessionState != SESSION_RUNNING) return; // only log during active sessions

  FirebaseJson json;
  json.set("weight_g",    filteredWeight_g);
  json.set("fan_pct",     fan_speed_pct);
  json.set("heater_on",   heater_on);
  json.set("temp_c",      isnan(temp_c)    ? 0.0f : temp_c);
  json.set("hum_pct",     isnan(hum_pct)   ? 0.0f : hum_pct);
  json.set("lux",         isnan(lux_val)   ? 0.0f : lux_val);
  json.set("battery_v",   isnan(battery_v) ? 0.0f : battery_v);
  json.set("progress_pct",dryingProgressPct(initialWeight_g, filteredWeight_g));
  json.set("ts_ms",       (int)nowMs());

  if (!Firebase.RTDB.pushJSON(&fbdo, buildPathHistory().c_str(), &json)) {
    Serial.printf("[Firebase] History push failed: %s\n", fbdo.errorReason().c_str());
  }
}

// Firebase command polling (for Wi-Fi mode)
static bool fbGetBool(const String &path, bool &out) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return false;
  if (Firebase.RTDB.getBool(&fbdo, path.c_str())) { out = fbdo.boolData(); return true; }
  return false;
}
static bool fbGetFloat(const String &path, float &out) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return false;
  if (Firebase.RTDB.getFloat(&fbdo, path.c_str())) { out = fbdo.floatData(); return true; }
  return false;
}
static bool fbGetString(const String &path, String &out) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return false;
  if (Firebase.RTDB.getString(&fbdo, path.c_str())) { out = fbdo.stringData(); return true; }
  return false;
}
static void fbSetBool(const String &path, bool v) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;
  Firebase.RTDB.setBool(&fbdo, path.c_str(), v);
}
static void fbSetString(const String &path, const String &v) {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;
  Firebase.RTDB.setString(&fbdo, path.c_str(), v.c_str());
}

static void pollFirebaseCommands() {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;

  String cmdBase = buildPathCommands();
  String cfgBase = buildPathConfig();

  // Tare
  { bool v=false; if (fbGetBool(cmdBase+"/tare", v) && v) { tareScale(); fbSetBool(cmdBase+"/tare", false); } }

  // Session Commands
  { String cmd=""; if (fbGetString(cmdBase+"/session_cmd", cmd) && cmd.length() > 0) {
    cmd.toUpperCase();
    if (cmd == "START") {
        String crop = "Unknown"; float tTemp = 50.0f;
        fbGetString(cmdBase+"/session_crop", crop);
        fbGetFloat(cmdBase+"/session_target_temp", tTemp);
        startSession(crop, tTemp, 0.0f);
        fbSetString(cmdBase+"/session_cmd", "");
        Firebase.RTDB.setString(&fbdo, (cmdBase + "/last_executed_cmd").c_str(), cmd.c_str());
        Firebase.RTDB.setInt(&fbdo, (cmdBase + "/last_executed_at_ms").c_str(), (int)nowMs());
    } else if (cmd == "STOP")   { stopSession();   fbSetString(cmdBase+"/session_cmd", "");
        Firebase.RTDB.setString(&fbdo, (cmdBase + "/last_executed_cmd").c_str(), cmd.c_str());
        Firebase.RTDB.setInt(&fbdo, (cmdBase + "/last_executed_at_ms").c_str(), (int)nowMs());
    } else if (cmd == "PAUSE")  { pauseSession();  fbSetString(cmdBase+"/session_cmd", "");
        Firebase.RTDB.setString(&fbdo, (cmdBase + "/last_executed_cmd").c_str(), cmd.c_str());
        Firebase.RTDB.setInt(&fbdo, (cmdBase + "/last_executed_at_ms").c_str(), (int)nowMs());
    } else if (cmd == "RESUME") { resumeSession(); fbSetString(cmdBase+"/session_cmd", "");
        Firebase.RTDB.setString(&fbdo, (cmdBase + "/last_executed_cmd").c_str(), cmd.c_str());
        Firebase.RTDB.setInt(&fbdo, (cmdBase + "/last_executed_at_ms").c_str(), (int)nowMs());
    }
  }}

  // Set initial weight
  { bool v=false; if (fbGetBool(cmdBase+"/set_initial_weight", v) && v) {
    initialWeight_g = filteredWeight_g;
    fbSetBool(cmdBase+"/set_initial_weight", false);
  }}

  // Manual fan speed (from Firebase, 0–100)
  { float f=0; if (fbGetFloat(cmdBase+"/fan_speed_pct", f)) { setFanSpeed((uint8_t)f); } }

  // Manual heater
  { bool v=false; if (fbGetBool(cmdBase+"/heater_manual_on", v)) { manual_heater_mode = v; if (v) setHeater(true); } }
  { bool v=false; if (fbGetBool(cmdBase+"/heater_force_off", v) && v) { manual_heater_mode = true; setHeater(false); } }

  // Auto heat config
  { bool v=false; if (fbGetBool(cfgBase+"/auto_heat_enabled", v)) auto_heat_enabled = v; }
  { float t=target_temp_c; if (fbGetFloat(cfgBase+"/target_temp_c", t)) target_temp_c = t; }

  // Calibration
  { float cf=calibration_factor; if (fbGetFloat(cfgBase+"/calibration_factor", cf)) {
    if (fabs(cf - calibration_factor) > 0.0001f) {
      calibration_factor = cf;
      scale.set_scale(calibration_factor);
    }
  }}

  // Offsets
  { float tofs=temp_offset; if (fbGetFloat(cfgBase+"/temp_offset", tofs)) temp_offset = tofs; }
  { float hofs=hum_offset; if (fbGetFloat(cfgBase+"/humidity_offset", hofs)) hum_offset = hofs; }

  // Emergency stop via Firebase
  { bool v=false; if (fbGetBool(cmdBase+"/emergency_stop", v) && v) {
    setHeater(false); setFanSpeed(0);
    if (sessionState == SESSION_RUNNING) sessionState = SESSION_PAUSED;
    fbSetBool(cmdBase+"/emergency_stop", false);
    Serial.println("[CMD] EMERGENCY STOP via Firebase");
  }}
}

// ========================= BLE CALLBACKS =========================
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pSvr) override {
    bleConnected = true;
    Serial.println("[BLE] Client connected");
  }
  void onDisconnect(BLEServer* pSvr) override {
    bleConnected = false;
    bleAdvertising = false;  // [FIX-8] force re-advertise
    Serial.println("[BLE] Client disconnected — will re-advertise");
  }
};

static void sendBleAck(const String &cmd, const String &status) {
  if (!pAckChar || !bleConnected) return;
  JsonDocument doc;
  doc["cmd"]    = cmd;
  doc["status"] = status;
  String out;
  serializeJson(doc, out);
  pAckChar->setValue(out.c_str());
  pAckChar->notify();
}

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pChar) override {
    String val = pChar->getValue().c_str();
    Serial.printf("[BLE] Command received: %s\n", val.c_str());

    // Parse JSON command
    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, val);
    if (err) {
      // Try as plain text command
      val.trim();
      val.toUpperCase();

      if (val == "START_SESSION") {
        startSession("Unknown", 50.0f, filteredWeight_g);
        sendBleAck("START_SESSION", "done");
      } else if (val == "STOP_SESSION") {
        stopSession();
        sendBleAck("STOP_SESSION", "done");
      } else if (val == "PAUSE_SESSION") {
        pauseSession();
        sendBleAck("PAUSE_SESSION", "done");
      } else if (val == "RESUME_SESSION") {
        resumeSession();
        sendBleAck("RESUME_SESSION", "done");
      } else if (val == "EMERGENCY_STOP") {
        setHeater(false);
        setFanSpeed(0);
        if (sessionState == SESSION_RUNNING) sessionState = SESSION_PAUSED;
        sendBleAck("EMERGENCY_STOP", "done");
        Serial.println("[BLE] EMERGENCY STOP executed");
      } else if (val == "TARE") {
        tareScale();
        sendBleAck("TARE", "done");
      } else if (val == "SCAN_WIFI") {
        pendingWifiScan = true;
        sendBleAck("SCAN_WIFI", "started");
      } else {
        sendBleAck(val, "failed");
      }
      return;
    }

    // JSON command parsing
    String cmd = doc["cmd"] | "";
    cmd.toUpperCase();

    if (cmd == "START_SESSION") {
      String crop     = doc["crop"] | "Unknown";
      float tTemp     = doc["target_temp"] | 50.0f;
      float weight    = doc["weight"] | 0.0f;
      startSession(crop, tTemp, weight);
      sendBleAck("START_SESSION", "done");
    }
    else if (cmd == "STOP_SESSION") {
      stopSession();
      sendBleAck("STOP_SESSION", "done");
    }
    else if (cmd == "PAUSE_SESSION") {
      pauseSession();
      sendBleAck("PAUSE_SESSION", "done");
    }
    else if (cmd == "RESUME_SESSION") {
      resumeSession();
      sendBleAck("RESUME_SESSION", "done");
    }
    else if (cmd == "SET_MANUAL_OUTPUTS") {
      if (doc.containsKey("fan_speed")) {
        setFanSpeed(doc["fan_speed"] | 0);
      }
      if (doc.containsKey("heater")) {
        bool h = doc["heater"] | false;
        manual_heater_mode = true;
        setHeater(h);
      }
      if (doc.containsKey("target_temp")) {
        target_temp_c = doc["target_temp"] | 35.0f;
      }
      if (doc.containsKey("temp_offset")) {
        temp_offset = doc["temp_offset"] | 0.0f;
      }
      if (doc.containsKey("humidity_offset")) {
        hum_offset = doc["humidity_offset"] | 0.0f;
      }
      sendBleAck("SET_MANUAL_OUTPUTS", "done");
    }
    else if (cmd == "SET_WIFI_CREDS") {
      String ssid = doc["ssid"] | "";
      String pass = doc["pass"] | "";
      if (ssid.length() > 0) {
        provisioningSsid = ssid;
        provisioningPass = pass;
        WiFi.disconnect();
        WiFi.begin(ssid.c_str(), pass.c_str());
        pendingWifiConnect = true;
        wifiConnectStartMs = nowMs();
        Serial.printf("[BLE] WiFi provisioning started for: %s\n", ssid.c_str());
      } else {
        JsonDocument res;
        res["cmd"] = "WIFI_CONNECT_RESULT";
        res["status"] = "failed";
        res["reason"] = "invalid_ssid";
        String out; serializeJson(res, out);
        if (pAckChar) { pAckChar->setValue(out.c_str()); pAckChar->notify(); }
      }
    }
    else if (cmd == "EMERGENCY_STOP") {
      setHeater(false);
      setFanSpeed(0);
      if (sessionState == SESSION_RUNNING) sessionState = SESSION_PAUSED;
      sendBleAck("EMERGENCY_STOP", "done");
    }
    else if (cmd == "TARE") {
      tareScale();
      sendBleAck("TARE", "done");
    }
    else if (cmd == "SCAN_WIFI") {
      pendingWifiScan = true;
      sendBleAck("SCAN_WIFI", "started");
    }
    else {
      sendBleAck(cmd, "failed");
    }
  }
  };

// ========================= BLE INIT =========================
static void bleInit() {
  bleDeviceName = generateBleId();
  Serial.printf("[BLE] Device name: %s\n", bleDeviceName.c_str());

  BLEDevice::init(bleDeviceName.c_str());
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // State characteristic (notify)
  pStateChar = pService->createCharacteristic(
    STATE_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pStateChar->addDescriptor(new BLE2902());

  // Command characteristic (write)
  pCommandChar = pService->createCharacteristic(
    COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  pCommandChar->setCallbacks(new CommandCallbacks());

  // ACK characteristic (notify)
  pAckChar = pService->createCharacteristic(
    ACK_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pAckChar->addDescriptor(new BLE2902());

  pService->start();

  BLEAdvertising *pAdv = BLEDevice::getAdvertising();
  pAdv->addServiceUUID(SERVICE_UUID);
  pAdv->setScanResponse(true);
  pAdv->setMinPreferred(0x06);
  pAdv->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  bleAdvertising = true;
  Serial.println("[BLE] Advertising started");
}

static void bleMaintainAdvertising() {
  if (!bleConnected && !bleAdvertising) {
    delay(500);  // small delay before re-advertising
    BLEDevice::startAdvertising();
    bleAdvertising = true;
    Serial.println("[BLE] Re-advertising started");
  }
}

static void bleNotifyState() {
  if (!pStateChar || !bleConnected) return;

  JsonDocument doc;
  doc["device_id"]  = deviceId;
  doc["ble_name"]   = bleDeviceName;
  doc["wifi"]       = wifiConnected;
  doc["fw"]         = FW_VERSION;
  doc["temp"]     = isnan(temp_c)    ? 0.0f : (float)round(temp_c * 10) / 10.0f;
  doc["hum"]      = isnan(hum_pct)   ? 0.0f : (float)round(hum_pct * 10) / 10.0f;
  doc["weight"]   = (float)round(filteredWeight_g * 10) / 10.0f;
  doc["fan"]      = fan_speed_pct;
  doc["heater"]   = heater_on;
  doc["bat"]      = isnan(battery_v) ? 0.0f : (float)round(battery_v * 100) / 100.0f;
  doc["lux"]      = isnan(lux_val)   ? 0.0f : (float)round(lux_val);
  doc["session"]  = sessionStateStr(sessionState);
  doc["crop"]     = sessionCropName;
  doc["tgt_temp"] = (float)round(target_temp_c * 10) / 10.0f;
  doc["progress"] = (float)round(dryingProgressPct(initialWeight_g, filteredWeight_g) * 10) / 10.0f;

  // Alerts
  JsonObject al = doc["alerts"].to<JsonObject>();
  al["ot"] = alerts.overTemp;
  al["lb"] = alerts.lowBattery;
  al["sf"] = alerts.sensorFault;

  if (wifiConnected) {
    doc["ip"] = WiFi.localIP().toString().c_str();
  }

  String out;
  serializeJson(doc, out);

  // BLE characteristic max is usually 512 bytes; truncate if needed
  if (out.length() < 500) {
    pStateChar->setValue(out.c_str());
    pStateChar->notify();
  }
}

// ========================= SERIAL PRINT =========================
static void printSensorLine() {
  Serial.printf("[SENS] W=%.1fg T=%.1fC H=%.0f%% B=%.2fV FAN=%d%% HEAT=%s SES=%s\n",
    filteredWeight_g,
    isnan(temp_c) ? 0.0f : temp_c,
    isnan(hum_pct) ? 0.0f : hum_pct,
    isnan(battery_v) ? 0.0f : battery_v,
    fan_speed_pct,
    heater_on ? "ON" : "OFF",
    sessionStateStr(sessionState));
}

// ========================= SETUP =========================
void setup() {
  Serial.begin(115200);
  delay(200);

  // Heater relay
  pinMode(PIN_RELAY_HEATER, OUTPUT);
  setHeater(false);

  // Fan PWM
  ledcSetup(FAN_PWM_CHANNEL, FAN_PWM_FREQ, FAN_PWM_RES);
  ledcAttachPin(PIN_FAN_PWM, FAN_PWM_CHANNEL);
  setFanSpeed(0);

  // Battery ADC
  analogReadResolution(12);
  pinMode(PIN_BAT_ADC, INPUT);

  Serial.println("=== HelaDry Firmware v" FW_VERSION " Boot ===");

  deviceId = generateDeviceId();
  Serial.printf("[DEVICE] ID: %s\n", deviceId.c_str());

  // Init subsystems
  sensorsInit();
  scaleInit();
  littlefsInit();

  // BLE always starts (for both online & offline modes)
  bleInit();

  // Try WiFi with stored credentials
  wifiInit();

  // Firebase if WiFi connected
  firebaseInitIfWiFi();

  Serial.println("=== System Ready ===");
  Serial.printf("[MODE] WiFi: %s | BLE: %s\n",
    wifiConnected ? "CONNECTED" : "OFFLINE (BLE fallback)",
    bleAdvertising ? "ADVERTISING" : "OFF");
}

// ========================= LOOP =========================
void loop() {
  uint32_t now = nowMs();

  // Handle WiFi Scan Request
  if (pendingWifiScan) {
    pendingWifiScan = false;
    WiFi.scanNetworks(true);  // async = true, non-blocking
    scanResultPending = true;
    scanStartMs = now;
  }

  // Check WiFi Scan Results
  if (scanResultPending) {
    int n = WiFi.scanComplete();
    if (n >= 0) {
      scanResultPending = false;
      JsonDocument doc;
      doc["cmd"] = "WIFI_SCAN_RESULT";
      JsonArray networks = doc["networks"].to<JsonArray>();
      int limit = n > 8 ? 8 : n;
      for (int i = 0; i < limit; i++) {
        JsonObject net = networks.add<JsonObject>();
        net["ssid"] = WiFi.SSID(i);
        net["rssi"] = WiFi.RSSI(i);
        net["secure"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
      }
      String out;
      serializeJson(doc, out);
      if (pAckChar && bleConnected && out.length() < 500) {
        pAckChar->setValue(out.c_str());
        pAckChar->notify();
      }
      WiFi.scanDelete();
    } else if (n == WIFI_SCAN_FAILED || (now - scanStartMs > 12000)) {
      scanResultPending = false;
      WiFi.scanDelete();
      if (pAckChar && bleConnected) {
        pAckChar->setValue("{\"cmd\":\"WIFI_SCAN_RESULT\",\"networks\":[]}");
        pAckChar->notify();
      }
    }
  }

  // Handle WiFi Provisioning Connection
  if (pendingWifiConnect) {
    if (WiFi.status() == WL_CONNECTED) {
      pendingWifiConnect = false;
      wifiConnected = true;
      wifiSaveCredentials(provisioningSsid, provisioningPass);
      
      JsonDocument doc;
      doc["cmd"] = "WIFI_CONNECT_RESULT";
      doc["status"] = "connected";
      doc["ip"] = WiFi.localIP().toString();
      String out;
      serializeJson(doc, out);
      if (pAckChar && bleConnected) {
        pAckChar->setValue(out.c_str());
        pAckChar->notify();
      }
      Serial.printf("[WiFi] Provisioning connected! IP: %s\n", WiFi.localIP().toString().c_str());
      firebaseInitIfWiFi();
      if (Firebase.ready()) {
        String cfgBase = buildPathConfig();
        Firebase.RTDB.setString(&fbdo, (cfgBase + "/last_wifi_ssid").c_str(), provisioningSsid.c_str());
        Firebase.RTDB.setString(&fbdo, (cfgBase + "/wifi_ip").c_str(), WiFi.localIP().toString().c_str());
        Firebase.RTDB.setInt(&fbdo, (cfgBase + "/wifi_connected_at_ms").c_str(), (int)now);
      }
    } else if (now - wifiConnectStartMs > WIFI_CONNECT_TIMEOUT_MS) {
      pendingWifiConnect = false;
      JsonDocument doc;
      doc["cmd"] = "WIFI_CONNECT_RESULT";
      doc["status"] = "failed";
      doc["reason"] = "timeout";
      String out;
      serializeJson(doc, out);
      if (pAckChar && bleConnected) {
        pAckChar->setValue(out.c_str());
        pAckChar->notify();
      }
      Serial.println("[WiFi] Provisioning failed (timeout)");
      WiFi.disconnect();
    }
  }

  // WiFi maintenance
  if (!pendingWifiConnect) {
    wifiMaintain();
  }

  // BLE re-advertise if disconnected
  bleMaintainAdvertising();

  // Sensor reading
  if (now - lastSensorReadMs >= SENSOR_READ_INTERVAL_MS) {
    lastSensorReadMs = now;
    readAllSensors();
    checkSafetyAlerts();
    heaterControlLogic();
    printSensorLine();
  }

  // BLE state notification
  if (now - lastBleNotifyMs >= BLE_NOTIFY_INTERVAL_MS) {
    lastBleNotifyMs = now;
    bleNotifyState();
  }

  // Firebase command polling (WiFi mode)
  if (now - lastCommandPollMs >= COMMAND_POLL_INTERVAL_MS) {
    lastCommandPollMs = now;
    pollFirebaseCommands();
  }

  // Firebase live + history push
  if (now - lastFirebasePushMs >= FIREBASE_PUSH_INTERVAL_MS) {
    lastFirebasePushMs = now;
    pushLiveToFirebase();
    pushHistoryToFirebase();

    // Also log to LittleFS if session running
    logBatchDataToFS();
  }

  // LittleFS log sync to Firebase
  if (now - lastLogSyncMs >= LOG_SYNC_INTERVAL_MS) {
    lastLogSyncMs = now;
    syncLogsToFirebase();
  }
}
