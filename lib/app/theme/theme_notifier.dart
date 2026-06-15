import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier global untuk ThemeMode yang bisa diakses dari mana saja.
///
/// Dipakai oleh [DesaKitaApp] untuk listen perubahan tema,
/// dan oleh screen lain (misal ProfileScreen) untuk mengubah tema.
///
/// Inisialisasi: panggil [ThemeNotifier.instance.load()] di main().
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier._();

  static final ThemeNotifier instance = ThemeNotifier._();

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  /// Muat preferensi dari SharedPreferences. Panggil sekali saat startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  /// Ubah mode tema dan simpan ke SharedPreferences.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', value);
    notifyListeners();
  }

  /// Toggle antara light dan dark.
  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
