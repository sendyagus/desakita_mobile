import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Layar Bahasa — memilih bahasa antarmuka (ID/EN).
///
/// Pilihan disimpan ke SharedPreferences (key [LanguageScreen.prefsKey]).
/// Perubahan bahasa penuh (L10n) belum diterapkan ke seluruh UI; layar ini
/// menyimpan preferensi dan memberi umpan balik ke pengguna.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  static const String prefsKey = 'app_language';

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'id';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () => _selected = prefs.getString(LanguageScreen.prefsKey) ?? 'id',
    );
  }

  Future<void> _select(String code) async {
    if (_selected == code) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LanguageScreen.prefsKey, code);
    if (!mounted) return;
    setState(() => _selected = code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          code == 'id'
              ? 'Bahasa Indonesia dipilih'
              : 'English selected (terjemahan penuh segera hadir)',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: DesaKitaColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      appBar: AppBar(
        backgroundColor: DesaKitaColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: DesaKitaColors.text,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bahasa',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DesaKitaColors.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(
            'Pilih bahasa pilihan Anda untuk antarmuka aplikasi DesaKita.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _LanguageTile(
            code: 'ID',
            title: 'Bahasa Indonesia',
            subtitle: 'Bahasa Sistem',
            selected: _selected == 'id',
            onTap: () => _select('id'),
          ),
          const SizedBox(height: 12),
          _LanguageTile(
            code: 'EN',
            title: 'English',
            subtitle: null,
            selected: _selected == 'en',
            onTap: () => _select('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? DesaKitaColors.primary : DesaKitaColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesaKitaColors.warmSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  code,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DesaKitaColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? DesaKitaColors.primary : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
