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
        GalleryFrame.wood => _TexturedFrame(
          key: const Key('frame-wood'),
          painterKey: const Key('wood-grain-painter'),
          painter: const _WoodGrainPainter(
            base: Color(0xFF9B6538),
            vein: Color(0xFF5C351D),
            highlight: Color(0xFFC08A54),
          ),
          padding: const EdgeInsets.all(8),
          child: _image(context),
        ),
        GalleryFrame.darkWood => _TexturedFrame(
          key: const Key('frame-darkWood'),
          painterKey: const Key('dark-wood-grain-painter'),
          painter: const _WoodGrainPainter(
            base: Color(0xFF3B2518),
            vein: Color(0xFF120906),
            highlight: Color(0xFF6C4228),
          ),
          padding: const EdgeInsets.all(7),
          child: _image(context),
        ),
        GalleryFrame.metal => _TexturedFrame(
          key: const Key('frame-metal'),
          painterKey: const Key('metal-texture-painter'),
          painter: const _MetalTexturePainter(),
          padding: const EdgeInsets.all(5),
          child: _image(context),
        ),
        GalleryFrame.vintage => _TexturedFrame(
          key: const Key('frame-vintage'),
          painterKey: const Key('vintage-paper-painter'),
          painter: const _VintagePaperPainter(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: _image(context),
        ),
        GalleryFrame.film => KeyedSubtree(
          key: const Key('frame-film'),
          child: CustomPaint(
            key: const Key('film-edge-painter'),
            painter: const _FilmEdgePainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
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

class _TexturedFrame extends StatelessWidget {
  const _TexturedFrame({
    super.key,
    required this.painterKey,
    required this.painter,
    required this.padding,
    required this.child,
  });

  final Key painterKey;
  final CustomPainter painter;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: painterKey,
      painter: painter,
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

class _FilmEdgePainter extends CustomPainter {
  const _FilmEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final holePaint = Paint()..color = const Color(0xFFECE2CF);
    const hole = Size(6, 8);
    for (var x = 8.0; x < size.width - 8; x += 16) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 5, hole.width, hole.height),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - 13, hole.width, hole.height),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FilmEdgePainter oldDelegate) => false;
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter({
    required this.base,
    required this.vein,
    required this.highlight,
  });

  final Color base;
  final Color vein;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, base, vein],
          stops: const [0, .48, 1],
        ).createShader(rect),
    );
    final veinPaint = Paint()
      ..color = vein.withValues(alpha: .36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final glowPaint = Paint()
      ..color = highlight.withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var i = -2; i < 13; i++) {
      final y = size.height * (i / 11);
      final path = Path()
        ..moveTo(-8, y)
        ..cubicTo(
          size.width * .22,
          y + math.sin(i * 1.7) * 13,
          size.width * .70,
          y + math.cos(i * 1.3) * 18,
          size.width + 8,
          y + math.sin(i * .9) * 10,
        );
      canvas.drawPath(path, i.isEven ? veinPaint : glowPaint);
    }
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.black.withValues(alpha: .20);
    canvas.drawRect(rect.deflate(2.5), bevel);
    canvas.drawRect(
      rect.deflate(6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .18),
    );
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter oldDelegate) =>
      base != oldDelegate.base ||
      vein != oldDelegate.vein ||
      highlight != oldDelegate.highlight;
}

class _MetalTexturePainter extends CustomPainter {
  const _MetalTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF7D7A73),
            Color(0xFFE2DED3),
            Color(0xFF9B968B),
            Color(0xFFF0ECE0),
          ],
          stops: [0, .28, .62, 1],
        ).createShader(rect),
    );
    final scratch = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..strokeWidth = .7;
    final darkScratch = Paint()
      ..color = Colors.black.withValues(alpha: .18)
      ..strokeWidth = .6;
    for (var i = 0; i < 32; i++) {
      final x = (i * 37) % (size.width + 30) - 15;
      final y = (i * 19) % (size.height + 20) - 10;
      canvas.drawLine(
        Offset(x.toDouble(), y.toDouble()),
        Offset(x + 34, y + 7),
        i.isEven ? scratch : darkScratch,
      );
    }
    canvas.drawRect(
      rect.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withValues(alpha: .24),
    );
  }

  @override
  bool shouldRepaint(covariant _MetalTexturePainter oldDelegate) => false;
}

class _VintagePaperPainter extends CustomPainter {
  const _VintagePaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.18, -.28),
          radius: 1.1,
          colors: [Color(0xFFF1DCAC), Color(0xFFD0AD6F), Color(0xFF816338)],
        ).createShader(rect),
    );
    for (var i = 0; i < 22; i++) {
      final cx = ((i * 53) % math.max(1, size.width.toInt())).toDouble();
      final cy = ((i * 31) % math.max(1, size.height.toInt())).toDouble();
      final radius = 3.0 + (i % 5) * 2.4;
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()..color = const Color(0xFF6F4D26).withValues(alpha: .08),
      );
    }
    canvas.drawRect(
      rect.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF6E522C).withValues(alpha: .42),
    );
    canvas.drawRect(
      rect.deflate(10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .22),
    );
  }

  @override
  bool shouldRepaint(covariant _VintagePaperPainter oldDelegate) => false;
}
