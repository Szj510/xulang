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
  });

  final GalleryChapter chapter;
  final List<GalleryMedia> media;
  final double cameraProgress;
  final double progress;
  final bool reduceMotion;
  final bool showStoryPath;
  final bool useOriginals;
  final GalleryTheme sceneTheme;

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
        final paper = sceneTheme == GalleryTheme.paper;
        return ClipRect(
          child: ColoredBox(
            key: const Key('scene-background'),
            color: paper ? XulangColors.paper : XulangColors.ink,
            child: Stack(
              children: [
                if (showStoryPath && chapter.layout == GalleryLayout.storyPath)
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
  });

  final NarrativeNodeFrame node;
  final GalleryPlacement placement;
  final GalleryMedia? media;
  final MotionFrame motion;
  final Size viewport;
  final bool useOriginals;
  final GalleryTheme sceneTheme;
  final bool depthWall;

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
          child: PhotoFrame(
            placement: placement,
            media: media,
            depth: node.depth,
            useOriginals: useOriginals,
            sceneTheme: sceneTheme,
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
    final paper = sceneTheme == GalleryTheme.paper;
    return ColoredBox(
      key: const Key('scene-background'),
      color: paper ? XulangColors.paper : XulangColors.ink,
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
              style: TextStyle(
                color: paper ? XulangColors.ink : XulangColors.paper,
              ),
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
    (sceneTheme == GalleryTheme.paper ? XulangColors.ink : XulangColors.paper)
        .withValues(alpha: .85);

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
  StoryPathPainter({required this.sceneTheme, required this.geometry});

  final GalleryTheme sceneTheme;
  final StoryPathGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final color =
        (sceneTheme == GalleryTheme.paper
                ? XulangColors.ink
                : XulangColors.paper)
            .withValues(alpha: .20);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
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
      canvas.drawPath(path, stroke);
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
      sceneTheme != oldDelegate.sceneTheme || geometry != oldDelegate.geometry;
}
