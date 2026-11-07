import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Layar "Tentang DesaKita" — profil singkat aplikasi, misi, statistik, dan
/// panduan pengguna. Konten bersifat statis.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHero(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMissionCard(context),
                    const SizedBox(height: 24),
                    Text(
                      'Panduan Pengguna',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildGuideTile(
                      icon: Icons.search,
                      iconColor: const Color(0xFFB5730A),
                      title: 'Menjelajahi Destinasi',
                      subtitle:
                          'Cari dan filter wisata alam serta UMKM di tab Explorasi.',
                    ),
                    _buildGuideTile(
                      icon: Icons.confirmation_number_outlined,
                      iconColor: DesaKitaColors.primary,
                      title: 'Memesan Tiket',
                      subtitle:
                          'Pilih jadwal & sesi, isi identitas, lalu selesaikan pembayaran.',
                    ),
                    _buildGuideTile(
                      icon: Icons.support_agent_outlined,
                      iconColor: const Color(0xFF2196F3),
                      title: 'Bantuan KITA AI',
                      subtitle:
                          'Tanyakan rekomendasi perjalanan ke asisten KITA AI kapan saja.',
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'DesaKita versi 1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: _RoundBackButton(onTap: () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _CurvedBottomClipper(),
          child: Image.asset(
            'assets/img/banner1.png',
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(height: 300, color: DesaKitaColors.primary),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'GUIDEBOOK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: DesaKitaColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mengenal Lebih Dekat\nDesaKita',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesaKitaColors.surfaceGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesaKitaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: DesaKitaColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Misi Kami',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DesaKitaColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'DesaKita lahir dari keinginan akan keaslian alam dan budaya. Kami berdedikasi untuk menghubungkan wisatawan dengan permata tersembunyi di pelosok nusantara, sekaligus memberdayakan UMKM desa agar tumbuh berkelanjutan.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: DesaKitaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _StatBox(value: '100+', label: 'Desa Mitra'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatBox(value: '500+', label: 'UMKM Lokal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RoundBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back_rounded, color: DesaKitaColors.text),
        ),
      ),
    );
  }
}

/// Memberi lengkungan halus pada bagian bawah gambar hero.
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 30);
    path.quadraticBezierTo(size.width / 2, size.height, 0, size.height - 30);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
