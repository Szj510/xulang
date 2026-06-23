import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/motion_resolver.dart';
import 'package:xulang/layout/narrative_track.dart';
import 'package:xulang/layout/narrative_track_resolver.dart';
import 'package:xulang/layout/story_path_geometry.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/photo_frame.dart';

class SceneCanvas extends StatelessWidget {
  const SceneCanvas({
    super.key,
    required this.chapter,
    required this.media,
    this.cameraProgress = 0,
    this.progress = 1,
    this.reduceMotion = false,
    this.showStoryPath = true,
    this.useOriginals = false,
    this.sceneTheme = GalleryTheme.ink,
    this.onPlacementTransformStart,
    this.onPlacementTransformUpdate,
    this.onPlacementTransformEnd,
  });

  final GalleryChapter chapter;
  final List<GalleryMedia> media;
  final double cameraProgress;
  final double progress;
  final bool reduceMotion;
  final bool showStoryPath;
  final bool useOriginals;
  final GalleryTheme sceneTheme;
  final void Function(String placementId)? onPlacementTransformStart;
  final void Function(String placementId, double scaleDelta, Offset delta)?
  onPlacementTransformUpdate;
  final void Function(String placementId)? onPlacementTransformEnd;

  @override
  Widget build(BuildContext context) {
    final mediaById = {for (final item in media) item.id: item};
    final placementsById = {
      for (final placement in chapter.placements) placement.id: placement,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (chapter.placements.isEmpty) {
          return _EmptyScene(sceneTheme: sceneTheme);
        }
        final track = NarrativeTrackResolver.resolve(
          chapter: chapter,
          viewport: viewport,
        );
        final frame = track.resolve(cameraProgress);
        final motion = MotionResolver.resolve(
          motion: chapter.motion,
          progress: progress,
          reduceMotion: reduceMotion,
        );
        final displayedGeometry = transformStoryPathGeometry(
          geometry: frame.path,
          motion: motion,
          viewport: viewport,
        );
        final anchorsByPlacement = {
          for (final anchor in displayedGeometry.anchors)
            anchor.placementId: anchor,
        };
        final nodesByPlacement = {
          for (final node in frame.nodes) node.placementId: node,
        };
        final nodes = [...frame.nodes]
          ..sort((a, b) => a.depth.compareTo(b.depth));
        return ClipRect(
          child: CustomPaint(
            key: const Key('scene-background'),
            painter: SceneBackgroundPainter(
              sceneTheme,
              room: chapter.layout == GalleryLayout.depthWall,
            ),
            child: Stack(
              children: [
                if (showStoryPath &&
                    chapter.layout == GalleryLayout.storyPath &&
                    chapter.pathStyle != StoryPathStyle.none)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        key: const Key('story-path-opacity'),
                        opacity: motion.opacity.clamp(0, 1),
                        child: CustomPaint(
                          key: const Key('story-path-line'),
                          painter: StoryPathPainter(
                            sceneTheme: sceneTheme,
                            geometry: displayedGeometry,
                            style: chapter.pathStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final node in nodes)
                  if (placementsById[node.placementId] case final placement?)
                    _SceneNodeWidget(
                      node: node,
                      placement: placement,
                      media: mediaById[placement.mediaId],
                      motion: motion,
                      viewport: viewport,
                      useOriginals: useOriginals,
                      sceneTheme: sceneTheme,
                      depthWall: chapter.layout == GalleryLayout.depthWall,
                      onTransformStart: onPlacementTransformStart,
                      onTransformUpdate: onPlacementTransformUpdate,
                      onTransformEnd: onPlacementTransformEnd,
                    ),
                if (chapter.layout == GalleryLayout.storyPath)
                  for (
                    var index = 0;
                    index < chapter.placements.length;
                    index++
                  )
                    if (anchorsByPlacement[chapter.placements[index].id]
                        case final anchor?)
                      _StoryNodeLabel(
                        index: index,
                        placement: chapter.placements[index],
                        anchor: anchor,
                        opacity:
                            (nodesByPlacement[anchor.placementId]?.opacity ??
                                0) *
                            motion.opacity,
                        sceneTheme: sceneTheme,
                        viewport: viewport,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SceneNodeWidget extends StatelessWidget {
  const _SceneNodeWidget({
    required this.node,
    required this.placement,
    required this.media,
    required this.motion,
    required this.viewport,
    required this.useOriginals,
    required this.sceneTheme,
    required this.depthWall,
    this.onTransformStart,
    this.onTransformUpdate,
    this.onTransformEnd,
  });

  final NarrativeNodeFrame node;
  final GalleryPlacement placement;
  final GalleryMedia? media;
  final MotionFrame motion;
  final Size viewport;
  final bool useOriginals;
  final GalleryTheme sceneTheme;
  final bool depthWall;
  final void Function(String placementId)? onTransformStart;
  final void Function(String placementId, double scaleDelta, Offset delta)?
  onTransformUpdate;
  final void Function(String placementId)? onTransformEnd;

  @override
  Widget build(BuildContext context) {
    final dx = motion.offset.dx * viewport.width;
    final dy = motion.offset.dy * viewport.height;
    final perspective = depthWall ? .00235 : .00135;
    final zLift = depthWall ? 28.0 : 10.0;
    final yRotation = depthWall ? node.rotateY * 2.2 : node.rotateY;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..translateByDouble(dx, dy, node.depth * zLift, 1)
      ..rotateY(yRotation)
      ..rotateZ(node.rotation + motion.rotation)
      ..scaleByDouble(motion.scale, motion.scale, 1, 1);
    return Positioned.fromRect(
      rect: node.rect,
      child: Opacity(
        opacity: (node.opacity * motion.opacity).clamp(0, 1),
        child: Transform(
          key: Key('scene-node-${placement.id}'),
          alignment: Alignment.center,
          transform: matrix,
          child: GestureDetector(
            key: Key('scene-node-gesture-${placement.id}'),
            behavior: HitTestBehavior.opaque,
            onScaleStart: onTransformUpdate == null
                ? null
                : (_) => onTransformStart?.call(placement.id),
            onScaleUpdate: onTransformUpdate == null
                ? null
                : (details) => onTransformUpdate!(
                    placement.id,
                    details.scale,
                    details.focalPointDelta,
                  ),
            onScaleEnd: onTransformUpdate == null
                ? null
                : (_) => onTransformEnd?.call(placement.id),
            child: PhotoFrame(
              placement: placement,
              media: media,
              depth: node.depth,
              useOriginals: useOriginals,
              sceneTheme: sceneTheme,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryNodeLabel extends StatelessWidget {
  const _StoryNodeLabel({
    required this.index,
    required this.placement,
    required this.anchor,
    required this.opacity,
    required this.sceneTheme,
    required this.viewport,
  });

  final int index;
  final GalleryPlacement placement;
  final StoryPathAnchor anchor;
  final double opacity;
  final GalleryTheme sceneTheme;
  final Size viewport;

  @override
  Widget build(BuildContext context) {
    final foreground = sceneTheme == GalleryTheme.paper
        ? XulangColors.ink
        : XulangColors.paper;
    final rect = resolveStoryLabelRect(anchor: anchor, viewport: viewport);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Opacity(
          key: Key('story-label-opacity-${placement.id}'),
          opacity: (opacity * .82).clamp(0, 1),
          child: Text(
            '${(index + 1).toString().padLeft(2, '0')}  '
            '${placement.caption.isEmpty ? '片段' : placement.caption}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: .68),
              fontFamily: 'serif',
              fontSize: 11,
              letterSpacing: .8,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyScene extends StatelessWidget {
  const _EmptyScene({required this.sceneTheme});

  final GalleryTheme sceneTheme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const Key('scene-background'),
      painter: SceneBackgroundPainter(sceneTheme),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 36,
              color: XulangColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              '这一章还没有照片',
              style: TextStyle(color: sceneForegroundColor(sceneTheme)),
            ),
            const SizedBox(height: 6),
            const Text(
              '导入图片，开始安排故事节奏',
              style: TextStyle(color: XulangColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

Rect resolveStoryLabelRect({
  required StoryPathAnchor anchor,
  required Size viewport,
  Size labelSize = const Size(92, 30),
}) {
  final maxLeft = (viewport.width - labelSize.width - 8).clamp(
    8.0,
    double.infinity,
  );
  final maxTop = (viewport.height - labelSize.height - 8).clamp(
    8.0,
    double.infinity,
  );
  Rect clampCandidate(double left) => Rect.fromLTWH(
    left.clamp(8.0, maxLeft),
    (anchor.point.dy - labelSize.height / 2).clamp(8.0, maxTop),
    labelSize.width,
    labelSize.height,
  );

  double overlapArea(Rect candidate) {
    if (!candidate.overlaps(anchor.nodeRect)) return 0;
    final overlap = candidate.intersect(anchor.nodeRect);
    return overlap.width * overlap.height;
  }

  final right = clampCandidate(anchor.point.dx + 8);
  final left = clampCandidate(anchor.point.dx - 8 - labelSize.width);
  return overlapArea(left) < overlapArea(right) ? left : right;
}

Color storyPathDotColor(GalleryTheme sceneTheme) =>
    sceneForegroundColor(sceneTheme).withValues(alpha: .85);

Color sceneForegroundColor(GalleryTheme sceneTheme) => switch (sceneTheme) {
  GalleryTheme.paper || GalleryTheme.warm => XulangColors.ink,
  GalleryTheme.ink ||
  GalleryTheme.graphite ||
  GalleryTheme.mist => XulangColors.paper,
};

class SceneBackgroundPainter extends CustomPainter {
  const SceneBackgroundPainter(this.sceneTheme, {this.room = false});

  final GalleryTheme sceneTheme;
  final bool room;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final colors = switch (sceneTheme) {
      GalleryTheme.ink => const [Color(0xFF08090A), Color(0xFF191B1C)],
      GalleryTheme.paper => const [Color(0xFFECE4D6), Color(0xFFD9CCB7)],
      GalleryTheme.graphite => const [Color(0xFF111417), Color(0xFF2B3033)],
      GalleryTheme.mist => const [Color(0xFF101820), Color(0xFF263944)],
      GalleryTheme.warm => const [Color(0xFFF0DDC0), Color(0xFFB88F62)],
    };
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.05, -.22),
          radius: 1.15,
          colors: colors,
        ).createShader(rect),
    );
    if (room) _paintRoom(canvas, size);
    final vignette =
        sceneTheme == GalleryTheme.paper || sceneTheme == GalleryTheme.warm
        ? Colors.white.withValues(alpha: .10)
        : Colors.black.withValues(alpha: .28);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, vignette],
        ).createShader(rect),
    );
  }

  void _paintRoom(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .47);
    final floorTop = size.height * .58;
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: .06),
          Colors.black.withValues(alpha: .08),
        ],
      ).createShader(Offset.zero & size);
    final leftWall = Path()
      ..moveTo(0, size.height * .24)
      ..lineTo(center.dx - size.width * .18, center.dy)
      ..lineTo(center.dx - size.width * .22, floorTop)
      ..lineTo(0, size.height * .74)
      ..close();
    final rightWall = Path()
      ..moveTo(size.width, size.height * .24)
      ..lineTo(center.dx + size.width * .18, center.dy)
      ..lineTo(center.dx + size.width * .22, floorTop)
      ..lineTo(size.width, size.height * .74)
      ..close();
    canvas.drawPath(leftWall, wallPaint);
    canvas.drawPath(rightWall, wallPaint);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(center.dx - size.width * .22, floorTop)
        ..lineTo(center.dx + size.width * .22, floorTop)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: .13),
                Colors.black.withValues(alpha: .33),
              ],
            ).createShader(
              Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop),
            ),
    );
    final beamPaint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final dx in [-.30, 0, .30]) {
      canvas.drawLine(Offset(size.width * (.5 + dx), 0), center, beamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SceneBackgroundPainter oldDelegate) =>
      sceneTheme != oldDelegate.sceneTheme || room != oldDelegate.room;
}

StoryPathGeometry transformStoryPathGeometry({
  required StoryPathGeometry geometry,
  required MotionFrame motion,
  required Size viewport,
}) {
  Offset transformPoint(Offset point, Offset pivot) {
    final relative = (point - pivot) * motion.scale;
    final cosine = math.cos(motion.rotation);
    final sine = math.sin(motion.rotation);
    final rotated = Offset(
      relative.dx * cosine - relative.dy * sine,
      relative.dx * sine + relative.dy * cosine,
    );
    return pivot +
        rotated +
        Offset(
          motion.offset.dx * viewport.width,
          motion.offset.dy * viewport.height,
        );
  }

  Rect transformRect(Rect rect, Offset pivot) {
    final points = [
      transformPoint(rect.topLeft, pivot),
      transformPoint(rect.topRight, pivot),
      transformPoint(rect.bottomLeft, pivot),
      transformPoint(rect.bottomRight, pivot),
    ];
    return Rect.fromLTRB(
      points.map((point) => point.dx).reduce(math.min),
      points.map((point) => point.dy).reduce(math.min),
      points.map((point) => point.dx).reduce(math.max),
      points.map((point) => point.dy).reduce(math.max),
    );
  }

  final transformedAnchors = [
    for (final anchor in geometry.anchors)
      StoryPathAnchor(
        placementId: anchor.placementId,
        point: transformPoint(anchor.point, anchor.nodeRect.center),
        nodeRect: transformRect(anchor.nodeRect, anchor.nodeRect.center),
      ),
  ];
  final fallbackPivot = Offset(viewport.width / 2, viewport.height / 2);
  final transformedSegments = <StoryPathSegment>[];
  for (var index = 0; index < geometry.segments.length; index++) {
    final segment = geometry.segments[index];
    final startAnchor = index < geometry.anchors.length
        ? geometry.anchors[index]
        : null;
    final endAnchor = index + 1 < geometry.anchors.length
        ? geometry.anchors[index + 1]
        : null;
    final startPivot = startAnchor?.nodeRect.center ?? fallbackPivot;
    final endPivot = endAnchor?.nodeRect.center ?? startPivot;
    transformedSegments.add(
      StoryPathSegment(
        start: index < transformedAnchors.length
            ? transformedAnchors[index].point
            : transformPoint(segment.start, startPivot),
        control1: transformPoint(segment.control1, startPivot),
        control2: transformPoint(segment.control2, endPivot),
        end: index + 1 < transformedAnchors.length
            ? transformedAnchors[index + 1].point
            : transformPoint(segment.end, endPivot),
      ),
    );
  }
  return StoryPathGeometry(
    anchors: transformedAnchors,
    segments: transformedSegments,
  );
}

class StoryPathPainter extends CustomPainter {
  StoryPathPainter({
    required this.sceneTheme,
    required this.geometry,
    this.style = StoryPathStyle.solid,
  });

  final GalleryTheme sceneTheme;
  final StoryPathGeometry geometry;
  final StoryPathStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final color =
        (sceneTheme == GalleryTheme.paper
                ? XulangColors.ink
                : XulangColors.paper)
            .withValues(alpha: .20);
    if (style == StoryPathStyle.none) return;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = style == StoryPathStyle.glow ? 1.6 : 1;
    for (final segment in geometry.segments) {
      final path = Path()
        ..moveTo(segment.start.dx, segment.start.dy)
        ..cubicTo(
          segment.control1.dx,
          segment.control1.dy,
          segment.control2.dx,
          segment.control2.dy,
          segment.end.dx,
          segment.end.dy,
        );
      if (style == StoryPathStyle.glow) {
        canvas.drawPath(
          path,
          Paint()
            ..color = storyPathDotColor(sceneTheme).withValues(alpha: .20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      }
      if (style == StoryPathStyle.dashed) {
        _drawDashedPath(canvas, path, stroke);
      } else {
        canvas.drawPath(path, stroke);
      }
    }
    final dot = Paint()
      ..color = storyPathDotColor(sceneTheme)
      ..style = PaintingStyle.fill;
    for (final anchor in geometry.anchors) {
      canvas.drawCircle(anchor.point, 3.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant StoryPathPainter oldDelegate) =>
      sceneTheme != oldDelegate.sceneTheme ||
      geometry != oldDelegate.geometry ||
      style != oldDelegate.style;
}

void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = (distance + 14).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += 22;
    }
  }
}
