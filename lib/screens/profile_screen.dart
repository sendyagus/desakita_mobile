import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/services/storage_service.dart';
import 'package:desa_wisata/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  UserModel? _currentUser;
  bool _isLoading = true;

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
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5016)),
        ),
      );

      // Pick image
      final image = await _storageService.pickImageFromGallery();
      if (image == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Upload to Firebase Storage
      final imageUrl = await _storageService.uploadImage(
        folder: 'users/${_currentUser!.id}',
        file: image,
      );

      // Update user profile
      await _userService.updateUser(
        id: _currentUser!.id,
        avatarUrl: imageUrl,
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        Navigator.pop(context); // Close loading
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
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
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

  final List<Map<String, dynamic>> _menuItems = const [
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5016)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(context),

            // Konten scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Avatar
                    _buildAvatar(),

                    const SizedBox(height: 14),

                    // Nama
                    Text(
                      _currentUser?.fullName ?? 'Nama Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      _currentUser?.email ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Badge member
                    _buildMemberBadge(),

                    const SizedBox(height: 20),

                    // Statistik
                    _buildStats(),

                    const SizedBox(height: 24),

                    // Menu list
                    _buildMenuList(context),

                    const SizedBox(height: 20),

                    // Tombol Keluar
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
          // Ikon menu kiri
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showDrawerMenu(context),
              child: const Icon(
                Icons.menu_rounded,
                size: 26,
                color: Color(0xFF2D5016),
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
                ? Image.network(
                    _currentUser!.avatarUrl!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 52,
                        color: Colors.white70,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2D5016),
                          strokeWidth: 2,
                        ),
                      );
                    },
                  )
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
          child: _StatCard(value: '12', label: 'Favorit'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(value: '8', label: 'Ulasan'),
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
    // Placeholder — navigasi ke sub-halaman masing-masing
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

  void _showDrawerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Menu',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            _DrawerItem(
                icon: Icons.edit_outlined, label: 'Edit Profil'),
            _DrawerItem(
                icon: Icons.history_outlined, label: 'Riwayat Perjalanan'),
            _DrawerItem(
                icon: Icons.bookmark_outline, label: 'Tersimpan'),
            _DrawerItem(
                icon: Icons.star_outline, label: 'Ulasan Saya'),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

// ─── Drawer Item ──────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DrawerItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF2D5016), size: 22),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 18, color: Colors.grey),
      onTap: () => Navigator.pop(context),
    );
  }
}
