import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/screens/admin/user_management_screen.dart';
import 'package:desa_wisata/screens/admin/destination_management_screen.dart';
import 'package:desa_wisata/screens/admin/booking_management_screen.dart';
import 'package:desa_wisata/screens/admin/event_management_screen.dart';
import 'package:desa_wisata/screens/admin/booking_analytics_screen.dart';
import 'package:desa_wisata/services/stats_service.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final StatsService _statsService = StatsService();
  final UserService _userService = UserService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentActivities = [];
  UserModel? _currentAdmin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _statsService.getAllStats();
      final activities = await _statsService.getRecentActivities();
      
      // Load admin user data
      final userId = FirebaseAuth.instance.currentUser?.uid;
      UserModel? admin;
      if (userId != null) {
        admin = await _userService.getUserById(userId);
      }
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentActivities = activities;
          _currentAdmin = admin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D5016),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF2D5016),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statistik cards
                            _buildStatsGrid(),

                            const SizedBox(height: 24),

                            // Menu utama
                            _buildMainMenu(),

                            const SizedBox(height: 24),

                            // Aktivitas terbaru
                            _buildRecentActivities(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar admin
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
              ),
              border: Border.all(color: const Color(0xFF2D5016), width: 2),
            ),
            child: ClipOval(
              child: _currentAdmin?.avatarUrl != null && _currentAdmin!.avatarUrl!.isNotEmpty
                  ? Image.network(
                      _currentAdmin!.avatarUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 22,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                  : const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Info admin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAdmin?.fullName ?? 'Dashboard Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _currentAdmin?.email ?? 'Kelola sistem DesaKita',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Logout button
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
            color: const Color(0xFFE53935),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Yakin ingin keluar dari dashboard admin?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal logout: $e',
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
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Grid ────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Hari Ini',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.people_outline,
              label: 'Total User',
              value: _stats!['totalUsers'].toString(),
              color: const Color(0xFF2196F3),
              trend: '+${_stats!['newUsersToday']} hari ini',
            ),
            _StatCard(
              icon: Icons.place_outlined,
              label: 'Destinasi',
              value: _stats!['totalDestinations'].toString(),
              color: const Color(0xFF4CAF50),
              trend: '${_stats!['activeDestinations']} aktif',
            ),
            _StatCard(
              icon: Icons.confirmation_number_outlined,
              label: 'Booking',
              value: _stats!['totalBookings'].toString(),
              color: const Color(0xFFFF9800),
              trend: '${_stats!['activeBookings']} aktif',
            ),
            _StatCard(
              icon: Icons.attach_money_outlined,
              label: 'Pendapatan',
              value: _stats!['totalRevenue'],
              color: const Color(0xFF9C27B0),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Main Menu ─────────────────────────────────────────────────────────────

  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Utama',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.people_outline,
          title: 'Kelola User',
          subtitle: 'Lihat dan kelola data pengguna',
          color: const Color(0xFF2196F3),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UserManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MenuCard(
          icon: Icons.place_outlined,
          title: 'Kelola Destinasi Wisata',
          subtitle: 'Tambah, edit, hapus destinasi',
          color: const Color(0xFF4CAF50),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DestinationManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MenuCard(
          icon: Icons.confirmation_number_outlined,
          title: 'Kelola Booking',
          subtitle: 'Lihat dan kelola pemesanan',
          color: const Color(0xFFFF9800),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BookingManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _MenuCard(
          icon: Icons.event_outlined,
          title: 'Kelola Acara',
          subtitle: 'Tambah dan kelola event desa',
          color: const Color(0xFF9C27B0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventManagementScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        _MenuCard(
          icon: Icons.bar_chart_outlined,
          title: 'Laporan & Analitik',
          subtitle: 'Laporan booking & pendapatan',
          color: const Color(0xFFE91E63),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingAnalyticsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ─── Recent Activities ─────────────────────────────────────────────────────

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            TextButton(
              onPressed: _loadData,
              child: Row(
                children: [
                  const Icon(Icons.refresh, size: 16, color: Color(0xFF2D5016)),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D5016),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Belum ada aktivitas',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
            ),
          )
        else
          Container(
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
              children: List.generate(_recentActivities.length, (index) {
                final activity = _recentActivities[index];
                final isLast = index == _recentActivities.length - 1;
                return _ActivityItem(
                  icon: _getIconData(activity['icon'] as String),
                  title: activity['title'] as String,
                  subtitle: activity['subtitle'] as String,
                  time: activity['time'] as String,
                  color: _getColorByType(activity['type'] as String),
                  showDivider: !isLast,
                );
              }),
            ),
          ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_add_outlined':
        return Icons.person_add_outlined;
      case 'bookmark_added_outlined':
        return Icons.bookmark_added_outlined;
      case 'place_outlined':
        return Icons.place_outlined;
      case 'event_outlined':
        return Icons.event_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorByType(String type) {
    switch (type) {
      case 'user':
        return const Color(0xFF4CAF50);
      case 'booking':
        return const Color(0xFF2196F3);
      case 'destination':
        return const Color(0xFFFF9800);
      case 'event':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend!,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Item ────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool showDivider;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}
