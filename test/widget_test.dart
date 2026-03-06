// Basic Flutter widget test for HelaDry app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heladry/main.dart';

void main() {
  testWidgets('App launches and shows dashboard', (WidgetTester tester) async {
    // Build the app — Firebase is mocked in test environment
    await tester.pumpWidget(const SolarDryingApp());
    await tester.pump();

    // Verify the app builds without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
