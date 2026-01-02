import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Utility functions for handling both Cloudinary URLs and legacy base64 images
class ImageUtils {
  /// Returns appropriate ImageProvider based on whether the data is a URL or base64
  static ImageProvider? getImageProvider(dynamic imageData) {
    if (imageData == null) {
      return null;
    }

    if (imageData is! String) {
      return null;
    }

    final String data = imageData as String;

    // Check if it's a URL (starts with http:// or https://)
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return NetworkImage(data);
    }

    // Otherwise, treat as legacy base64
    try {
      final Uint8List bytes = base64Decode(data);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding image data: $e');
      return null;
    }
  }

  /// Returns decoded bytes for legacy base64 images, null for URLs or errors
  static Uint8List? getImageBytes(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return null;
    }

    // Don't decode URLs
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return null;
    }

    try {
      return base64Decode(imageData);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  /// Check if image data is a Cloudinary URL
  static bool isCloudinaryUrl(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return false;
    }
    return imageData.startsWith('http://') || imageData.startsWith('https://');
  }
}
