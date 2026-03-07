#include <Arduino.h>
#include <Preferences.h>
#include <WiFi.h>
#include <WiFiManager.h>

// BLE
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#include <Wire.h>

#include <HX711.h>

// BME280 + BH1750
#include <Adafruit_BME280.h>
#include <BH1750.h>

// Firebase (Mobizt)
#include <Firebase_ESP_Client.h>
#include <addons/RTDBHelper.h>
#include <addons/TokenHelper.h>

// Secrets
#include <secrets.h>

// ========================= FIRMWARE VERSION =========================
#define FW_VERSION "2.1.4"

// ========================= DEVICE =========================
#define DEVICE_ID "heladry_001"
#define BOOT_BTN 0

// ========================= BLE UUIDs =========================
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define STATE_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define ACK_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26aa"

// ========================= PINOUT (DEFAULTS) =========================
static const int PIN_I2C_SDA = 21;
static const int PIN_I2C_SCL = 22;

static const int PIN_HX_DT = 18;
static const int PIN_HX_SCK = 19;

static const int PIN_RELAY_FAN = 25;
static const int PIN_RELAY_HEATER = 26;

// Battery monitor (optional)
static const int PIN_BAT_ADC = 34;

// Relay logic
static const bool RELAY_ACTIVE_LOW = true;

// ========================= TIMING =========================
static const uint32_t SENSOR_READ_INTERVAL_MS = 2000;
static const uint32_t FIREBASE_PUSH_INTERVAL_MS = 5000;
static const uint32_t COMMAND_POLL_INTERVAL_MS = 2000;
static const uint32_t BLE_NOTIFY_INTERVAL_MS = 1000;

static const uint32_t WIFI_WAIT_MS = 15000;
static const uint32_t PORTAL_TIMEOUT_SEC = 180;
static const uint32_t WIFI_RECONNECT_INTERVAL_MS = 5000;

// HX711 smoothing
static const size_t MA_WINDOW = 10;

// Heater auto control
static const float HEAT_HYST_C = 2.0f;

// ========================= GLOBALS =========================
HX711 scale;
Adafruit_BME280 bme;
BH1750 lightMeter;

bool bme_ok = false;
bool bh_ok = false;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Preferences (NVS)
Preferences prefs;

// Weight state
static float calibration_factor = -7050.0f;
static float initialWeight_g = 0.0f;
static float currentWeight_g = 0.0f;
static float filteredWeight_g = 0.0f;

// Sensor state
static float temp_c = NAN;
static float hum_pct = NAN;
static float pres_hpa = NAN;
static float lux = NAN;
static float battery_v = NAN;

// Control state
static bool fan_on = false;
static bool heater_on = false;

// Modes/commands
static bool manual_fan_mode = false;
static bool manual_heater_mode = false;

static bool auto_heat_enabled = false;
static float target_temp_c = 35.0f;

// Moving average buffer (HX711)
static float ma_buf[MA_WINDOW];
static size_t ma_idx = 0;
static size_t ma_count = 0;

// Timers
static uint32_t lastSensorReadMs = 0;
static uint32_t lastFirebasePushMs = 0;
static uint32_t lastCommandPollMs = 0;
static uint32_t lastBleNotifyMs = 0;
static uint32_t lastWiFiTryMs = 0;

// WiFi state
static bool wifi_connected_once = false;

// BLE
static BLEServer *pServer = nullptr;
static BLECharacteristic *pStateChar = nullptr;
static BLECharacteristic *pCommandChar = nullptr;
static BLECharacteristic *pAckChar = nullptr;
static bool bleConnected = false;
static bool bleAdvertising = false;
static String bleDeviceName = "HELADRY-0000";

// ========================= HELPERS =========================
static uint32_t nowMs() { return millis(); }

static String buildRootPath() {
  String p;
  p.reserve(32);
  p = "/devices/";
  p.concat(DEVICE_ID);
  return p;
}

static String buildPathLive() {
  String p = buildRootPath();
  p.concat("/live");
  return p;
}

static String buildPathHistory() {
  String p = buildRootPath();
  p.concat("/history");
  return p;
}

