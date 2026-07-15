import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

  // Fallback: byte-fetch via HTTP saat Image.network gagal.
  Uint8List? _fallbackBytes;
  bool _fallbackLoading = false;

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
      _fallbackBytes = null;
      _fallbackLoading = false;
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
    if (_advanceScheduled) return;

    // Masih ada URL kandidat lain? Coba URL berikutnya.
    if (_index + 1 < _urls.length) {
      _advanceScheduled = true;
      debugPrint('⚠️ Image load failed, trying next URL (${_index + 1}/${_urls.length})');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _advanceScheduled = false;
        if (!mounted) return;
        if (_index + 1 < _urls.length) {
          setState(() => _index++);
        }
      });
      return;
    }

    // Semua URL gagal — coba byte-fetch manual sebagai fallback terakhir.
    if (!_fallbackLoading && _fallbackBytes == null && _urls.isNotEmpty) {
      _tryFallbackByteFetch();
    }
  }

  /// Fetch gambar via HTTP dengan headers yang tepat agar tidak diblokir oleh
  /// Google Drive / lh3. Berguna saat Image.network mendapat EncodingError
  /// (server mengembalikan HTML bukan gambar).
  Future<void> _tryFallbackByteFetch() async {
    _fallbackLoading = true;
    final url = _urls.first;
    debugPrint('🔄 Fallback: byte-fetch dari $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          debugPrint('✅ Fallback byte-fetch berhasil (${response.bodyBytes.length} bytes)');
          setState(() => _fallbackBytes = response.bodyBytes);
          return;
        } else {
          debugPrint('⚠️ Fallback: content-type bukan image ($contentType)');
        }
      } else {
        debugPrint('⚠️ Fallback: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Fallback byte-fetch gagal: $e');
    }

    if (mounted) setState(() => _fallbackLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty) {
      return _wrap(_placeholder());
    }

    // Fallback: tampilkan gambar dari byte-fetch jika tersedia.
    if (_fallbackBytes != null) {
      return _wrap(Image.memory(
        _fallbackBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ));
    }

    return _wrap(_TimedNetworkImage(
      url: _urls[_index],
      imageKey: ValueKey('${_urls[_index]}-$_index'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      onTimeoutOrError: _scheduleNextDriveUrl,
      loadingBuilder: _loadingBox,
      placeholderBuilder: _placeholder,
    ));
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

class _TimedNetworkImage extends StatefulWidget {
  final String url;
  final Key imageKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback onTimeoutOrError;
  final Widget Function() loadingBuilder;
  final Widget Function() placeholderBuilder;

  const _TimedNetworkImage({
    required this.url,
    required this.imageKey,
    required this.width,
    required this.height,
    required this.fit,
    required this.onTimeoutOrError,
    required this.loadingBuilder,
    required this.placeholderBuilder,
  });

  @override
  State<_TimedNetworkImage> createState() => _TimedNetworkImageState();
}

class _TimedNetworkImageState extends State<_TimedNetworkImage> {
  Timer? _timer;
  bool _timedOut = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _TimedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _timer?.cancel();
      _timedOut = false;
      _hasCompleted = false;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _hasCompleted) return;
      setState(() => _timedOut = true);
      widget.onTimeoutOrError();
    });
  }

  void _markCompleted() {
    _hasCompleted = true;
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) return widget.placeholderBuilder();

    return Image.network(
      widget.url,
      key: widget.imageKey,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // Web: pakai <img> agar gambar Google Drive tidak diblokir CORS (CanvasKit fetch).
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image error: $error');
        _markCompleted();
        widget.onTimeoutOrError();
        return widget.loadingBuilder();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          debugPrint('✅ Image loaded successfully: ${widget.url}');
          _markCompleted();
          return child;
        }
        return widget.loadingBuilder();
      },
    );
  }
}
