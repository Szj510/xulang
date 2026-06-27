import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xulang/domain/gallery_document.dart';

class AtmosphericSticker extends StatelessWidget {
  const AtmosphericSticker({
    super.key,
    required this.kind,
    this.size = 42,
    this.rotation = 0,
    this.opacity = 1,
  });

  final GalleryStickerKind kind;
  final double size;
  final double rotation;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size.square(size),
        painter: AtmosphericStickerPainter(kind: kind, opacity: opacity),
      ),
    );
  }
}

class AtmosphericStickerPainter extends CustomPainter {
  const AtmosphericStickerPainter({required this.kind, this.opacity = 1});

  final GalleryStickerKind kind;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final alpha = opacity.clamp(0, 1).toDouble();
    canvas.saveLayer(Offset.zero & size, Paint());
    switch (kind) {
      case GalleryStickerKind.star:
        _paintStar(canvas, size, alpha);
      case GalleryStickerKind.sparkle:
        _paintSparkle(canvas, size, alpha);
      case GalleryStickerKind.heart:
        _paintHeart(canvas, size, alpha);
      case GalleryStickerKind.leaf:
        _paintLeaf(canvas, size, alpha);
      case GalleryStickerKind.flower:
        _paintFlower(canvas, size, alpha);
      case GalleryStickerKind.crescentMoon:
        _paintCrescentMoon(canvas, size, alpha);
      case GalleryStickerKind.firefly:
        _paintFirefly(canvas, size, alpha);
      case GalleryStickerKind.comet:
        _paintComet(canvas, size, alpha);
      case GalleryStickerKind.pressedPetal:
        _paintPressedPetal(canvas, size, alpha);
      case GalleryStickerKind.paperTape:
        _paintPaperTape(canvas, size, alpha);
      case GalleryStickerKind.fogRibbon:
        _paintFogRibbon(canvas, size, alpha);
      case GalleryStickerKind.waxSeal:
        _paintWaxSeal(canvas, size, alpha);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AtmosphericStickerPainter oldDelegate) =>
      kind != oldDelegate.kind || opacity != oldDelegate.opacity;
}

void _paintSoftShadow(Canvas canvas, Size size, double alpha) {
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(size.width * .52, size.height * .62),
      width: size.width * .72,
      height: size.height * .18,
    ),
    Paint()
      ..color = Colors.black.withValues(alpha: .24 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
}

void _paintStar(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final center = Offset(size.width / 2, size.height / 2);
  final outer = size.shortestSide * .42;
  final inner = outer * .38;
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? outer : inner;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(
    path,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF3B0), Color(0xFFC9A87C)],
      ).createShader(Offset.zero & size),
  );
  canvas.drawCircle(
    center,
    outer * .92,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFFFFF6D6).withValues(alpha: .42 * alpha),
  );
}

void _paintSparkle(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = size.shortestSide * .045
    ..color = const Color(0xFFE9D7FF).withValues(alpha: .88 * alpha);
  void glint(Offset center, double radius) {
    canvas.drawLine(
      center - Offset(radius, 0),
      center + Offset(radius, 0),
      paint,
    );
    canvas.drawLine(
      center - Offset(0, radius),
      center + Offset(0, radius),
      paint,
    );
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xFFBEEBFF).withValues(alpha: .36 * alpha),
    );
  }

  glint(Offset(size.width * .44, size.height * .42), size.shortestSide * .22);
  glint(Offset(size.width * .72, size.height * .28), size.shortestSide * .10);
  glint(Offset(size.width * .25, size.height * .68), size.shortestSide * .12);
}

void _paintHeart(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final path = Path();
  final w = size.width;
  final h = size.height;
  path.moveTo(w * .50, h * .78);
  path.cubicTo(w * .12, h * .50, w * .18, h * .18, w * .42, h * .30);
  path.cubicTo(w * .50, h * .08, w * .88, h * .17, w * .77, h * .49);
  path.cubicTo(w * .72, h * .62, w * .62, h * .70, w * .50, h * .78);
  canvas.drawPath(
    path,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEFB7A7), Color(0xFFB85C5C)],
      ).createShader(Offset.zero & size),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFE6D5).withValues(alpha: .42 * alpha),
  );
}

void _paintLeaf(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final stem = Paint()
    ..color = const Color(0xFFB7C59A).withValues(alpha: .85 * alpha)
    ..strokeWidth = size.shortestSide * .035
    ..strokeCap = StrokeCap.round;
  final p0 = Offset(size.width * .26, size.height * .78);
  final p1 = Offset(size.width * .64, size.height * .22);
  canvas.drawLine(p0, p1, stem);
  for (final t in [.28, .48, .66]) {
    final center = Offset.lerp(p0, p1, t)!;
    final side = t == .48 ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx + side * size.width * .20,
        center.dy - size.height * .12,
        center.dx + side * size.width * .26,
        center.dy + size.height * .03,
      )
      ..quadraticBezierTo(
        center.dx + side * size.width * .12,
        center.dy + size.height * .10,
        center.dx,
        center.dy,
      );
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF758C63).withValues(alpha: .88 * alpha),
    );
  }
}