static String buildPathCommands() {
  String p = buildRootPath();
  p.concat("/commands");
  return p;
}

static String buildPathConfig() {
  String p = buildRootPath();
  p.concat("/config");
  return p;
}

static String joinPath(const String &base, const char *leaf) {
  String p = base;
  p.concat(leaf);
  return p;
}

static void relayWrite(int pin, bool on) {
  if (RELAY_ACTIVE_LOW)
    digitalWrite(pin, on ? LOW : HIGH);
  else
    digitalWrite(pin, on ? HIGH : LOW);
}

static void setFan(bool on) {
  fan_on = on;
  relayWrite(PIN_RELAY_FAN, on);
}

static void setHeater(bool on) {
  heater_on = on;
  relayWrite(PIN_RELAY_HEATER, on);
}

static void maReset() {
  ma_idx = 0;
  ma_count = 0;
  for (size_t i = 0; i < MA_WINDOW; i++)
    ma_buf[i] = 0.0f;
}

static float maAdd(float v) {
  ma_buf[ma_idx] = v;
  ma_idx = (ma_idx + 1) % MA_WINDOW;
  if (ma_count < MA_WINDOW)
    ma_count++;

  float sum = 0.0f;
  for (size_t i = 0; i < ma_count; i++)
    sum += ma_buf[i];
  return (ma_count > 0) ? (sum / (float)ma_count) : v;
}

static float dryingProgressPct(float initial_g, float current_g) {
  if (initial_g <= 1.0f)
    return 0.0f;
  float loss = initial_g - current_g;
  float pct = (loss / initial_g) * 100.0f;
  if (pct < 0.0f)
    pct = 0.0f;
  if (pct > 100.0f)
    pct = 100.0f;
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

// ========================= BATTERY (OPTIONAL) =========================
static const bool BATTERY_ENABLED = true;
static const float BAT_DIVIDER_RATIO =
    4.70f; // CHANGE this to your resistor ratio
static const float ADC_REF_V = 3.3f;
static const int ADC_MAX = 4095;

static float readBatteryVoltage() {
  if (!BATTERY_ENABLED)
    return NAN;

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

// ========================= HX711 =========================
static void scaleInit() {
  scale.begin(PIN_HX_DT, PIN_HX_SCK);
  scale.set_scale(calibration_factor);
  scale.tare();
  maReset();
}

static bool readWeightOnce(float &out_g) {
  if (!scale.is_ready())
    return false;
  float w = scale.get_units(5);
  out_g = w;
  return true;
}

static void tareScale() {
  scale.tare();
  maReset();
  float w = 0.0f;
  if (readWeightOnce(w))
    filteredWeight_g = w;
  Serial.println("[HX711] Tare complete");
}

// ========================= I2C SENSORS =========================
static void sensorsInit() {
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);

  bme_ok = bme.begin(0x76);
  if (bme_ok)
    Serial.println("[BME280] OK");
  else
    Serial.println("[BME280] NOT FOUND (check wiring/address)");

  bh_ok = lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
  if (bh_ok)
    Serial.println("[BH1750] OK");
  else
    Serial.println("[BH1750] NOT FOUND (check wiring)");
}

static void readAllSensors() {
  float w = 0.0f;
  if (readWeightOnce(w)) {
    currentWeight_g = w;
    filteredWeight_g = maAdd(w);
  }

  if (bme_ok) {
    temp_c = bme.readTemperature();
    hum_pct = bme.readHumidity();
    pres_hpa = bme.readPressure() / 100.0f;
  }

  if (bh_ok) {
    lux = lightMeter.readLightLevel();
  }

  battery_v = readBatteryVoltage();
}

// ========================= HEATER CONTROL =========================
static void heaterControlLogic() {
  if (auto_heat_enabled && !manual_heater_mode) {
    if (isnan(temp_c)) {
      setHeater(false);
      return;
    }

    if (!heater_on && temp_c < (target_temp_c - HEAT_HYST_C)) {
      setHeater(true);
    } else if (heater_on && temp_c > (target_temp_c + HEAT_HYST_C)) {
      setHeater(false);
    }
  }
}

// ========================= WIFI =========================
static bool startConfigPortal() {
  WiFiManager wm;
  wm.setConfigPortalTimeout(PORTAL_TIMEOUT_SEC);

  Serial.println("[WiFi] Starting config portal (AP: HelaDry-Setup)...");
  bool ok = wm.startConfigPortal("HelaDry-Setup");

  if (ok) {
    Serial.print("[WiFi] Connected after portal. IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("[WiFi] Portal timeout/no config saved.");
  }
  return ok;
}

static void wifiInit() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);

  pinMode(BOOT_BTN, INPUT_PULLUP);
  bool forcePortal = (digitalRead(BOOT_BTN) == LOW);

  if (forcePortal) {
    startConfigPortal();
    wifi_connected_once = (WiFi.status() == WL_CONNECTED);
    return;
  }

  Serial.println("[WiFi] Trying saved WiFi...");
  WiFi.begin(); // saved creds

  uint32_t t0 = nowMs();
  while (nowMs() - t0 < WIFI_WAIT_MS) {
    if (WiFi.status() == WL_CONNECTED) {
      wifi_connected_once = true;
      Serial.print("[WiFi] Connected. IP: ");
      Serial.println(WiFi.localIP());
      return;
    }
    delay(200);
  }

  Serial.println("[WiFi] Saved WiFi not connected. Opening portal...");
  startConfigPortal();
  wifi_connected_once = (WiFi.status() == WL_CONNECTED);
}

