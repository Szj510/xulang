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
    this.compact = false,
  });

  final GalleryPlacement placement;
  final GalleryMedia? media;
  final double depth;
  final bool useOriginals;
  final GalleryTheme sceneTheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (placement.frame == GalleryFrame.orb) {
      return _OrbFrame(
        depth: depth,
        sceneTheme: sceneTheme,
        compact: compact,
        child: _image(context),
      );
    }
    final frameWeight = compact ? .72 : 1.0;
    final frame = DecoratedBox(
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
          padding: EdgeInsets.all(compact ? 1.5 : 2),
          child: _image(context),
        ),
        GalleryFrame.mat => _SimpleFrame(
          key: const Key('frame-mat'),
          borderWidth: compact ? .68 : .8,
          borderColor: XulangColors.ink.withValues(alpha: .16),
          color: const Color(0xFFF0E8D9),
          padding: compact
              ? const EdgeInsets.fromLTRB(3.5, 3.5, 3.5, 6)
              : const EdgeInsets.fromLTRB(11, 11, 11, 24),
          child: _image(context),
        ),
        GalleryFrame.stamp => KeyedSubtree(
          key: const Key('frame-stamp'),
          child: CustomPaint(
            key: const Key('stamp-edge-painter'),
            painter: _StampEdgePainter(
              color: const Color(0xFFECE2CF),
              weight: frameWeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 4 : 11),
              child: _image(context),
            ),
          ),
        ),
        GalleryFrame.wood => _TexturedFrame(
          key: const Key('frame-wood'),
          painterKey: const Key('wood-grain-painter'),
          painter: _WoodGrainPainter(
            base: const Color(0xFF9B6538),
            vein: const Color(0xFF5C351D),
            highlight: const Color(0xFFC08A54),
            weight: frameWeight,
          ),
          padding: EdgeInsets.all(compact ? 3.5 : 8),
          child: _image(context),
        ),
        GalleryFrame.darkWood => _TexturedFrame(
          key: const Key('frame-darkWood'),
          painterKey: const Key('dark-wood-grain-painter'),
          painter: _WoodGrainPainter(
            base: const Color(0xFF3B2518),
            vein: const Color(0xFF120906),
            highlight: const Color(0xFF6C4228),
            weight: frameWeight,
          ),
          padding: EdgeInsets.all(compact ? 3.5 : 7),
          child: _image(context),
        ),
        GalleryFrame.metal => _TexturedFrame(
          key: const Key('frame-metal'),
          painterKey: const Key('metal-texture-painter'),
          painter: _MetalTexturePainter(weight: frameWeight),
          padding: EdgeInsets.all(compact ? 2.5 : 5),
          child: _image(context),
        ),
        GalleryFrame.vintage => _TexturedFrame(
          key: const Key('frame-vintage'),
          painterKey: const Key('vintage-paper-painter'),
          painter: _VintagePaperPainter(weight: frameWeight),
          padding: compact
              ? const EdgeInsets.fromLTRB(4, 4, 4, 7)
              : const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: _image(context),
        ),
        GalleryFrame.film => KeyedSubtree(
          key: const Key('frame-film'),
          child: CustomPaint(
            key: const Key('film-edge-painter'),
            painter: _FilmEdgePainter(weight: frameWeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 4 : 10,
                vertical: compact ? 5 : 18,
              ),
              child: _image(context),
            ),
          ),
        ),
        GalleryFrame.captionMat => _CaptionMatFrame(
          key: const Key('frame-captionMat'),
          caption: placement.frameCaption,
          compact: compact,
          child: _image(context),
        ),
        GalleryFrame.tapedPaper => _TexturedFrame(
          key: const Key('frame-tapedPaper'),
          painterKey: const Key('taped-paper-frame-painter'),
          painter: _TapedPaperFramePainter(weight: frameWeight),
          foregroundPainter: _TapedPaperTapePainter(
            weight: frameWeight,
            compact: compact,
          ),
          padding: compact
              ? const EdgeInsets.fromLTRB(5, 5, 5, 7)
              : const EdgeInsets.fromLTRB(14, 15, 14, 22),
          child: _image(context),
        ),
        GalleryFrame.crayon => _TexturedFrame(
          key: const Key('frame-crayon'),
          painterKey: const Key('crayon-frame-painter'),
          painter: _CrayonFramePainter(weight: frameWeight),
          padding: EdgeInsets.all(compact ? 5.5 : 14),
          child: _image(context),
        ),
        GalleryFrame.watercolor => _TexturedFrame(
          key: const Key('frame-watercolor'),
          painterKey: const Key('watercolor-frame-painter'),
          painter: _WatercolorFramePainter(weight: frameWeight),
          padding: EdgeInsets.all(compact ? 6 : 16),
          child: _image(context),
        ),
        GalleryFrame.doodleTape => _TexturedFrame(
          key: const Key('frame-doodleTape'),
          painterKey: const Key('doodle-tape-frame-painter'),
          foregroundPainter: _DoodleTapeFramePainter(weight: frameWeight),
          padding: EdgeInsets.all(compact ? 6 : 17),
          child: _image(context),
        ),
        GalleryFrame.scallop => _TexturedFrame(
          key: const Key('frame-scallop'),
          painterKey: const Key('scallop-frame-painter'),
          foregroundPainter: _ScallopFramePainter(
            color: _handDrawnInk,
            weight: compact ? .82 : 1,
          ),
          padding: EdgeInsets.all(compact ? 6 : 14),
          child: _image(context),
        ),
        GalleryFrame.cornerSketch => _TexturedFrame(
          key: const Key('frame-cornerSketch'),
          painterKey: const Key('corner-sketch-frame-painter'),
          foregroundPainter: _CornerSketchFramePainter(
            color: _handDrawnInk,
            weight: compact ? .95 : 1,
          ),
          padding: EdgeInsets.all(compact ? 5 : 11),
          child: _image(context),
        ),
        GalleryFrame.wavy => _TexturedFrame(
          key: const Key('frame-wavy'),
          painterKey: const Key('wavy-frame-painter'),
          foregroundPainter: _WavyFramePainter(
            color: _handDrawnInk,
            weight: compact ? .82 : 1,
          ),
          padding: EdgeInsets.all(compact ? 5 : 12),
          child: _image(context),
        ),
        GalleryFrame.orb => throw StateError('Orb frame handled above'),
      },
    );
    if (placement.rotation == 0) return frame;
    return Transform.rotate(
      angle: placement.rotation * math.pi / 180.0,
      child: frame,
    );
  }

  Color get _edgeColor => sceneTheme == GalleryTheme.paper
      ? XulangColors.ink.withValues(alpha: .25)
      : XulangColors.paper.withValues(alpha: .16);

  Color get _handDrawnInk => switch (sceneTheme) {
    GalleryTheme.paper ||
    GalleryTheme.warm ||
    GalleryTheme.botanical ||
    GalleryTheme.terracotta => const Color(0xFF282420),
    _ => const Color(0xFFEDE3D2),
  };

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

