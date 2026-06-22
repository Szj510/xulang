import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xulang/theme/xulang_theme.dart';

class GalleryImage extends StatelessWidget {
  const GalleryImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.alignment = Alignment.center,
    this.scale = 1,
  });

  final String path;
  final BoxFit fit;
  final int? cacheWidth;
  final Alignment alignment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('asset://')
        ? Image.asset(
            path.substring(8),
            fit: fit,
            alignment: alignment,
            cacheWidth: cacheWidth,
          )
        : Image.file(
            File(path),
            fit: fit,
            alignment: alignment,
            cacheWidth: cacheWidth,
            errorBuilder: (context, error, stackTrace) => const _MissingImage(),
          );
    return Semantics(
      label: '展览图片',
      image: true,
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: alignment,
          child: image,
        ),
      ),
    );
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: XulangColors.elevated,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: XulangColors.muted),
            SizedBox(height: 8),
            Text(
              '图片暂不可用',
              style: TextStyle(color: XulangColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
