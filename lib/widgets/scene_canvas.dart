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
        final anchorsByPlacement = {
          for (final anchor in frame.path.anchors) anchor.placementId: anchor,
        };
        final nodesByPlacement = {
          for (final node in frame.nodes) node.placementId: node,
        };
        final nodes = [...frame.nodes]
          ..sort((a, b) => a.depth.compareTo(b.depth));
        final motion = MotionResolver.resolve(
          motion: chapter.motion,
          progress: progress,
          reduceMotion: reduceMotion,
        );
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
                      child: CustomPaint(
                        key: const Key('story-path-line'),
                        painter: StoryPathPainter(
                          sceneTheme: sceneTheme,
                          geometry: frame.path,
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
                            nodesByPlacement[anchor.placementId]?.opacity ?? 0,
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
  });

  final NarrativeNodeFrame node;
  final GalleryPlacement placement;
  final GalleryMedia? media;
  final MotionFrame motion;
  final Size viewport;
  final bool useOriginals;
  final GalleryTheme sceneTheme;

  @override
  Widget build(BuildContext context) {
    final dx = motion.offset.dx * viewport.width;
    final dy = motion.offset.dy * viewport.height;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, .00135)
      ..translateByDouble(dx, dy, node.depth * 10, 1)
      ..rotateY(node.rotateY)
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
  var rect = Rect.fromLTWH(
    anchor.point.dx + 8,
    anchor.point.dy - labelSize.height / 2,
    labelSize.width,
    labelSize.height,
  );
  if (rect.overlaps(anchor.nodeRect)) {
    rect = Rect.fromLTWH(
      anchor.point.dx - 8 - labelSize.width,
      rect.top,
      labelSize.width,
      labelSize.height,
    );
  }
  final maxLeft = (viewport.width - labelSize.width - 8).clamp(
    8.0,
    double.infinity,
  );
  final maxTop = (viewport.height - labelSize.height - 8).clamp(
    8.0,
    double.infinity,
  );
  return Rect.fromLTWH(
    rect.left.clamp(8.0, maxLeft),
    rect.top.clamp(8.0, maxTop),
    labelSize.width,
    labelSize.height,
  );
}

Color storyPathDotColor(GalleryTheme sceneTheme) =>
    (sceneTheme == GalleryTheme.paper ? XulangColors.ink : XulangColors.paper)
        .withValues(alpha: .85);

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
