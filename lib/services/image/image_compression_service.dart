import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:path_provider/path_provider.dart';

/// Compresses an image file for upload. Quality and optional max size
/// are read from config API values stored in [TokenStorage].
class ImageCompressionService {
  ImageCompressionService._();

  static const _defaultQuality = 40;
  static const _minQuality = 10;
  static const _qualityStep = 10;
  static const _defaultMaxWidth = 1024;
  static const _defaultMaxHeight = 1024;

  /// Quality from config (0-100). Default 40 if not set or invalid.
  static Future<int> _qualityFromConfig() async {
    final parsed = await TokenStorage.getImageCompressionQuality();
    if (parsed == null || parsed < 0 || parsed > 100) return _defaultQuality;
    return parsed;
  }

  /// Max size in KB from config. Null if not set or invalid.
  static Future<int?> _maxKbFromConfig() async {
    final parsed = await TokenStorage.getImageCompressionMaxSizeKB();
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// Compresses the image at [sourcePath] and returns the path to the
  /// compressed file (JPEG). If compression fails, returns [sourcePath].
  /// Quality is read from API config persisted in local storage.
  /// If image max size is set, quality is reduced in steps until
  /// the file is under that size (in KB).
  static Future<String> compressImage(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) return sourcePath;

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/park_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    int quality = await _qualityFromConfig();
    final maxBytesKb = await _maxKbFromConfig();
    final maxBytes = maxBytesKb != null ? maxBytesKb * 1024 : null;
    String? lastPath;

    while (true) {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: _defaultMaxWidth,
        minHeight: _defaultMaxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) return sourcePath;

      lastPath = result.path;
      final resultSize = await File(result.path).length();

      final underMax = maxBytes == null || resultSize <= maxBytes;
      if (underMax || quality <= _minQuality) break;

      quality = (quality - _qualityStep).clamp(_minQuality, 100);
    }

    return lastPath;
  }
}
