import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/fix_old_image_urls.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  bool _isFixing = false;
  bool _isVerifying = false;
  String _resultMessage = '';

  Future<void> _fixAllUrls() async {
    setState(() {
      _isFixing = true;
      _resultMessage = '';
    });

    try {
      await FixOldImageUrls.fixAllDestinations();
      if (mounted) {
        setState(() {
          _resultMessage = 'Berhasil memperbaiki URL gambar! Lihat console untuk detail.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'URL gambar berhasil diperbaiki',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFixing = false);
      }
    }
  }

  Future<void> _verifyAllUrls() async {
    setState(() {
      _isVerifying = true;
      _resultMessage = '';
    });

    try {
      await FixOldImageUrls.verifyAllUrls();
      if (mounted) {
        setState(() {
          _resultMessage = 'Verifikasi selesai! Lihat console untuk detail.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verifikasi selesai, cek console',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Admin Tools',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Perbaikan & Maintenance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tools untuk memperbaiki data dan melakukan maintenance database',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Fix Image URLs Card
            _buildToolCard(
              icon: Icons.image_outlined,
              title: 'Perbaiki URL Gambar',
              description:
                  'Mengubah format URL gambar lama (uc?export=view) menjadi format thumbnail yang lebih stabil',
              buttonText: 'Perbaiki Semua URL',
              isLoading: _isFixing,
              onPressed: _fixAllUrls,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Verify URLs Card
            _buildToolCard(
              icon: Icons.verified_outlined,
              title: 'Verifikasi URL Gambar',
              description:
                  'Memeriksa semua URL gambar di database dan menampilkan informasi di console',
              buttonText: 'Verifikasi Semua URL',
              isLoading: _isVerifying,
              onPressed: _verifyAllUrls,
              color: Colors.green,
            ),

            const SizedBox(height: 24),

            // Result Message
            if (_resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultMessage.startsWith('Error')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _resultMessage.startsWith('Error')
                        ? Colors.red[300]!
                        : Colors.green[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resultMessage.startsWith('Error')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _resultMessage.startsWith('Error')
                          ? Colors.red[800]
                          : Colors.green[800],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _resultMessage.startsWith('Error')
                              ? Colors.red[900]
                              : Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Perbaikan URL akan mengubah semua URL gambar lama ke format baru\n'
                    '• Proses ini aman dan tidak akan menghapus data\n'
                    '• Lihat console/terminal untuk melihat detail proses\n'
                    '• Backup data sebelum melakukan perbaikan massal',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[900],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
