import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/brag_board_service.dart';

/// Displays a brag post image from either URL or base64 data.
class BragImage extends StatelessWidget {
  final BragPost post;
  final double height;
  final double? width;

  const BragImage({
    super.key,
    required this.post,
    this.height = 280,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Try URL first, then base64 data
    if (post.photoUrl != null && post.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Image.network(post.photoUrl!, height: height, width: width ?? double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    if (post.photoData != null && post.photoData!.isNotEmpty) {
      try {
        final bytes = base64Decode(post.photoData!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Image.memory(bytes, height: height, width: width ?? double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback()),
        );
      } catch (_) {}
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      height: height,
      color: Colors.grey.shade900,
      child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.white24)),
    );
  }
}