class _CaptionMatFrame extends StatelessWidget {
  const _CaptionMatFrame({
    super.key,
    required this.caption,
    required this.compact,
    required this.child,
  });

  final String caption;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const Key('caption-mat-frame-painter'),
      painter: const _CaptionMatFramePainter(),
      foregroundPainter: _CaptionMatTapePainter(compact: compact),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final useCompact = compact;
          final horizontalPadding = useCompact
              ? (width * .045).clamp(2.5, 6.0)
              : 10.0;
          final topPadding = useCompact
              ? (height * .055).clamp(2.5, 6.0)
              : 11.0;
          final bottomPadding = useCompact
              ? (height * .04).clamp(2.0, 5.0)
              : 9.0;
          final captionHeight = useCompact
              ? (height * .18).clamp(10.0, 28.0)
              : (height * .22).clamp(25.0, 58.0);
          final fontSize = useCompact
              ? (captionHeight * .48).clamp(7.5, 14.0)
              : (captionHeight * .42).clamp(11.0, 21.0);
          final innerBorderWidth = useCompact
              ? (math.min(width, height) * .012).clamp(.4, .7)
              : .8;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    key: const Key('caption-mat-photo-region'),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF615746).withValues(alpha: .22),
                        width: innerBorderWidth,
                      ),
                    ),
                    child: child,
                  ),
                ),
                SizedBox(
                  height: captionHeight,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: useCompact ? 2 : 5,
                      ),
                      child: Text(
                        caption.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF4B3928),
                          fontFamily: 'Xulang Handwriting',
                          fontFamilyFallback: const [
                            'Noto Serif SC',
                            'STKaiti',
                            'serif',
                          ],
                          fontSize: fontSize,
                          height: 1.12,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CaptionMatFramePainter extends CustomPainter {
  const _CaptionMatFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final paper = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));
    final strokeWidth = (math.min(size.width, size.height) * .012).clamp(
      .35,
      .8,
    );
    canvas.drawRRect(paper, Paint()..color = const Color(0xFFF3EBDD));
    canvas.drawRRect(
      paper.deflate(strokeWidth),
      Paint()
        ..color = const Color(0xFF776B5A).withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    final fiber = Paint()
      ..color = const Color(0xFF9C8464).withValues(alpha: .10)
      ..strokeWidth = .45;
    for (var y = 7.0; y < size.height; y += 11) {
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y + .7), fiber);
    }
  }

  @override
  bool shouldRepaint(covariant _CaptionMatFramePainter oldDelegate) => false;
}

