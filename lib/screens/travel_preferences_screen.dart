import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/screens/home_screen.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({super.key});

  @override
  State<TravelPreferencesScreen> createState() =>
      _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  int _step = 0;
  bool _saving = false;
  String? _age;
  String? _budget;
  String? _style;
  String? _companion;

  final List<Map<String, dynamic>> _questions = const [
    {
      'title': 'Berapa usia kamu?',
      'subtitle': 'Biar Kita AI bisa membantu memilih destinasi yang sesuai.',
      'key': 'ageRange',
      'options': ['< 18 Tahun', '18 - 24 Tahun', '25 - 34 Tahun', '> 35 Tahun'],
    },
    {
      'title': 'Berapa rata-rata budget liburan kamu?',
      'subtitle': 'Kami akan menyesuaikan rekomendasi dengan anggaranmu.',
      'key': 'budget',
      'options': [
        '< 300 ribu',
        '300 - 700 ribu',
        '700 ribu - 1,5 juta',
        '> 1,5 juta',
      ],
    },
    {
      'title': 'Gaya liburan apa yang kamu sukai?',
      'subtitle': 'Pilih vibe yang paling menggambarkan dirimu.',
      'key': 'travelStyle',
      'options': [
        'Healing Santai',
        'Petualangan Alam',
        'Hunting Foto & Kuliner',
      ],
    },
    {
      'title': 'Dengan siapa biasanya kamu berwisata?',
      'subtitle': 'Pilih teman perjalanan yang paling sering menemanimu.',
      'key': 'companion',
      'options': ['Sendiri', 'Keluarga', 'Pasangan', 'Teman-teman'],
    },
  ];

  String? get _selectedValue {
    switch (_step) {
      case 0:
        return _age;
      case 1:
        return _budget;
      case 2:
        return _style;
      case 3:
        return _companion;
      default:
        return null;
    }
  }

  void _setSelected(String value) {
    setState(() {
      switch (_step) {
        case 0:
          _age = value;
          break;
        case 1:
          _budget = value;
          break;
        case 2:
          _style = value;
          break;
        case 3:
          _companion = value;
          break;
      }
    });
  }

  Future<void> _continue() async {
    if (_step < _questions.length - 1) {
      if (_selectedValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih satu jawaban untuk melanjutkan.'),
          ),
        );
        return;
      }
      setState(() => _step++);
      return;
    }
    if (_companion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih satu jawaban atau lewati proses ini.'),
        ),
      );
      return;
    }
    await _savePreferences(skipped: false);
  }

  Future<void> _savePreferences({required bool skipped}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'preferencesCompleted': true,
        'travelPreferences': <String, dynamic>{
          if (_age != null) 'ageRange': _age,
          if (_budget != null) 'budget': _budget,
          if (_style != null) 'travelStyle': _style,
          if (_companion != null) 'companion': _companion,
          'skipped': skipped,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preferensi belum berhasil disimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_step];
    final options = question['options'] as List<String>;

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: _step == 0
                        ? null
                        : () => setState(() => _step--),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: DesaKitaColors.darkGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _questions.length,
                        (index) => Expanded(
                          child: Container(
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index <= _step
                                  ? DesaKitaColors.primary
                                  : const Color(0xFFDDE2DA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _savePreferences(skipped: true),
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 35, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: DesaKitaColors.mutedGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _step == 0
                            ? Icons.person_outline_rounded
                            : _step == 1
                            ? Icons.account_balance_wallet_outlined
                            : _step == 2
                            ? Icons.landscape_outlined
                            : Icons.people_outline_rounded,
                        color: DesaKitaColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      question['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question['subtitle'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.55,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...options.map((option) {
                      final selected = _selectedValue == option;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _setSelected(option),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 17,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFC9F7DC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? DesaKitaColors.primary
                                    : const Color(0xFFDDE2DA),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: selected
                                          ? DesaKitaColors.darkGreen
                                          : DesaKitaColors.text,
                                    ),
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 20,
                                  color: selected
                                      ? DesaKitaColors.primary
                                      : const Color(0xFFC7CDC5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    Text(
                      'Jawaban ini digunakan untuk personalisasi rekomendasi. Kamu bisa melewati langkah ini.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        height: 1.5,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _continue,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step == _questions.length - 1
                              ? 'Mulai Explorasi'
                              : 'Lanjut',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
