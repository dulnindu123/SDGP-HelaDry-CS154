# SDGP HelaDry — Mobile App UI (UI Branch)

This branch contains the **HelaDry mobile application UI** built with **Flutter (Dart)** for the SDGP project **Solar-Powered IoT Hybrid Dehydrator System**.

✅ **UI-only implementation** (mock data + simulated BLE/Wi-Fi flows)  
❌ No Firebase / no backend required for this branch

---

## App Summary

HelaDry is a companion mobile app for a solar-powered food dehydrator. The UI is designed to support both:

- **Online Mode** (Wi-Fi + Internet workflow — UI simulation)
- **Offline Mode** (Bluetooth/BLE workflow — UI simulation)

The app includes **Light + Dark themes**, multi-screen navigation, and realistic states such as scanning, connecting, and confirmation steps.

---

## Key Features (UI)

### Authentication UI
- Splash screen
- Login screen (with validation + password visibility toggle)
- Create account screen (with validation + confirm password)
- Demo/Quick Access mode (mock)

### Connection Flow (pre-dashboard)
- Connection Mode selection (Online / Offline)
- Pair Device UI (BLE scan → list → connect)
- Pair Success confirmation
- Wi-Fi Setup Wizard (BLE provisioning UI):
  - Scan Wi-Fi networks
  - Enter password
  - Connection progress + confirmation
  - Saved network UI (mock)

### Main App Screens
- Dashboard (live metrics UI + actions)
- Manual Controls (fan/heater/temp + emergency stop)
- Start New Batch (crop selection + batch settings)
- Crop Drying Guide (recommended temp/time + steps/tips)
- My Records (filters + search + mock history)
- Settings (theme toggle, units, calibration, alerts, device actions)

---

## Tech Stack

- **Flutter (Dart)**
- State Management: **Provider (ChangeNotifier)**
- Local UI simulation: mock services (`MockDeviceService`, `MockWifiService`)
- Themes: Light/Dark via ThemeController

> This UI branch is structured for clean modular code and is ready for later integration with real BLE + Firebase/RTDB.

---

## Getting Started

### Prerequisites
- Flutter SDK installed
- Android Studio / VS Code
- Android emulator or physical device

### Install & Run
```bash
flutter pub get
flutter run
