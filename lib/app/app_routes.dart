import 'package:flutter/material.dart';

import 'package:desa_wisata/screens/home_screen.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/screens/onboarding_screen.dart';
import 'package:desa_wisata/screens/opening_screen.dart';
import 'package:desa_wisata/widgets/auth_gate.dart';

class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';

  static Map<String, WidgetBuilder> get routes => {
    root: (context) => const OpeningScreen(),
    home: (context) => const HomeScreen(),
    login: (context) => const LoginScreen(),
    auth: (context) => const AuthGate(),
    onboarding: (context) => const OnboardingScreen(),
  };
}
