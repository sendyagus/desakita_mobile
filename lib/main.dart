import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:desa_wisata/screens/home_screen.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/screens/opening_screen.dart';
import 'package:desa_wisata/screens/onboarding_screen.dart';
import 'package:desa_wisata/widgets/auth_gate.dart';
import 'package:desa_wisata/firebase_options.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase dengan options untuk semua platform
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Run app dengan DevicePreview
  // Aktif hanya di debug mode, non-aktif di release mode
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Aktif di debug mode, non-aktif di release
      builder: (context) => const DesaKitaApp(),
    ),
  );
}

class DesaKitaApp extends StatelessWidget {
  const DesaKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // DevicePreview configuration
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      scrollBehavior: MyCustomScrollBehavior(),

      title: 'DesaKita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5016),
          primary: const Color(0xFF2D5016),
        ),
        useMaterial3: true,
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/auth': (context) => const AuthGate(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      home: const OpeningScreen(),
    );
  }
}
