import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/app/app_assets.dart';

/// Header bar untuk AgentScreen — menampilkan avatar bot, nama, status,
/// tombol toggle TTS (auto-read), dan tombol hapus riwayat chat.
class AgentChatHeader extends StatelessWidget {
  final bool isTtsActive;
  final bool messagesEmpty;
  final VoidCallback onToggleTts;
  final VoidCallback onClearChat;

  const AgentChatHeader({
    super.key,
    required this.isTtsActive,
    required this.messagesEmpty,
    required this.onToggleTts,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // Avatar bot
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D5016).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(AppAssets.kitaAiIcon, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(width: 12),

              // Nama & status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KITA — Asisten DesaKita',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online • Siap membantu',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol Toggle TTS (Auto-Read)
              IconButton(
                onPressed: onToggleTts,
                icon: Icon(
                  isTtsActive
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: isTtsActive
                      ? const Color(0xFF2D5016)
                      : Colors.grey[400],
                  size: 22,
                ),
              ),

              // Tombol hapus riwayat
              IconButton(
                onPressed: messagesEmpty ? null : onClearChat,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: messagesEmpty
                      ? Colors.grey[300]
                      : Colors.grey[500],
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