void _paintFlower(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final center = Offset(size.width * .50, size.height * .46);
  for (var i = 0; i < 6; i++) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(i * math.pi / 3);
    final petal = Rect.fromCenter(
      center: Offset(0, -size.height * .18),
      width: size.width * .18,
      height: size.height * .34,
    );
    canvas.drawOval(
      petal,
      Paint()..color = const Color(0xFFE2B8A7).withValues(alpha: .84 * alpha),
    );
    canvas.restore();
  }
  canvas.drawCircle(
    center,
    size.shortestSide * .11,
    Paint()..color = const Color(0xFFC9A87C).withValues(alpha: alpha),
  );
}

void _paintCrescentMoon(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final moon = Paint()
    ..color = const Color(0xFFE8DFCE).withValues(alpha: .95 * alpha)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .4);
  final center = Offset(size.width * .50, size.height * .48);
  canvas.drawCircle(center, size.shortestSide * .32, moon);
  canvas.drawCircle(
    center + Offset(size.width * .14, -size.height * .06),
    size.shortestSide * .31,
    Paint()..color = const Color(0xFF17202C).withValues(alpha: alpha),
  );
  canvas.drawCircle(
    center,
    size.shortestSide * .39,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE8DFCE).withValues(alpha: .24 * alpha),
  );
}

void _paintFirefly(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final center = Offset(size.width * .52, size.height * .48);
  canvas.drawCircle(
    center,
    size.shortestSide * .30,
    Paint()
      ..color = const Color(0xFFFFEFA8).withValues(alpha: .26 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  final wingPaint = Paint()
    ..color = const Color(0xFFE8DFCE).withValues(alpha: .42 * alpha);
  canvas.drawOval(
    Rect.fromCenter(
      center: center + Offset(-size.width * .13, -size.height * .06),
      width: size.width * .22,
      height: size.height * .14,
    ),
    wingPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: center + Offset(size.width * .13, -size.height * .06),
      width: size.width * .22,
      height: size.height * .14,
    ),
    wingPaint,
  );
  canvas.drawCircle(
    center,
    size.shortestSide * .10,
    Paint()..color = const Color(0xFFFFD66B).withValues(alpha: alpha),
  );
}

void _paintComet(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final tail = Path()
    ..moveTo(size.width * .12, size.height * .64)
    ..cubicTo(
      size.width * .34,
      size.height * .42,
      size.width * .52,
      size.height * .32,
      size.width * .78,
      size.height * .28,
    );
  canvas.drawPath(
    tail,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .10
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFBEEBFF).withValues(alpha: .84 * alpha),
        ],
      ).createShader(Offset.zero & size),
  );
  canvas.drawCircle(
    Offset(size.width * .80, size.height * .27),
    size.shortestSide * .12,
    Paint()..color = const Color(0xFFE8DFCE).withValues(alpha: alpha),
  );
}

void _paintPressedPetal(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final path = Path()
    ..moveTo(size.width * .50, size.height * .16)
    ..cubicTo(
      size.width * .82,
      size.height * .28,
      size.width * .77,
      size.height * .70,
      size.width * .48,
      size.height * .86,
    )
    ..cubicTo(
      size.width * .18,
      size.height * .62,
      size.width * .25,
      size.height * .30,
      size.width * .50,
      size.height * .16,
    );
  canvas.drawPath(
    path,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEBC5B8), Color(0xFF936E6E)],
      ).createShader(Offset.zero & size),
  );
  canvas.drawLine(
    Offset(size.width * .49, size.height * .23),
    Offset(size.width * .49, size.height * .78),
    Paint()
      ..strokeWidth = .8
      ..color = Colors.white.withValues(alpha: .28 * alpha),
  );
}

void _paintPaperTape(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final rect = Rect.fromCenter(
    center: Offset(size.width * .50, size.height * .50),
    width: size.width * .78,
    height: size.height * .30,
  );
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(size.width * .04),
  );
  canvas.drawRRect(
    rrect,
    Paint()..color = const Color(0xFFE8DFCE).withValues(alpha: .72 * alpha),
  );
  for (var i = 0; i < 5; i++) {
    final x = rect.left + rect.width * (i + .5) / 5;
    canvas.drawLine(
      Offset(x, rect.top + 3),
      Offset(x - size.width * .05, rect.bottom - 3),
      Paint()
        ..strokeWidth = .8
        ..color = const Color(0xFFC9A87C).withValues(alpha: .35 * alpha),
    );
  }
}

void _paintFogRibbon(Canvas canvas, Size size, double alpha) {
  final path = Path()
    ..moveTo(size.width * .10, size.height * .56)
    ..cubicTo(
      size.width * .28,
      size.height * .20,
      size.width * .55,
      size.height * .86,
      size.width * .90,
      size.height * .42,
    );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .16
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFDDE9E7).withValues(alpha: .30 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .035
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE8DFCE).withValues(alpha: .46 * alpha),
  );
}

void _paintWaxSeal(Canvas canvas, Size size, double alpha) {
  _paintSoftShadow(canvas, size, alpha);
  final center = Offset(size.width * .50, size.height * .50);
  final blob = Path();
  for (var i = 0; i < 12; i++) {
    final angle = i * math.pi / 6;
    final radius = size.shortestSide * (.30 + (i.isEven ? .035 : -.015));
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      blob.moveTo(point.dx, point.dy);
    } else {
      blob.lineTo(point.dx, point.dy);
    }
  }
  blob.close();
  canvas.drawPath(
    blob,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFB85C5C), Color(0xFF6F3035)],
      ).createShader(Offset.zero & size),
  );
  canvas.drawCircle(
    center,
    size.shortestSide * .16,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFE8DFCE).withValues(alpha: .34 * alpha),
  );
}
