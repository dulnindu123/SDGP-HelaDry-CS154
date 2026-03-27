// ============================================================
//  secrets.h — HelaDry Firmware
//  Only API_KEY and DATABASE_URL needed.
//  Firmware uses Anonymous Auth — no user credentials required.
//  Add this file to .gitignore
// ============================================================
#pragma once

// Firebase Web API Key (from Firebase Console > Project Settings)
// This is NOT secret — it is already inside google-services.json
#define API_KEY      "AIzaSyCiFayCZhCAH6KlFYKACCnEU3EUu3m9kBE"

// Firebase Realtime Database URL
#define DATABASE_URL "https://solar-dryer-iot-default-rtdb.asia-southeast1.firebasedatabase.app"

// Device User Credentials (Email/Password must be enabled in Firebase Auth)
#define USER_EMAIL    "device@example.com"
#define USER_PASSWORD "device_password"