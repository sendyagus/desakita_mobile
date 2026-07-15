import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/app/theme/theme_notifier.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/services/storage_service.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/models/user_model.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/screens/register_screen.dart';
import 'package:desa_wisata/screens/user/user_booking_history_screen.dart';
import 'package:desa_wisata/screens/user/favorite_destinations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final BookingService _bookingService = BookingService();
  UserModel? _currentUser;
  bool _isLoading = true;
  int _bookingCount = 0;

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _userService.getUserById(userId);
        final bookings = await _bookingService.getUserBookings(userId);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _bookingCount = bookings.length;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _currentUser = null;
          _bookingCount = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_currentUser == null) return;

    var isDialogOpen = false;

    try {
      // Pick image first, so the app does not show an endless loading dialog
      // while the gallery permission/picker is still waiting for user input.
      final image = await _storageService.pickImageFromGallery();
      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5016)),
        ),
      );
      isDialogOpen = true;

      // Upload to Firebase Storage with a clear timeout instead of hanging.
      final imageUrl = await _storageService
          .uploadImage(
            folder: 'users/${_currentUser!.id}',
            file: image,
          )
          .timeout(const Duration(seconds: 45));

      // Update user profile.
      final updatedUser = await _userService
          .updateUser(
            id: _currentUser!.id,
            avatarUrl: imageUrl,
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      setState(() {
        _currentUser = updatedUser;
      });

      if (isDialogOpen) {
        Navigator.pop(context); // Close loading
        isDialogOpen = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto profil berhasil diperbarui',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF2D5016),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on TimeoutException {
      if (mounted) {
        if (isDialogOpen) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload foto terlalu lama. Periksa koneksi internet lalu coba lagi.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (isDialogOpen) Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal upload foto: $e',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _menuItems => [
    {
      'icon': Icons.history_outlined,
      'label': 'Riwayat Booking',
    },
    {
      'icon': Icons.favorite_outline,
      'label': 'Destinasi Favorit',
    },
    {
      'icon': Icons.location_on_outlined,
      'label': 'Alamat Saya',
    },
    {
      'icon': Icons.credit_card_outlined,
      'label': 'Metode Pembayaran',
    },
    {
      'icon': Icons.notifications_outlined,
      'label': 'Notifikasi',
    },
    {
      'icon': Icons.language_outlined,
      'label': 'Bahasa',
    },
    {
      'icon': Icons.info_outline,
      'label': 'Tentang DesaKita',
    },
    {
      'icon': Icons.help_outline_rounded,
      'label': 'Bantuan & FAQ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5016)),
        ),
      );
    } else if (!_isLoggedIn) {
      content = Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildGuestLoginPrompt(context)),
            ],
          ),
        ),
      );
    } else {
      content = Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildAvatar(),
                      const SizedBox(height: 14),
                      Text(
                        _currentUser?.fullName ?? 'Nama Pengguna',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? FirebaseAuth.instance.currentUser?.email ?? '',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      _buildMemberBadge(),
                      const SizedBox(height: 20),
                      _buildStats(),
                      const SizedBox(height: 24),
                      _buildMenuList(context),
                      const SizedBox(height: 16),
                      _buildDarkModeToggle(context),
                      const SizedBox(height: 20),
                      _buildLogoutButton(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          // Mendeteksi geseran (swipe) baik dari kanan ke kiri (velocity < -300) maupun kiri ke kanan (velocity > 300)
          if (details.primaryVelocity!.abs() > 300) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        }
      },
      child: content,
    );
  }

  Widget _buildGuestLoginPrompt(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8EDE3),
              border: Border.all(color: const Color(0xFF2D5016), width: 2),
            ),
            child: const Icon(Icons.person_outline, size: 52, color: Color(0xFF2D5016)),
          ),
          const SizedBox(height: 20),
          Text(
            'Masuk ke DesaKita',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Login untuk booking penginapan & wisata, melihat riwayat pesanan, dan menyimpan favorit destinasi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 28),
          _guestBenefit(Icons.confirmation_number_outlined, 'Booking penginapan & wisata'),
          _guestBenefit(Icons.history_outlined, 'Riwayat booking (disetujui & menunggu)'),
          _guestBenefit(Icons.favorite_border, 'Simpan destinasi favorit'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                _loadUserData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Login', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
                _loadUserData();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2D5016), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Daftar Akun Baru',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D5016),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _guestBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF2D5016)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF333333))),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Judul tengah
          Text(
            'DesaKita',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF2D5016),
            ),
          ),
          // Tombol kembali di kiri
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8EDE3),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF2D5016),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A2E),
            border: Border.all(
              color: const Color(0xFF2D5016),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: _currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty
                ? _TimedAvatarImage(imageUrl: _currentUser!.avatarUrl!)
                : const Icon(
                    Icons.person,
                    size: 52,
                    color: Colors.white70,
                  ),
          ),
        ),
        // Tombol edit foto
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _uploadProfilePhoto,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Member Badge ──────────────────────────────────────────────────────────

  Widget _buildMemberBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2D5016), width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2D5016),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Sahabat DesaKita',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D5016),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserBookingHistoryScreen()),
              ).then((_) => _loadUserData());
            },
            child: _StatCard(value: '$_bookingCount', label: 'Booking'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoriteDestinationsScreen()),
              ).then((_) => _loadUserData());
            },
            child: _StatCard(
              value: '${_currentUser?.favorites.length ?? 0}',
              label: 'Favorit',
            ),
          ),
        ),
      ],
    );
  }

  // ─── Menu List ─────────────────────────────────────────────────────────────

  Widget _buildMenuList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_menuItems.length, (index) {
          final item = _menuItems[index];
          final isLast = index == _menuItems.length - 1;
          return _MenuItem(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            showDivider: !isLast,
            onTap: () => _handleMenuTap(context, item['label'] as String),
          );
        }),
      ),
    );
  }

  // ─── Dark Mode Toggle ──────────────────────────────────────────────────────

  Widget _buildDarkModeToggle(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        final isDark = ThemeNotifier.instance.isDark;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: const Color(0xFF2D5016),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Mode Gelap',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (_) => ThemeNotifier.instance.toggle(),
                activeTrackColor: const Color(0xFF2D5016),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Logout Button ─────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        icon: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFE53935),
          size: 20,
        ),
        label: Text(
          'Keluar',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE53935),
          ),
        ),
      ),
    );
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  void _handleMenuTap(BuildContext context, String label) {
    if (label == 'Riwayat Booking') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserBookingHistoryScreen()),
      ).then((_) => _loadUserData());
      return;
    }
    if (label == 'Destinasi Favorit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoriteDestinationsScreen()),
      ).then((_) => _loadUserData());
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label — segera hadir',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF2D5016),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari akun ini?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              // Navigate ke AuthGate dan hapus semua route sebelumnya
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

}

class _TimedAvatarImage extends StatefulWidget {
  final String imageUrl;

  const _TimedAvatarImage({required this.imageUrl});

  @override
  State<_TimedAvatarImage> createState() => _TimedAvatarImageState();
}

class _TimedAvatarImageState extends State<_TimedAvatarImage> {
  Timer? _timer;
  bool _isTakingTooLong = false;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void didUpdateWidget(covariant _TimedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _isTakingTooLong = false;
      _startTimeout();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 12), () {
      if (mounted) {
        setState(() => _isTakingTooLong = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isTakingTooLong) {
      return const Icon(
        Icons.person,
        size: 52,
        color: Colors.white70,
      );
    }

    return Image.network(
      widget.imageUrl,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        _timer?.cancel();
        return const Icon(
          Icons.person,
          size: 52,
          color: Colors.white70,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _timer?.cancel();
          return child;
        }
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D5016),
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8D0), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D5016),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showDivider;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: const Color(0xFF2D5016)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 54,
            endIndent: 18,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}


