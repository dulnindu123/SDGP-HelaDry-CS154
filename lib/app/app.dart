import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'routes.dart';

// Auth pages
import '../features/auth/pages/splash_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/create_account_page.dart';

// Connection & Pairing
import '../features/connection/pages/connection_mode_page.dart';
import '../features/pair/pages/pair_device_page.dart';
import '../features/pair/pages/pair_success_page.dart';

// Wi-Fi Setup
import '../features/wifi/pages/wifi_setup_ble_step1_page.dart';
import '../features/wifi/pages/wifi_setup_ble_step2_page.dart';
import '../features/wifi/pages/wifi_setup_ble_step3_page.dart';

// Main App Screens
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/controls/pages/manual_controls_page.dart';
import '../features/records/pages/my_records_page.dart';
import '../features/batch/pages/start_new_batch_page.dart';
import '../features/guide/pages/crop_guide_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/settings/pages/edit_profile_page.dart';

class HelaDryApp extends StatelessWidget {
  const HelaDryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'HelaDry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.createAccount: (_) => const CreateAccountPage(),
          AppRoutes.connectionMode: (_) => const ConnectionModePage(),
          AppRoutes.pairDevice: (_) => const PairDevicePage(),
          AppRoutes.pairSuccess: (_) => const PairSuccessPage(),
          AppRoutes.wifiStep1: (_) => const WifiSetupBleStep1Page(),
          AppRoutes.wifiStep2: (_) => const WifiSetupBleStep2Page(),
          AppRoutes.wifiStep3: (_) => const WifiSetupBleStep3Page(),
          AppRoutes.dashboard: (_) => const DashboardPage(),
          AppRoutes.manualControls: (_) => const ManualControlsPage(),
          AppRoutes.myRecords: (_) => const MyRecordsPage(),
          AppRoutes.startNewBatch: (_) => const StartNewBatchPage(),
          AppRoutes.cropGuide: (_) => const CropGuidePage(),
          AppRoutes.settings: (_) => const SettingsPage(),
          AppRoutes.editProfile: (_) => const EditProfilePage(),
        };

        final builder = routes[settings.name];
        if (builder == null) return null;

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            final fadeAnim = CurvedAnimation(parent: animation, curve: curve);
            final slideAnim = Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(position: slideAnim, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
      },
    );
  }
}
