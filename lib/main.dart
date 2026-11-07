import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:desa_wisata/screens/home_screen.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/screens/splash_screen.dart';
import 'package:desa_wisata/screens/booking_screen.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/firebase_options.dart';
import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat API key dari asset env.json (gitignored) — tanpa perlu flag dart-define.
  await AppConfig.loadEnv();

  // Token Mapbox untuk SDK native (web/Android/iOS). Diambil dari env.json.
  if (AppConfig.isMapboxConfigured) {
    MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
  }

  // Initialize Firebase dengan options untuk semua platform
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Web: pulihkan hasil alur redirect Google (bila popup diblokir browser).
  try {
    await AuthService.instance.handlePendingGoogleRedirect();
  } catch (e) {
    debugPrint('⚠️  Pending Google redirect: $e');
  }

  runApp(const DesaKitaApp());
}

class DesaKitaApp extends StatelessWidget {
  const DesaKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
