import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/services/session_store.dart';

void main() {
  testWidgets('HelaDry app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => SessionStore()),
        ],
        child: const HelaDryApp(),
      ),
    );

    // The splash screen should show the app name
    expect(find.text('HelaDry'), findsOneWidget);
  });
}
