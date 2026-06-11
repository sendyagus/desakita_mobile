import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/image_url_helper.dart';

/// Gambar dari URL (Firebase Storage / Google Drive) dengan fallback placeholder.
/// Untuk Google Drive mencoba beberapa URL jika yang pertama gagal (CORS/web).
class AppNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String placeholderLabel;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderLabel = '',
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  late List<String> _urls;
  int _index = 0;
  bool _advanceScheduled = false;

  @override
  void initState() {
    super.initState();
    _urls = _buildUrlList();
    if (_urls.isNotEmpty) {
      debugPrint('🖼️ AppNetworkImage: ${_urls.length} URL candidates');
      debugPrint('   First URL: ${_urls.first}');
    }
  }

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _urls = _buildUrlList();
      _index = 0;
      _advanceScheduled = false;
    }
  }

  List<String> _buildUrlList() {
    final raw = widget.imageUrl?.trim();
    if (raw == null || raw.isEmpty) return [];

    final driveCandidates = ImageUrlHelper.googleDriveCandidatesFromUrl(raw);
    if (driveCandidates != null && driveCandidates.isNotEmpty) {
      return driveCandidates;
    }

    final resolved = ImageUrlHelper.resolveDisplayUrl(raw);
    if (resolved == null) return [];
    return [resolved];
  }

  void _scheduleNextDriveUrl() {
    if (_index + 1 >= _urls.length || _advanceScheduled) return;
    _advanceScheduled = true;
    debugPrint('⚠️ Image load failed, trying next URL (${_index + 1}/${_urls.length})');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _advanceScheduled = false;
      if (!mounted) return;
      if (_index + 1 < _urls.length) {
        setState(() => _index++);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty) {
      return _wrap(_placeholder());
    }

    final url = _urls[_index];
    final image = Image.network(
      url,
      key: ValueKey('$url-$_index'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // Web: pakai <img> agar gambar Google Drive tidak diblokir CORS (CanvasKit fetch).
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image error at index $_index: $error');
        _scheduleNextDriveUrl();
        return _index + 1 < _urls.length ? _loadingBox() : _placeholder();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          debugPrint('✅ Image loaded successfully: $url');
          return child;
        }
        return _loadingBox();
      },
    );

    return _wrap(image);
  }

  Widget _wrap(Widget child) {
    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }

  Widget _loadingBox() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFD8DDD0),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Color(0xFF2D5016),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFD8DDD0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 28, color: Colors.grey[500]),
          if (widget.placeholderLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.placeholderLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
