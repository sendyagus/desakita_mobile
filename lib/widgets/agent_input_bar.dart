import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input bar untuk AgentScreen — menampilkan hint suara, text field,
/// tombol mikrofon (dengan animasi pulse), dan tombol kirim.
class AgentInputBar extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isListening;
  final bool isTyping;
  final bool speechEnabled;
  final double soundLevel;
  final String? speechHint;
  final Animation<double> pulseAnimation;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onShowNoSpeechSupport;

  const AgentInputBar({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.isListening,
    required this.isTyping,
    required this.speechEnabled,
    required this.soundLevel,
    required this.speechHint,
    required this.pulseAnimation,
    required this.onStartListening,
    required this.onStopListening,
    required this.onSendMessage,
    required this.onShowNoSpeechSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isListening || speechHint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isListening ? Icons.mic_rounded : Icons.info_outline,
                    size: 16,
                    color: isListening ? Colors.red[600] : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      speechHint ??
                          (isListening
                              ? 'Mendengarkan…'
                              : 'Siap mendengarkan'),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isListening
                            ? Colors.red[700]
                            : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isListening)
                    SizedBox(
                      width: 48,
                      child: LinearProgressIndicator(
                        value: (soundLevel.clamp(0, 10)) / 10,
                        minHeight: 4,
                        backgroundColor: Colors.red[50],
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) {
                      return KeyEventResult.ignored;
                    }
                    if (event.logicalKey != LogicalKeyboardKey.enter) {
                      return KeyEventResult.ignored;
                    }
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      return KeyEventResult.ignored;
                    }
                    final text = textController.text.trim();
                    if (text.isNotEmpty && !isTyping) {
                      onSendMessage(text);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0),
                      borderRadius: BorderRadius.circular(24),
                      border: isListening
                          ? Border.all(color: Colors.red[300]!, width: 1.5)
                          : null,
                    ),
                    child: TextField(
                      controller: textController,
                      focusNode: focusNode,
                      enabled: !isListening,
                      style: GoogleFonts.poppins(fontSize: 14),
                      maxLines: 1,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: isListening
                            ? 'Bicara sekarang…'
                            : 'Tanyakan sesuatu...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          onSendMessage(value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Tombol mikrofon
              GestureDetector(
                onTap: !speechEnabled
                    ? onShowNoSpeechSupport
                    : (isListening ? onStopListening : onStartListening),
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    final double scale = isListening
                        ? 1.0 + (pulseAnimation.value * 0.12)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !speechEnabled
                              ? Colors.grey[200]
                              : isListening
                              ? Colors.red[600]
                              : const Color(0xFFE8F0E3),
                          boxShadow: [
                            if (isListening)
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 10 + (pulseAnimation.value * 6),
                                spreadRadius: 2 + (pulseAnimation.value * 2),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Icon(
                          !speechEnabled
                              ? Icons.mic_off_rounded
                              : isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: !speechEnabled
                              ? Colors.grey[400]
                              : isListening
                              ? Colors.white
                              : const Color(0xFF2D5016),
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Tombol kirim
              GestureDetector(
                onTap: isTyping
                    ? null
                    : () => onSendMessage(textController.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D5016), Color(0xFF4A7C2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5016).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
