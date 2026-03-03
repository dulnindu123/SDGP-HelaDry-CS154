// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:heladry/dashboard_screen.dart';
import 'package:heladry/main.dart';

void main() {
  // Existing test
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HelaDryApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  // New test for Firebase Realtime Database
  test('Firebase Realtime Database structure test', () async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseDatabase database = FirebaseDatabase.instance;

    // Sign in anonymously for testing
    final UserCredential userCredential = await auth.signInAnonymously();
    final String uid = userCredential.user!.uid;

    // Set test data
    final DatabaseReference deviceRef = database.ref('devices/device-001');
    await deviceRef.set({'owner': uid});

    final DatabaseReference userDeviceRef = database.ref(
      'users/$uid/devices/device-001',
    );
    await userDeviceRef.set(true);

    // Verify data
    final DataSnapshot deviceSnapshot = await deviceRef.get();
    expect(deviceSnapshot.value, {'owner': uid});

    final DataSnapshot userDeviceSnapshot = await userDeviceRef.get();
    expect(userDeviceSnapshot.value, true);

    // Clean up
    await deviceRef.remove();
    await userDeviceRef.remove();
  });
}
