import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/design_system/design_system.dart';
import 'services/push_notification_service.dart';
import 'presentation/navigation/auth_wrapper.dart';

// Exports for backward compatibility across existing views and tests
export 'presentation/navigation/auth_wrapper.dart';
export 'presentation/widgets/modern_digital_clock_card.dart';
export 'views/auth/login_screen.dart';
export 'views/onboarding/join_company_screen.dart';
export 'views/employee/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().initialize();
  await AppThemeNotifier.instance.initialize();
  runApp(const MyBiometricApp());
}

class MyBiometricApp extends StatelessWidget {
  const MyBiometricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'myBiometric',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: AppThemeNotifier.instance.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