class _CaptionMatTapePainter extends CustomPainter {
  const _CaptionMatTapePainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _drawTape(
      canvas,
      Offset(math.min(size.width * .18, 31), compact ? 5 : 10),
      math.min(48, size.width * .34),
      (size.height * .08).clamp(4.0, 13.0),
      -.16,
    );
  }

  @override
  bool shouldRepaint(covariant _CaptionMatTapePainter oldDelegate) =>
      compact != oldDelegate.compact;
}

class _OrbFrame extends StatelessWidget {
  const _OrbFrame({
    required this.depth,
    required this.sceneTheme,
    required this.compact,
    required this.child,
  });

  final double depth;
  final GalleryTheme sceneTheme;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light =
        sceneTheme == GalleryTheme.paper ||
        sceneTheme == GalleryTheme.warm ||
        sceneTheme == GalleryTheme.botanical ||
        sceneTheme == GalleryTheme.terracotta;
    final edge = light
        ? const Color(0xFF6E6253).withValues(alpha: .62)
        : const Color(0xFFF1E6D2).withValues(alpha: .72);
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          key: const Key('frame-orb'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: light ? const Color(0xFFE7DCC8) : const Color(0xFF171A19),
            border: Border.all(color: edge, width: compact ? 1.1 : 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28 + depth * .30),
                blurRadius: 18 + depth * 22,
                spreadRadius: depth * 1.5,
                offset: Offset(0, 8 + depth * 9),
              ),
              BoxShadow(
                color: edge.withValues(alpha: .18 + depth * .16),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 2.2 : 3),
            child: ClipOval(child: child),
          ),
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
    this.painter,
    this.foregroundPainter,
    required this.padding,
    required this.child,
  }) : assert(painter != null || foregroundPainter != null);

  final Key painterKey;
  final CustomPainter? painter;
  final CustomPainter? foregroundPainter;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: painterKey,
      painter: painter,
      foregroundPainter: foregroundPainter,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StampEdgePainter extends CustomPainter {
  const _StampEdgePainter({required this.color, this.weight = 1});

  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final holePaint = Paint()..blendMode = BlendMode.clear;
    final radius = 2.3 * weight;
    final spacing = 8.0 * (.75 + weight * .25);
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
      color != oldDelegate.color || weight != oldDelegate.weight;
}

class _FilmEdgePainter extends CustomPainter {
  const _FilmEdgePainter({this.weight = 1});

  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final holePaint = Paint()..color = const Color(0xFFECE2CF);
    final hole = Size(6 * weight, 8 * weight);
    final edge = 5.0 * weight;
    final spacing = 16.0 * (.7 + weight * .3);
    for (var x = 8.0; x < size.width - 8; x += spacing) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, edge, hole.width, hole.height),
          Radius.circular(1.5 * weight),
        ),
        holePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            size.height - edge - hole.height,
            hole.width,
            hole.height,
          ),
          Radius.circular(1.5 * weight),
        ),
        holePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FilmEdgePainter oldDelegate) =>
      weight != oldDelegate.weight;
}

