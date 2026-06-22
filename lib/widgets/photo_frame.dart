import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/gallery_image.dart';

class PhotoFrame extends StatelessWidget {
  const PhotoFrame({
    super.key,
    required this.placement,
    required this.media,
    required this.depth,
    required this.useOriginals,
    required this.sceneTheme,
  });

  final GalleryPlacement placement;
  final GalleryMedia? media;
  final double depth;
  final bool useOriginals;
  final GalleryTheme sceneTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22 + .26 * depth),
            blurRadius: 16 + 22 * depth,
            offset: Offset(0, 7 + 10 * depth),
          ),
        ],
      ),
      child: switch (placement.frame) {
        GalleryFrame.none => _SimpleFrame(
          key: const Key('frame-none'),
          borderWidth: .7,
          borderColor: _edgeColor,
          padding: EdgeInsets.zero,
          child: _image(context),
        ),
        GalleryFrame.hairline => _SimpleFrame(
          key: const Key('frame-hairline'),
          borderWidth: 1.25,
          borderColor: sceneTheme == GalleryTheme.paper
              ? XulangColors.ink.withValues(alpha: .72)
              : XulangColors.paper.withValues(alpha: .88),
          padding: const EdgeInsets.all(2),
          child: _image(context),
        ),
        GalleryFrame.mat => _SimpleFrame(
          key: const Key('frame-mat'),
          borderWidth: .8,
          borderColor: XulangColors.ink.withValues(alpha: .16),
          color: const Color(0xFFF0E8D9),
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 24),
          child: _image(context),
        ),
        GalleryFrame.stamp => KeyedSubtree(
          key: const Key('frame-stamp'),
          child: CustomPaint(
            key: const Key('stamp-edge-painter'),
            painter: _StampEdgePainter(color: const Color(0xFFECE2CF)),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: _image(context),
            ),
          ),
        ),
      },
    );
  }

  Color get _edgeColor => sceneTheme == GalleryTheme.paper
      ? XulangColors.ink.withValues(alpha: .25)
      : XulangColors.paper.withValues(alpha: .16);

  Widget _image(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: media == null
          ? const ColoredBox(
              color: XulangColors.elevated,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            )
          : GalleryImage(
              path: useOriginals ? media!.originalPath : media!.thumbnailPath,
              alignment: Alignment(
                placement.focalX * 2 - 1,
                placement.focalY * 2 - 1,
              ),
              scale: placement.zoom,
              cacheWidth: math.max(
                320,
                (MediaQuery.sizeOf(context).width * 2).round(),
              ),
            ),
    );
  }
}

class _SimpleFrame extends StatelessWidget {
  const _SimpleFrame({
    super.key,
    required this.borderWidth,
    required this.borderColor,
    required this.padding,
    required this.child,
    this.color = XulangColors.elevated,
  });

  final double borderWidth;
  final Color borderColor;
  final EdgeInsets padding;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StampEdgePainter extends CustomPainter {
  const _StampEdgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final holePaint = Paint()..blendMode = BlendMode.clear;
    const radius = 2.3;
    const spacing = 8.0;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      canvas.drawCircle(Offset(x, 0), radius, holePaint);
      canvas.drawCircle(Offset(x, size.height), radius, holePaint);
    }
    for (var y = spacing / 2; y < size.height; y += spacing) {
      canvas.drawCircle(Offset(0, y), radius, holePaint);
      canvas.drawCircle(Offset(size.width, y), radius, holePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StampEdgePainter oldDelegate) =>
      color != oldDelegate.color;
}