static void wifiMaintain() {
  if (WiFi.status() == WL_CONNECTED)
    return;

  if (nowMs() - lastWiFiTryMs < WIFI_RECONNECT_INTERVAL_MS)
    return;
  lastWiFiTryMs = nowMs();

  Serial.println("[WiFi] Disconnected. Reconnecting...");
  WiFi.reconnect();
}

// ========================= FIREBASE =========================
static void firebaseInitIfWiFi() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[Firebase] Skipped init (no WiFi).");
    return;
  }

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  config.token_status_callback = tokenStatusCallback;
  Firebase.reconnectWiFi(true);
  Firebase.begin(&config, &auth);

  fbdo.setResponseSize(4096);
  Serial.println("[Firebase] Init done.");
}

static void pushLiveToFirebase() {
  if (WiFi.status() != WL_CONNECTED)
    return;
  if (!Firebase.ready())
    return;

  FirebaseJson json;
  json.set("weight_g", filteredWeight_g);
  json.set("fan_on", fan_on);
  json.set("heater_on", heater_on);

  json.set("temp_c", temp_c);
  json.set("hum_pct", hum_pct);
  json.set("pres_hpa", pres_hpa);
  json.set("lux", lux);
  json.set("battery_v", battery_v);

  json.set("manual_fan_mode", manual_fan_mode);
  json.set("manual_heater_mode", manual_heater_mode);
  json.set("auto_heat_enabled", auto_heat_enabled);
  json.set("target_temp_c", target_temp_c);

  json.set("initial_weight_g", initialWeight_g);
  json.set("progress_pct",
           dryingProgressPct(initialWeight_g, filteredWeight_g));
  json.set("ts_ms", (int)nowMs());

  String livePath = buildPathLive();

  if (!Firebase.RTDB.setJSON(&fbdo, livePath.c_str(), &json)) {
    Serial.print("[Firebase] Live push failed: ");
    Serial.println(fbdo.errorReason().c_str());
  }
}

static void pushHistoryToFirebase() {
  if (WiFi.status() != WL_CONNECTED)
    return;
  if (!Firebase.ready())
    return;

  FirebaseJson json;
  json.set("weight_g", filteredWeight_g);
  json.set("fan_on", fan_on);
  json.set("heater_on", heater_on);
  json.set("temp_c", temp_c);
  json.set("hum_pct", hum_pct);
  json.set("lux", lux);
  json.set("battery_v", battery_v);
  json.set("progress_pct",
           dryingProgressPct(initialWeight_g, filteredWeight_g));
  json.set("ts_ms", (int)nowMs());

  String histPath = buildPathHistory();

  if (!Firebase.RTDB.pushJSON(&fbdo, histPath.c_str(), &json)) {
    Serial.print("[Firebase] History push failed: ");
    Serial.println(fbdo.errorReason().c_str());
  }
}

