import 'package:desa_wisata/screens/admin/admin_dashboard_screen.dart';
import 'package:desa_wisata/screens/home_screen.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Jangan blok hanya karena firebase_options.dart placeholder.
    // Android/iOS bisa init tanpa options jika file native config sudah ada.
    if (Firebase.apps.isEmpty) {
      return const _FirebaseNotConfiguredScreen();
    }

    return StreamBuilder<fa.User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null &&
            !snapshot.hasError) {
          return const _AuthLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder(
          future: AuthService.instance.getCurrentUserProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState != ConnectionState.done) {
              return const _AuthLoadingScreen();
            }

            final profile = profileSnap.data;
            if (profile != null && profile.isAdmin) {
              return const AdminDashboardScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _FirebaseNotConfiguredScreen extends StatelessWidget {
  const _FirebaseNotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Firebase belum dikonfigurasi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Jalankan:\n  flutterfire configure\n\n'
                'Lalu letakkan google-services.json (Android) dan '
                'GoogleService-Info.plist (iOS). Lihat FIREBASE_SETUP.md.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