class _TapedPaperFramePainter extends CustomPainter {
  const _TapedPaperFramePainter({this.weight = 1});

  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paper = _roughRectPath(size, inset: 2.5, amplitude: 1.4, phase: .8);
    canvas.drawPath(paper, Paint()..color = const Color(0xFFF2E9D8));
    canvas.drawPath(
      paper,
      Paint()
        ..color = const Color(0xFF49443C).withValues(alpha: .64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * weight,
    );
    final mark = Paint()
      ..color = const Color(0xFF5B554B).withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85 * weight
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(7, 28), const Offset(9, 38), mark);
    canvas.drawLine(
      Offset(size.width - 8, size.height * .35),
      Offset(size.width - 10, size.height * .48),
      mark,
    );
  }

  @override
  bool shouldRepaint(covariant _TapedPaperFramePainter oldDelegate) =>
      weight != oldDelegate.weight;
}

class _TapedPaperTapePainter extends CustomPainter {
  const _TapedPaperTapePainter({required this.weight, required this.compact});

  final double weight;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final top = compact ? 5.0 : 15.0;
    final bottom = size.height - (compact ? 7.0 : 22.0);
    _drawTape(
      canvas,
      Offset(size.width * .50, top),
      42 * weight,
      11 * weight,
      -.03,
    );
    _drawTape(
      canvas,
      Offset(size.width * .18, bottom),
      46 * weight,
      12 * weight,
      .16,
    );
    _drawTape(
      canvas,
      Offset(size.width * .82, bottom),
      46 * weight,
      12 * weight,
      -.18,
    );
  }

  @override
  bool shouldRepaint(covariant _TapedPaperTapePainter oldDelegate) =>
      weight != oldDelegate.weight || compact != oldDelegate.compact;
}

