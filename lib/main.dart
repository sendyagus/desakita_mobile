import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:desa_wisata/app/desa_kita_app.dart';
import 'package:desa_wisata/app/theme/theme_notifier.dart';
import 'package:desa_wisata/firebase_options.dart';

Future<void> main() async {
  // Global error handler — tangkap error yang tidak di-handle oleh try/catch.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Muat preferensi tema dari SharedPreferences
    await ThemeNotifier.instance.load();

    // Tangkap error dari widget build / framework Flutter.
    FlutterError.onError = (details) {
      debugPrint('🔴 FlutterError: ${details.exceptionAsString()}');
      if (details.stack != null) debugPrint(details.stack.toString());
    };

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
        enabled: !kReleaseMode,
        builder: (context) => const DesaKitaApp(),
      ),
    );
  }, (error, stack) {
    // Tangkap error async yang lolos dari zona (uncaught).
    debugPrint('🔴 Uncaught error: $error');
    debugPrint(stack.toString());
  });
}