static bool getBoolAt(const String &path, bool &out) {
  if (WiFi.status() != WL_CONNECTED)
    return false;
  if (!Firebase.ready())
    return false;
  if (Firebase.RTDB.getBool(&fbdo, path.c_str())) {
    out = fbdo.boolData();
    return true;
  }
  return false;
}

static bool getFloatAt(const String &path, float &out) {
  if (WiFi.status() != WL_CONNECTED)
    return false;
  if (!Firebase.ready())
    return false;
  if (Firebase.RTDB.getFloat(&fbdo, path.c_str())) {
    out = fbdo.floatData();
    return true;
  }
  return false;
}

static void setBoolAt(const String &path, bool v) {
  if (WiFi.status() != WL_CONNECTED)
    return;
  if (!Firebase.ready())
    return;
  if (!Firebase.RTDB.setBool(&fbdo, path.c_str(), v)) {
    Serial.print("[Firebase] setBool failed: ");
    Serial.println(fbdo.errorReason().c_str());
  }
}

static void pollCommands() {
  if (WiFi.status() != WL_CONNECTED)
    return;
  if (!Firebase.ready())
    return;

  String cmdBase = buildPathCommands();
  String cfgBase = buildPathConfig();
  (void)cfgBase;

  // tare
  {
    String p = joinPath(cmdBase, "/tare");
    bool v = false;
    if (getBoolAt(p, v) && v) {
      tareScale();
      setBoolAt(p, false);
    }
  }

  // set initial weight
  {
    String p = joinPath(cmdBase, "/set_initial_weight");
    bool v = false;
    if (getBoolAt(p, v) && v) {
      initialWeight_g = filteredWeight_g;
      Serial.print("[CMD] initialWeight_g set = ");
      Serial.println(initialWeight_g);
      setBoolAt(p, false);
    }
  }

  // manual fan
  {
    String p = joinPath(cmdBase, "/manual_fan_trigger");
    bool v = false;
    if (getBoolAt(p, v)) {
      manual_fan_mode = v;
      if (manual_fan_mode)
        setFan(true);
    }
  }

  // fan force off
  {
    String p = joinPath(cmdBase, "/fan_force_off");
    bool v = false;
    if (getBoolAt(p, v) && v) {
      manual_fan_mode = true;
      setFan(false);
    }
  }

  // heater manual on
  {
    String p = joinPath(cmdBase, "/heater_manual_on");
    bool v = false;
    if (getBoolAt(p, v)) {
      manual_heater_mode = v;
      if (manual_heater_mode)
        setHeater(true);
    }
  }

  // heater force off
  {
    String p = joinPath(cmdBase, "/heater_force_off");
    bool v = false;
    if (getBoolAt(p, v) && v) {
      manual_heater_mode = true;
      setHeater(false);
    }
  }

  // auto heat enabled
  {
    String p = joinPath(cfgBase, "/auto_heat_enabled");
    bool v = false;
    if (getBoolAt(p, v))
      auto_heat_enabled = v;
  }

  // target temp
  {
    String p = joinPath(cfgBase, "/target_temp_c");
    float t = target_temp_c;
    if (getFloatAt(p, t))
      target_temp_c = t;
  }

  // calibration factor
  {
    String p = joinPath(cfgBase, "/calibration_factor");
    float cf = calibration_factor;
    if (getFloatAt(p, cf)) {
      if (fabs(cf - calibration_factor) > 0.0001f) {
        calibration_factor = cf;
        scale.set_scale(calibration_factor);
        Serial.print("[CFG] calibration_factor = ");
        Serial.println(calibration_factor);
      }
    }
  }
}

