# heladry

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:
System Architecture

## HelaDry is an IoT-based smart solar drying system built using:

ESP32 → Which Sends telemetry data

Firebase Realtime Database → For Cloud backend

Firebase Authentication (Email/Password) → For User authentication

Flutter → Mobile & Web application
Architecture Flow:
ESP32 → Firebase Realtime Database → Flutter App

Authentication Model:
Users sign up / log in using Firebase Authentication.

Each authenticated user is assigned a unique uid.

All user-specific data is structured under that uid to ensure data isolation.

Device ownership is mapped securely to authenticated users.

## Firebase Realtime Database Schema

## Firebase Realtime Database Schema

The system is structured to support secure multi-user device ownership and session tracking.

### Users Node

users/
{uid}/
devices/
{deviceId}: true

    sessions/
      {sessionId}/
        crop: string
        startTime: timestamp
        status: active | completed
        deviceId: string

Each authenticated user only accesses their own `{uid}` node.

---

### Devices Node

devices/
{deviceId}/
owner: {uid}

    telemetry/
      temperature: number
      humidity: number
      lastUpdated: timestamp

Devices are linked to a single user via the `owner` field.

## Device - User Linking Logic

users/{uid}/devices/{deviceId} = true
devices/{deviceId}/owner = {uid}

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