class _CrayonFramePainter extends CustomPainter {
  const _CrayonFramePainter({this.weight = 1});

  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final sides = <(Offset, Offset, Color)>[
      (const Offset(5, 7), Offset(size.width - 5, 5), const Color(0xFFE25F54)),
      (
        Offset(size.width - 6, 5),
        Offset(size.width - 5, size.height - 6),
        const Color(0xFFF0B43C),
      ),
      (
        Offset(size.width - 5, size.height - 6),
        Offset(5, size.height - 5),
        const Color(0xFF4F98B8),
      ),
      (Offset(6, size.height - 5), const Offset(5, 7), const Color(0xFF6FA267)),
    ];
    for (var side = 0; side < sides.length; side++) {
      final (start, end, color) = sides[side];
      for (var pass = 0; pass < 4; pass++) {
        canvas.drawPath(
          _roughLinePath(
            start,
            end,
            amplitude: 2.5 + pass * .35,
            phase: side * 1.8 + pass * 1.13,
          ),
          Paint()
            ..color = color.withValues(alpha: .34 + pass * .08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (7.8 - pass * 1.25) * weight
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrayonFramePainter oldDelegate) =>
      weight != oldDelegate.weight;
}

class _WatercolorFramePainter extends CustomPainter {
  const _WatercolorFramePainter({this.weight = 1});

  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const washes = [
      (Color(0xFF668DA4), 5.8, .2),
      (Color(0xFFD27D72), 7.8, 1.9),
      (Color(0xFFE0B15B), 9.5, 3.6),
    ];
    for (final wash in washes) {
      canvas.drawPath(
        _roughRectPath(size, inset: wash.$2, amplitude: 4.8, phase: wash.$3),
        Paint()
          ..color = wash.$1.withValues(alpha: .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.5 * weight
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
    }
    final blooms = <(Offset, Color, double)>[
      (Offset(size.width * .12, 7), const Color(0xFF557F9B), 6.5),
      (Offset(size.width * .78, 7), const Color(0xFFD56E6C), 7.5),
      (Offset(size.width - 7, size.height * .36), const Color(0xFFDF9E4B), 6.8),
      (Offset(size.width * .64, size.height - 7), const Color(0xFF738E72), 7.2),
      (Offset(7, size.height * .72), const Color(0xFF8A76A1), 6.6),
    ];
    for (final bloom in blooms) {
      canvas.drawCircle(
        bloom.$1,
        bloom.$3 * weight,
        Paint()
          ..color = bloom.$2.withValues(alpha: .22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WatercolorFramePainter oldDelegate) =>
      weight != oldDelegate.weight;
}

class _DoodleTapeFramePainter extends CustomPainter {
  const _DoodleTapeFramePainter({this.weight = 1});

  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final band = Path.combine(
      PathOperation.difference,
      _roughRectPath(size, inset: 1.5, amplitude: 3.2, phase: .4),
      _roughRectPath(size, inset: 13.0, amplitude: 2.4, phase: 2.7),
    );
    canvas.drawPath(band, Paint()..color = const Color(0xFFF1DFBC));
    for (final stroke in const [
      (3.0, .3, Color(0xFF345D68)),
      (7.2, 2.1, Color(0xFFC75955)),
      (11.5, 4.0, Color(0xFF5C754B)),
    ]) {
      canvas.drawPath(
        _roughRectPath(
          size,
          inset: stroke.$1,
          amplitude: 2.5,
          phase: stroke.$2,
        ),
        Paint()
          ..color = stroke.$3.withValues(alpha: .78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7 * weight
          ..strokeCap = StrokeCap.round,
      );
    }
    final doodle = Paint()
      ..color = const Color(0xFF3C3630).withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15 * weight
      ..strokeCap = StrokeCap.round;
    for (var x = 20.0; x < size.width - 14; x += 25) {
      canvas.drawCircle(Offset(x, 7), 2.2 + (x.toInt() % 3), doodle);
    }
    for (var y = 22.0; y < size.height - 14; y += 29) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width - 7, y), radius: 3.5),
        -.7,
        math.pi * 1.45,
        false,
        doodle,
      );
    }
    canvas.drawPath(
      _smallDoodleStar(Offset(8, size.height - 8), 5.2),
      Paint()
        ..color = const Color(0xFFCA8650)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * weight
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleTapeFramePainter oldDelegate) =>
      weight != oldDelegate.weight;
}

class _ScallopFramePainter extends CustomPainter {
  const _ScallopFramePainter({required this.color, this.weight = 1});

  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ink = Paint()
      ..color = color.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65 * weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_scallopRectPath(size, inset: 8, lobe: 6.2), ink);
    canvas.drawPath(
      _scallopRectPath(size, inset: 9.6, lobe: 5.7),
      ink
        ..color = color.withValues(alpha: .30)
        ..strokeWidth = .85 * weight,
    );
  }

  @override
  bool shouldRepaint(covariant _ScallopFramePainter oldDelegate) =>
      color != oldDelegate.color || weight != oldDelegate.weight;
}

class _CornerSketchFramePainter extends CustomPainter {
  const _CornerSketchFramePainter({required this.color, this.weight = 1});

  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const inset = 4.5;
    final length = math.min(18.0, math.min(size.width, size.height) * .22);
    final segments = <(Offset, Offset)>[
      (Offset(inset, inset + length), const Offset(inset, inset)),
      (const Offset(inset, inset), Offset(inset + length, inset)),
      (
        Offset(size.width - inset - length, inset),
        Offset(size.width - inset, inset),
      ),
      (
        Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + length),
      ),
      (
        Offset(size.width - inset, size.height - inset - length),
        Offset(size.width - inset, size.height - inset),
      ),
      (
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset - length, size.height - inset),
      ),
      (
        Offset(inset + length, size.height - inset),
        Offset(inset, size.height - inset),
      ),
      (
        Offset(inset, size.height - inset),
        Offset(inset, size.height - inset - length),
      ),
    ];
    for (var pass = 0; pass < 2; pass++) {
      for (var index = 0; index < segments.length; index++) {
        final path = _roughLinePath(
          segments[index].$1,
          segments[index].$2,
          amplitude: 1.1 + pass * .35,
          phase: index * .73 + pass * 2.2,
        );
        if (pass == 0) {
          final contrast = color.computeLuminance() > .5
              ? Colors.black
              : Colors.white;
          canvas.drawPath(
            path,
            Paint()
              ..color = contrast.withValues(alpha: .34)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.2 * weight
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: pass == 0 ? .80 : .32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (pass == 0 ? 1.8 : .85) * weight
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CornerSketchFramePainter oldDelegate) =>
      color != oldDelegate.color || weight != oldDelegate.weight;
}

class _WavyFramePainter extends CustomPainter {
  const _WavyFramePainter({required this.color, this.weight = 1});

  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ink = Paint()
      ..color = color.withValues(alpha: .84)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      _roughRectPath(size, inset: 7, amplitude: 3.3, phase: 1.4),
      ink,
    );
    for (final corner in [
      const Offset(7, 7),
      Offset(size.width - 7, 7),
      Offset(size.width - 7, size.height - 7),
      Offset(7, size.height - 7),
    ]) {
      canvas.drawCircle(corner, 2.7 * weight, Paint()..color = ink.color);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyFramePainter oldDelegate) =>
      color != oldDelegate.color || weight != oldDelegate.weight;
}

Path _roughLinePath(
  Offset start,
  Offset end, {
  required double amplitude,
  required double phase,
}) {
  final delta = end - start;
  final length = delta.distance;
  if (length == 0) return Path()..moveTo(start.dx, start.dy);
  final normal = Offset(-delta.dy / length, delta.dx / length);
  final path = Path()..moveTo(start.dx, start.dy);
  const segments = 18;
  for (var index = 1; index <= segments; index++) {
    final t = index / segments;
    final taper = math.sin(math.pi * t);
    final jitter = math.sin(index * 1.91 + phase) * amplitude * taper;
    final point = start + delta * t + normal * jitter;
    path.lineTo(point.dx, point.dy);
  }
  return path;
}

void _drawTape(
  Canvas canvas,
  Offset center,
  double width,
  double height,
  double angle,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  final tape = Path()
    ..moveTo(-width / 2, -height / 2)
    ..lineTo(-width / 2 + 2, -height / 2 + 1)
    ..lineTo(-width / 2, -height / 2 + 3)
    ..lineTo(-width / 2 + 1, height / 2)
    ..lineTo(width / 2 - 2, height / 2 - 1)
    ..lineTo(width / 2, height / 2 - 3)
    ..lineTo(width / 2 - 1, -height / 2)
    ..close();
  canvas.drawPath(
    tape,
    Paint()..color = const Color(0xFFD9C49B).withValues(alpha: .92),
  );
  canvas.drawPath(
    tape,
    Paint()
      ..color = const Color(0xFF5B5143).withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85,
  );
  final hatch = Paint()
    ..color = const Color(0xFF7B6A52).withValues(alpha: .34)
    ..strokeWidth = .65;
  for (var x = -width / 2 + 5; x < width / 2; x += 7) {
    canvas.drawLine(
      Offset(x, -height / 2 + 2),
      Offset(x + 3, height / 2 - 2),
      hatch,
    );
  }
  canvas.restore();
}

Path _scallopRectPath(
  Size size, {
  required double inset,
  required double lobe,
}) {
  final path = Path()..moveTo(inset, inset);
  final horizontalCount = math.max(
    3,
    ((size.width - inset * 2) / (lobe * 2)).round(),
  );
  final verticalCount = math.max(
    3,
    ((size.height - inset * 2) / (lobe * 2)).round(),
  );
  final horizontalStep = (size.width - inset * 2) / horizontalCount;
  final verticalStep = (size.height - inset * 2) / verticalCount;
  for (var index = 0; index < horizontalCount; index++) {
    final x = inset + horizontalStep * index;
    path.quadraticBezierTo(
      x + horizontalStep / 2,
      inset - lobe,
      x + horizontalStep,
      inset,
    );
  }
  for (var index = 0; index < verticalCount; index++) {
    final y = inset + verticalStep * index;
    path.quadraticBezierTo(
      size.width - inset + lobe,
      y + verticalStep / 2,
      size.width - inset,
      y + verticalStep,
    );
  }
  for (var index = 0; index < horizontalCount; index++) {
    final x = size.width - inset - horizontalStep * index;
    path.quadraticBezierTo(
      x - horizontalStep / 2,
      size.height - inset + lobe,
      x - horizontalStep,
      size.height - inset,
    );
  }
  for (var index = 0; index < verticalCount; index++) {
    final y = size.height - inset - verticalStep * index;
    path.quadraticBezierTo(
      inset - lobe,
      y - verticalStep / 2,
      inset,
      y - verticalStep,
    );
  }
  return path..close();
}

Path _smallDoodleStar(Offset center, double radius) {
  final path = Path();
  for (var index = 0; index < 10; index++) {
    final angle = -math.pi / 2 + math.pi * index / 5;
    final point =
        center +
        Offset(math.cos(angle), math.sin(angle)) *
            (index.isEven ? radius : radius * .42);
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

Path _roughRectPath(
  Size size, {
  required double inset,
  required double amplitude,
  required double phase,
  int gapEvery = 0,
}) {
  final path = Path();
  final points = <Offset>[];
  const segments = 12;
  for (var side = 0; side < 4; side++) {
    for (var step = 0; step <= segments; step++) {
      if (side > 0 && step == 0) continue;
      final t = step / segments;
      final wave =
          math.sin((step + side * segments) * 1.73 + phase) * amplitude;
      final point = switch (side) {
        0 => Offset(inset + (size.width - inset * 2) * t, inset + wave),
        1 => Offset(
          size.width - inset + wave,
          inset + (size.height - inset * 2) * t,
        ),
        2 => Offset(
          size.width - inset - (size.width - inset * 2) * t,
          size.height - inset + wave,
        ),
        _ => Offset(
          inset + wave,
          size.height - inset - (size.height - inset * 2) * t,
        ),
      };
      points.add(point);
    }
  }
  for (var index = 0; index < points.length; index++) {
    final point = points[index];
    if (index == 0 || (gapEvery > 0 && index % gapEvery == 0)) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  if (gapEvery == 0) path.close();
  return path;
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter({
    required this.base,
    required this.vein,
    required this.highlight,
    this.weight = 1,
  });

  final Color base;
  final Color vein;
  final Color highlight;
  final double weight;

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
      ..strokeWidth = 1.1 * weight;
    final glowPaint = Paint()
      ..color = highlight.withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8 * weight;
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
      ..strokeWidth = 5 * weight
      ..color = Colors.black.withValues(alpha: .20);
    canvas.drawRect(rect.deflate(2.5), bevel);
    canvas.drawRect(
      rect.deflate(6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * weight
        ..color = Colors.white.withValues(alpha: .18),
    );
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter oldDelegate) =>
      base != oldDelegate.base ||
      vein != oldDelegate.vein ||
      highlight != oldDelegate.highlight ||
      weight != oldDelegate.weight;
}

class _MetalTexturePainter extends CustomPainter {
  const _MetalTexturePainter({this.weight = 1});

  final double weight;

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
      ..strokeWidth = .7 * weight;
    final darkScratch = Paint()
      ..color = Colors.black.withValues(alpha: .18)
      ..strokeWidth = .6 * weight;
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
        ..strokeWidth = 3 * weight
        ..color = Colors.black.withValues(alpha: .24),
    );
  }

  @override
  bool shouldRepaint(covariant _MetalTexturePainter oldDelegate) =>
      weight != oldDelegate.weight;
}

class _VintagePaperPainter extends CustomPainter {
  const _VintagePaperPainter({this.weight = 1});

  final double weight;

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
        ..strokeWidth = 2 * weight
        ..color = const Color(0xFF6E522C).withValues(alpha: .42),
    );
    canvas.drawRect(
      rect.deflate(10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * weight
        ..color = Colors.white.withValues(alpha: .22),
    );
  }

  @override
  bool shouldRepaint(covariant _VintagePaperPainter oldDelegate) =>
      weight != oldDelegate.weight;
}