// ========================= BLE CALLBACKS =========================
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pSvr) override {
    bleConnected = true;
    Serial.println("[BLE] Client connected");
  }
  void onDisconnect(BLEServer *pSvr) override {
    bleConnected = false;
    bleAdvertising = false;
    Serial.println("[BLE] Client disconnected");
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
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pStateChar->addDescriptor(new BLE2902());

  // Command characteristic (write)
  pCommandChar = pService->createCharacteristic(
      COMMAND_CHAR_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);

  // ACK characteristic (notify)
  pAckChar = pService->createCharacteristic(
      ACK_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
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
    BLEDevice::startAdvertising();
    bleAdvertising = true;
    Serial.println("[BLE] Re-advertising");
  }
}

// ========================= BLE STATE NOTIFY =========================
static void bleNotifyState() {
  if (!pStateChar || !bleConnected)
    return;

  String out = "{\"temp\":";
  out += String(isnan(temp_c) ? 0 : temp_c, 1);
  out += ",\"hum\":";
  out += String(isnan(hum_pct) ? 0 : hum_pct, 1);
  out += ",\"fan\":";
  out += fan_on ? "true" : "false";
  out += ",\"heater\":";
  out += heater_on ? "true" : "false";
  out += ",\"bat\":";
  out += String(isnan(battery_v) ? 0 : battery_v, 2);
  out += ",\"weight\":";
  out += String(filteredWeight_g, 1);
  out += "}";

  pStateChar->setValue(out.c_str());
  pStateChar->notify();
}

// ========================= SERIAL PRINT =========================
static void printSensorLine() {
  Serial.print("[SENS] W=");
  Serial.print(filteredWeight_g, 2);
  Serial.print("g  T=");
  if (isnan(temp_c))
    Serial.print("NaN");
  else
    Serial.print(temp_c, 2);
  Serial.print("C  H=");
  if (isnan(hum_pct))
    Serial.print("NaN");
  else
    Serial.print(hum_pct, 1);
  Serial.print("%  P=");
  if (isnan(pres_hpa))
    Serial.print("NaN");
  else
    Serial.print(pres_hpa, 1);
  Serial.print("hPa  LUX=");
  if (isnan(lux))
    Serial.print("NaN");
  else
    Serial.print(lux, 1);
  Serial.print("  BAT=");
  if (isnan(battery_v))
    Serial.print("NaN");
  else
    Serial.print(battery_v, 2);
  Serial.print("V  FAN=");
  Serial.print(fan_on ? "ON" : "OFF");
  Serial.print("  HEAT=");
  Serial.println(heater_on ? "ON" : "OFF");
}

// ========================= SETUP / LOOP =========================
void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(PIN_RELAY_FAN, OUTPUT);
  pinMode(PIN_RELAY_HEATER, OUTPUT);
  setFan(false);
  setHeater(false);

  if (BATTERY_ENABLED) {
    analogReadResolution(12);
    pinMode(PIN_BAT_ADC, INPUT);
  }

  Serial.println("=== HelaDry Firmware v" FW_VERSION " Boot ===");

  sensorsInit();
  scaleInit();

  // Init BLE
  bleInit();

  wifiInit();
  firebaseInitIfWiFi();

  Serial.println("=== Started. BLE active, sensor readings every 2s ===");
}

void loop() {
  wifiMaintain();
  bleMaintainAdvertising();

  uint32_t now = nowMs();

  if (now - lastSensorReadMs >= SENSOR_READ_INTERVAL_MS) {
    lastSensorReadMs = now;
    readAllSensors();
    heaterControlLogic();
    printSensorLine();
  }

  // BLE state notifications
  if (now - lastBleNotifyMs >= BLE_NOTIFY_INTERVAL_MS) {
    lastBleNotifyMs = now;
    bleNotifyState();
  }

  if (now - lastCommandPollMs >= COMMAND_POLL_INTERVAL_MS) {
    lastCommandPollMs = now;
    pollCommands();
  }

  if (now - lastFirebasePushMs >= FIREBASE_PUSH_INTERVAL_MS) {
    lastFirebasePushMs = now;
    pushLiveToFirebase();
    pushHistoryToFirebase();
  }
}
