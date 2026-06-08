import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget untuk testing berbagai alignment pada background image
/// Gunakan ini untuk menemukan alignment terbaik untuk gambar Anda
class ImageAlignmentTester extends StatefulWidget {
  final String imagePath;

  const ImageAlignmentTester({super.key, required this.imagePath});

  @override
  State<ImageAlignmentTester> createState() => _ImageAlignmentTesterState();
}

class _ImageAlignmentTesterState extends State<ImageAlignmentTester> {
  double _alignX = 0.0;
  double _alignY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image dengan alignment yang bisa diatur
          Positioned.fill(
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              alignment: Alignment(_alignX, _alignY),
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, size: 80),
                  ),
                );
              },
            ),
          ),

          // Overlay gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Controls
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Image Alignment Tester',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // X Alignment
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              'X (${_alignX.toStringAsFixed(2)})',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _alignX,
                              min: -1.0,
                              max: 1.0,
                              divisions: 20,
                              label: _alignX.toStringAsFixed(2),
                              activeColor: const Color(0xFF2D5016),
                              onChanged: (value) =>
                                  setState(() => _alignX = value),
                            ),
                          ),
                        ],
                      ),

                      // Y Alignment
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Y (${_alignY.toStringAsFixed(2)})',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _alignY,
                              min: -1.0,
                              max: 1.0,
                              divisions: 20,
                              label: _alignY.toStringAsFixed(2),
                              activeColor: const Color(0xFF2D5016),
                              onChanged: (value) =>
                                  setState(() => _alignY = value),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Code output
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          'alignment: Alignment(${_alignX.toStringAsFixed(1)}, ${_alignY.toStringAsFixed(1)})',
                          style: GoogleFonts.sourceCodePro(fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Quick presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PresetButton(
                            'Center',
                            onTap: () => setState(() {
                              _alignX = 0.0;
                              _alignY = 0.0;
                            }),
                          ),
                          _PresetButton(
                            'Top',
                            onTap: () => setState(() {
                              _alignX = 0.0;
                              _alignY = -1.0;
                            }),
                          ),
                          _PresetButton(
                            'Bottom',
                            onTap: () => setState(() {
                              _alignX = 0.0;
                              _alignY = 1.0;
                            }),
                          ),
                          _PresetButton(
                            'Left',
                            onTap: () => setState(() {
                              _alignX = -1.0;
                              _alignY = 0.0;
                            }),
                          ),
                          _PresetButton(
                            'Right',
                            onTap: () => setState(() {
                              _alignX = 1.0;
                              _alignY = 0.0;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D5016),
        side: const BorderSide(color: Color(0xFF2D5016)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 11),
      ),
    );
  }
}

/// Cara menggunakan:
/// 
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ImageAlignmentTester(
///       imagePath: 'assets/img/cs1.png',
///     ),
///   ),
/// );
