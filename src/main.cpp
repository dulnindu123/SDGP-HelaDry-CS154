#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include "HX711.h"

// --- WIFI CREDENTIALS ---
#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// --- FIREBASE CREDENTIALS ---
#define FIREBASE_HOST "heladry-iot-24a53-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "fSMoUvf7NRCpS47ULiKjGZqxl3vVOh3rdgoszcYd"

// --- PINS ---
const int LOADCELL_DOUT_PIN = 18;
const int LOADCELL_SCK_PIN = 19;

HX711 scale;
FirebaseData firebaseData;
FirebaseConfig config;
FirebaseAuth auth;

void setup() {
  Serial.begin(115200);

  // 1. Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected!");

  // 2. Initialize Scale
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(-7050.0); // Calibration factor
  scale.tare();

  // 3. Configure Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  if (scale.is_ready()) {
    float weight = scale.get_units(5);
    
    // 4. Push Data to Firebase path "/HelaDry/current_weight"
    if (Firebase.setFloat(firebaseData, "/HelaDry/current_weight", weight)) {
      Serial.print("Push Successful. Weight: ");
      Serial.println(weight);
    } else {
      Serial.print("Firebase Error: ");
      Serial.println(firebaseData.errorReason());
    }
  }
  delay(3000); // Send data every 3 seconds
}