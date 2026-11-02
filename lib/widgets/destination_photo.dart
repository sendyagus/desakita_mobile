import 'package:flutter/material.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Menampilkan foto destinasi/UMKM dari Firestore; jika belum tersedia
/// atau gagal dimuat (mis. diblokir CORS), pakai aset/placeholder lokal.
class DestinationPhoto extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget Function(BuildContext)? fallbackBuilder;

  const DestinationPhoto({
    super.key,
    this.imageUrl,
    this.fallbackAsset = 'assets/img/cs1.jpg',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.fallbackBuilder,
  });

  /// Normalisasi URL Google Drive menjadi lh3.googleusercontent.com yang
  /// mengirim header CORS, sehingga dapat dimuat di Flutter Web (CanvasKit).
  static String normalizeImageUrl(String url) {
    final driveFile = RegExp(
      r'drive\.google\.com/(?:file/d/|open\?id=|thumbnail\?id=)([\w-]{20,})',
    ).firstMatch(url);
    if (driveFile != null) {
      return 'https://lh3.googleusercontent.com/d/${driveFile.group(1)}=w1200';
    }
    final uc = RegExp(
      r'googleusercontent\.com/(?:d|w)/([\w-]{20,})',
    ).firstMatch(url);
    if (uc != null && !url.contains('=w')) {
      return 'https://lh3.googleusercontent.com/d/${uc.group(1)}=w1200';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final url = normalizeImageUrl(imageUrl?.trim() ?? '');
    Widget fallback() =>
        fallbackBuilder?.call(context) ??
        Image.asset(fallbackAsset, width: width, height: height, fit: fit);

    Widget image;
    if (url.isEmpty) {
      image = fallback();
    } else {
      image = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: DesaKitaColors.mutedGreen,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return ClipRRect(borderRadius: borderRadius, child: image);
  }
}
