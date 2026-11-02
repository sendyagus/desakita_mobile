import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:desa_wisata/screens/home_screen.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/screens/splash_screen.dart';
import 'package:desa_wisata/screens/booking_screen.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/firebase_options.dart';

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

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const DesaKitaApp(),
    ),
  );
}

class DesaKitaApp extends StatelessWidget {
  const DesaKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'DesaKita',
      debugShowCheckedModeBanner: false,
      theme: DesaKitaTheme.light,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/services': (context) => const BookingScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
