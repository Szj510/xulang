import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/layout/motion_resolver.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_track.dart';
import 'package:xulang/layout/narrative_track_resolver.dart';
import 'package:xulang/layout/orbit_geometry.dart';
import 'package:xulang/layout/story_path_geometry.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/atmospheric_sticker.dart';
import 'package:xulang/widgets/gallery_image.dart';
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
    this.canvasBackgroundPath,
    this.canvasBackgroundOpacity = 0.32,
    this.placementEditingEnabled = true,
    this.stickerEditingEnabled = false,
    this.selectedStickerKind,
    this.onStickerPlaced,
    this.onStickerChanged,
    this.onStickerDeleted,
    this.onStickerTap,
    this.onPlacementTap,
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
  final String? canvasBackgroundPath;
  final double canvasBackgroundOpacity;
  final bool placementEditingEnabled;
  final bool stickerEditingEnabled;
  final GalleryStickerKind? selectedStickerKind;
  final void Function(Offset localPosition, Size viewport)? onStickerPlaced;
  final ValueChanged<GallerySticker>? onStickerChanged;
  final ValueChanged<String>? onStickerDeleted;
  final ValueChanged<String>? onStickerTap;
  final void Function(String placementId)? onPlacementTap;
  final void Function(String placementId)? onPlacementTransformStart;
  final void Function(
    String placementId,
    double scaleDelta,
    Offset delta,
    double rotationDelta,
  )?
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
          return Stack(
            children: [
              Positioned.fill(child: _EmptyScene(sceneTheme: sceneTheme)),
              if (canvasBackgroundPath != null &&
                  canvasBackgroundPath!.trim().isNotEmpty)
                _CustomCanvasBackground(
                  path: canvasBackgroundPath,
                  opacity: canvasBackgroundOpacity,
                ),
            ],
          );
        }
        final track = NarrativeTrackResolver.resolve(
          chapter: chapter,
          viewport: viewport,
        );
        var effectiveCameraProgress = cameraProgress;
        var frame = track.resolve(effectiveCameraProgress);
        if (!_hasVisibleNode(frame, viewport)) {
          effectiveCameraProgress = 0;
          frame = track.resolve(effectiveCameraProgress);
        }
        final stickerCameraOffset = _stickerCameraOffset(
          track,
          viewport,
          effectiveCameraProgress,
        );
        final motion = MotionResolver.resolve(
          motion: chapter.motion,
          progress: progress,
          reduceMotion: reduceMotion,
        );
        final customPathAnchors = chapter.customPathAnchors;
        final basePath = customPathAnchors == null
            ? frame.path
            : resolveCustomStoryPathGeometry(
                anchors: customPathAnchors,
                viewport: viewport,
              );
        final displayedGeometry = transformStoryPathGeometry(
          geometry: basePath,
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
        final orbitLayout = chapter.layout == GalleryLayout.orbit;
        final orbitCenterId = orbitLayout && chapter.placements.isNotEmpty
            ? chapter.placements.first.id
            : null;
        final orbitCenterNode = orbitCenterId == null
            ? null
            : nodesByPlacement[orbitCenterId];
        final orbitBackNodes = orbitLayout
            ? nodes
                  .where(
                    (node) =>
                        node.placementId != orbitCenterId && node.depth < .50,
                  )
                  .toList()
            : const <NarrativeNodeFrame>[];
        final orbitFrontNodes = orbitLayout
            ? nodes
                  .where(
                    (node) =>
                        node.placementId != orbitCenterId && node.depth >= .50,
                  )
                  .toList()
            : const <NarrativeNodeFrame>[];

        Widget buildSceneNode(
          NarrativeNodeFrame node,
          GalleryPlacement placement,
        ) => _SceneNodeWidget(
          node: node,
          placement: placement,
          media: mediaById[placement.mediaId],
          motion: motion,
          viewport: viewport,
          useOriginals: useOriginals,
          sceneTheme: sceneTheme,
          orbitLighting: orbitLayout,
          onTap: onPlacementTap,
          onTransformStart: placementEditingEnabled
              ? onPlacementTransformStart
              : null,
          onTransformUpdate: placementEditingEnabled
              ? onPlacementTransformUpdate
              : null,
          onTransformEnd: placementEditingEnabled
              ? onPlacementTransformEnd
              : null,
        );

        Widget orbitTrackLayer(OrbitRingSegment segment) => Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: motion.opacity.clamp(0, 1),
              child: CustomPaint(
                key: Key('orbit-track-${segment.name}'),
                painter: OrbitBackdropPainter(
                  sceneTheme,
                  ringCount: orbitRingCount(chapter.placements.length),
                  segment: segment,
                ),
              ),
            ),
          ),
        );
        return ClipRect(
          child: CustomPaint(
            key: const Key('scene-background'),
            painter: SceneBackgroundPainter(sceneTheme, room: false),
            child: Stack(
              children: [
                if (canvasBackgroundPath != null &&
                    canvasBackgroundPath!.trim().isNotEmpty)
                  _CustomCanvasBackground(
                    path: canvasBackgroundPath,
                    opacity: canvasBackgroundOpacity,
                  ),
                if (chapter.layout == GalleryLayout.orbit &&
                    orbitRingCount(chapter.placements.length) > 0)
                  orbitTrackLayer(OrbitRingSegment.back),
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
                if (!orbitLayout)
                  for (final node in nodes)
                    if (placementsById[node.placementId] case final placement?)
                      buildSceneNode(node, placement),
                if (orbitLayout)
                  for (final node in orbitBackNodes)
                    if (placementsById[node.placementId] case final placement?)
                      buildSceneNode(node, placement),
                if (orbitCenterNode case final centerNode?)
                  if (placementsById[centerNode.placementId]
                      case final placement?)
                    buildSceneNode(centerNode, placement),
                if (orbitLayout &&
                    orbitRingCount(chapter.placements.length) > 0)
                  orbitTrackLayer(OrbitRingSegment.front),
                if (orbitLayout)
                  for (final node in orbitFrontNodes)
                    if (placementsById[node.placementId] case final placement?)
                      buildSceneNode(node, placement),
                if (chapter.layout == GalleryLayout.storyPath &&
                    customPathAnchors == null)
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
                if (chapter.layout == GalleryLayout.storyPath &&
                    customPathAnchors != null)
                  for (
                    var index = 0;
                    index < customPathAnchors.length &&
                        index < displayedGeometry.anchors.length;
                    index++
                  )
                    _CustomStoryPathLabel(
                      anchor: displayedGeometry.anchors[index],
                      source: customPathAnchors[index],
                      index: index,
                      opacity: motion.opacity,
                      sceneTheme: sceneTheme,
                    ),
                if (stickerEditingEnabled && selectedStickerKind != null)
                  Positioned.fill(
                    child: GestureDetector(
                      key: const Key('scene-sticker-place-surface'),
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        final placementId = _hitPlacementAt(
                          screenPoint: details.localPosition,
                          nodes: nodes,
                          placementsById: placementsById,
                          motion: motion,
                          viewport: viewport,
                        );
                        if (placementId != null) {
                          onPlacementTap?.call(placementId);
                          return;
                        }
                        if (_isStickerTapTarget(
                          screenPoint: details.localPosition,
                          stickers: chapter.stickers,
                          viewport: viewport,
                          axis: track.axis,
                          cameraOffset: stickerCameraOffset,
                          usesSharedCamera: track.sharedCamera,
                        )) {
                          return;
                        }
                        onStickerPlaced?.call(
                          _stickerScreenToWorld(
                            details.localPosition,
                            track.axis,
                            stickerCameraOffset,
                            track.sharedCamera,
                          ),
                          viewport,
                        );
                      },
                    ),
                  ),
                for (final sticker in chapter.stickers)
                  _StickerWidget(
                    sticker: sticker,
                    viewport: viewport,
                    opacity: motion.opacity.clamp(0, 1),
                    axis: track.axis,
                    cameraOffset: stickerCameraOffset,
                    usesSharedCamera: track.sharedCamera,
                    editable: stickerEditingEnabled,
                    onChanged: onStickerChanged,
                    onDeleted: onStickerDeleted,
                    onTap: onStickerTap,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

bool _hasVisibleNode(ResolvedNarrativeFrame frame, Size viewport) {
  if (frame.nodes.isEmpty) return true;
  final visibleRect = (Offset.zero & viewport).inflate(96);
  return frame.nodes.any(
    (node) => node.opacity > 0.02 && node.rect.overlaps(visibleRect),
  );
}

double _stickerCameraOffset(
  ResolvedNarrativeTrack track,
  Size viewport,
  double progress,
) {
  if (!track.sharedCamera) return 0;
  final viewportPrimary = track.axis.primaryExtent(viewport);
  final travel = math.max(0.0, track.contentExtent - viewportPrimary);
  return travel * progress.clamp(0.0, 1.0);
}

Offset _stickerScreenToWorld(
  Offset screenPoint,
  NarrativeAxis axis,
  double cameraOffset,
  bool usesSharedCamera,
) {
  if (!usesSharedCamera) return screenPoint;
  return switch (axis) {
    NarrativeAxis.horizontal => Offset(
      screenPoint.dx + cameraOffset,
      screenPoint.dy,
    ),
    NarrativeAxis.vertical => Offset(
      screenPoint.dx,
      screenPoint.dy + cameraOffset,
    ),
  };
}

Offset _stickerWorldToScreen(
  Offset worldPoint,
  NarrativeAxis axis,
  double cameraOffset,
  bool usesSharedCamera,
) {
  if (!usesSharedCamera) return worldPoint;
  return switch (axis) {
    NarrativeAxis.horizontal => Offset(
      worldPoint.dx - cameraOffset,
      worldPoint.dy,
    ),
    NarrativeAxis.vertical => Offset(
      worldPoint.dx,
      worldPoint.dy - cameraOffset,
    ),
  };
}

bool _isStickerTapTarget({
  required Offset screenPoint,
  required List<GallerySticker> stickers,
  required Size viewport,
  required NarrativeAxis axis,
  required double cameraOffset,
  required bool usesSharedCamera,
}) {
  for (final sticker in stickers) {
    final size = 42.0 * sticker.scale.clamp(0.6, 1.8);
    final worldCenter = Offset(
      sticker.x * viewport.width,
      sticker.y * viewport.height,
    );
    final screenCenter = _stickerWorldToScreen(
      worldCenter,
      axis,
      cameraOffset,
      usesSharedCamera,
    );
    final hitRect = Rect.fromCenter(
      center: screenCenter,
      width: size + 52,
      height: size + 52,
    );
    if (hitRect.contains(screenPoint)) return true;
  }
  return false;
}

String? _hitPlacementAt({
  required Offset screenPoint,
  required List<NarrativeNodeFrame> nodes,
  required Map<String, GalleryPlacement> placementsById,
  required MotionFrame motion,
  required Size viewport,
}) {
  final dx = motion.offset.dx * viewport.width;
  final dy = motion.offset.dy * viewport.height;
  for (final node in nodes.reversed) {
    if (node.opacity * motion.opacity <= 0.02 ||
        !placementsById.containsKey(node.placementId)) {
      continue;
    }
    final hitRect = node.rect.shift(Offset(dx, dy)).inflate(18);
    if (hitRect.contains(screenPoint)) return node.placementId;
  }
  return null;
}

class _CustomCanvasBackground extends StatelessWidget {
  const _CustomCanvasBackground({required this.path, required this.opacity});

  final String? path;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final value = path;
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      key: const Key('scene-custom-canvas-background'),
      child: IgnorePointer(
        child: Opacity(
          key: const Key('scene-custom-canvas-opacity'),
          opacity: opacity.clamp(0, 1).toDouble(),
          child: GalleryImage(path: value, cacheWidth: 1400),
        ),
      ),
    );
  }
}

class _StickerWidget extends StatelessWidget {
  const _StickerWidget({
    required this.sticker,
    required this.viewport,
    required this.opacity,
    required this.axis,
    required this.cameraOffset,
    required this.usesSharedCamera,
    required this.editable,
    required this.onChanged,
    required this.onDeleted,
    required this.onTap,
  });

  final GallerySticker sticker;
  final Size viewport;
  final double opacity;
  final NarrativeAxis axis;
  final double cameraOffset;
  final bool usesSharedCamera;
  final bool editable;
  final ValueChanged<GallerySticker>? onChanged;
  final ValueChanged<String>? onDeleted;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    const baseSize = 42.0;
    final size = baseSize * sticker.scale.clamp(0.6, 1.8);
    final worldCenter = Offset(
      sticker.x * viewport.width,
      sticker.y * viewport.height,
    );
    final screenCenter = _stickerWorldToScreen(
      worldCenter,
      axis,
      cameraOffset,
      usesSharedCamera,
    );
    const deleteHitSize = 46.0;
    final hitSize = size + 58;
    final left = screenCenter.dx - hitSize / 2;
    final top = screenCenter.dy - hitSize / 2;
    return Positioned(
      left: left,
      top: top,
      width: hitSize,
      height: hitSize,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: GestureDetector(
                key: Key('scene-sticker-${sticker.id}'),
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap?.call(sticker.id),
                onPanUpdate: !editable || onChanged == null
                    ? null
                    : (details) {
                        final nextScreenCenter = screenCenter + details.delta;
                        final nextWorldCenter = _stickerScreenToWorld(
                          nextScreenCenter,
                          axis,
                          cameraOffset,
                          usesSharedCamera,
                        );
                        onChanged!(
                          sticker.copyWith(
                            x: nextWorldCenter.dx / viewport.width,
                            y: nextWorldCenter.dy / viewport.height,
                          ),
                        );
                      },
                child: AtmosphericSticker(
                  kind: sticker.kind,
                  size: size,
                  rotation: sticker.rotation,
                  opacity: opacity,
                ),
              ),
            ),
            if (editable)
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  key: Key('scene-sticker-delete-${sticker.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onDeleted?.call(sticker.id),
                  child: SizedBox(
                    width: deleteHitSize,
                    height: deleteHitSize,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .72),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .34),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomStoryPathLabel extends StatelessWidget {
  const _CustomStoryPathLabel({
    required this.anchor,
    required this.source,
    required this.index,
    required this.opacity,
    required this.sceneTheme,
  });

  final StoryPathAnchor anchor;
  final CustomPathAnchor source;
  final int index;
  final double opacity;
  final GalleryTheme sceneTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = sceneForegroundColor(sceneTheme);
    final text = source.label.trim().isEmpty ? '点 ${index + 1}' : source.label;
    return Positioned(
      left: anchor.point.dx + 8,
      top: anchor.point.dy - 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: (opacity * .82).clamp(0, 1),
          child: Text(
            text,
            style: TextStyle(
              color: foreground.withValues(alpha: .72),
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

class _SceneNodeWidget extends StatelessWidget {
  const _SceneNodeWidget({
    required this.node,
    required this.placement,
    required this.media,
    required this.motion,
    required this.viewport,
    required this.useOriginals,
    required this.sceneTheme,
    required this.orbitLighting,

    this.onTap,
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
  final bool orbitLighting;

  final void Function(String placementId)? onTap;
  final void Function(String placementId)? onTransformStart;
  final void Function(
    String placementId,
    double scaleDelta,
    Offset delta,
    double rotationDelta,
  )?
  onTransformUpdate;
  final void Function(String placementId)? onTransformEnd;

  @override
  Widget build(BuildContext context) {
    final dx = motion.offset.dx * viewport.width;
    final dy = motion.offset.dy * viewport.height;
    const perspective = .00135;
    const zLift = 10.0;
    final yRotation = node.rotateY;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..translateByDouble(dx, dy, node.depth * zLift, 1)
      ..rotateY(yRotation)
      ..rotateZ(node.rotation + motion.rotation)
      ..scaleByDouble(motion.scale, motion.scale, 1, 1);
    final photoFrame = PhotoFrame(
      placement: placement,
      media: media,
      depth: node.depth,
      useOriginals: useOriginals,
      sceneTheme: sceneTheme,
    );
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
            onTap: onTap == null ? null : () => onTap!.call(placement.id),
            onScaleStart: onTransformUpdate == null
                ? null
                : (_) => onTransformStart?.call(placement.id),
            onScaleUpdate: onTransformUpdate == null
                ? null
                : (details) => onTransformUpdate!(
                    placement.id,
                    details.scale,
                    details.focalPointDelta,
                    details.rotation,
                  ),
            onScaleEnd: onTransformUpdate == null
                ? null
                : (_) => onTransformEnd?.call(placement.id),
            child: orbitLighting
                ? ColorFiltered(
                    key: Key('scene-orbit-lighting-${placement.id}'),
                    colorFilter: ColorFilter.matrix(
                      _orbitLightMatrix(node.depth),
                    ),
                    child: photoFrame,
                  )
                : photoFrame,
          ),
        ),
      ),
    );
  }
}

List<double> _orbitLightMatrix(double depth) {
  final light = .46 + depth.clamp(0.0, 1.0) * .64;
  return <double>[
    light,
    0,
    0,
    0,
    0,
    0,
    light,
    0,
    0,
    0,
    0,
    0,
    light,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
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
    final foreground = sceneForegroundColor(sceneTheme);
    final labelText = AppStrings.of(
      context,
    ).placementCaption(placement.id, placement.caption).trim();
    if (labelText.isEmpty) return const SizedBox.shrink();
    final rect = resolveStoryLabelRect(anchor: anchor, viewport: viewport);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Opacity(
          key: Key('story-label-opacity-${placement.id}'),
          opacity: (opacity * .82).clamp(0, 1),
          child: Text(
            '${(index + 1).toString().padLeft(2, '0')}  '
            '$labelText',
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
  GalleryTheme.paper ||
  GalleryTheme.warm ||
  GalleryTheme.botanical ||
  GalleryTheme.terracotta => XulangColors.ink,
  GalleryTheme.ink ||
  GalleryTheme.graphite ||
  GalleryTheme.mist ||
  GalleryTheme.moonlight ||
  GalleryTheme.cyanotype ||
  GalleryTheme.starfield => XulangColors.paper,
};

enum OrbitRingSegment { back, front }

class OrbitBackdropPainter extends CustomPainter {
  const OrbitBackdropPainter(
    this.sceneTheme, {
    required this.ringCount,
    required this.segment,
  });

  final GalleryTheme sceneTheme;
  final int ringCount;
  final OrbitRingSegment segment;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || ringCount <= 0) return;
    final center = Offset(size.width * .5, size.height * .49);
    final foreground = sceneForegroundColor(sceneTheme);
    final planeRotation = orbitPlaneRotation(size);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(planeRotation);
    canvas.translate(-center.dx, -center.dy);

    if (segment == OrbitRingSegment.back) {
      final haloRect = Rect.fromCenter(
        center: center,
        width: size.width * .76,
        height: size.height * (size.height >= size.width ? .28 : .58),
      );
      canvas.drawOval(
        haloRect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              foreground.withValues(alpha: .075),
              foreground.withValues(alpha: 0),
            ],
          ).createShader(haloRect),
      );
    }

    final rings = <Rect>[
      for (var index = 0; index < ringCount; index++)
        Rect.fromCenter(
          center: center,
          width: orbitRadii(size, outer: index == 1).width * 2,
          height: orbitRadii(size, outer: index == 1).height * 2,
        ),
    ];
    for (var ringIndex = 0; ringIndex < rings.length; ringIndex++) {
      final ring = rings[ringIndex];
      final front = segment == OrbitRingSegment.front;
      final baseAlpha = ringIndex == 0 ? .13 : .065;
      canvas.drawArc(
        ring,
        front ? 0 : math.pi,
        math.pi,
        false,
        Paint()
          ..color = foreground.withValues(
            alpha: baseAlpha * (front ? 2.4 : .58),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = front ? (ringIndex == 0 ? 1.9 : 1.35) : .65,
      );
      final tickCount = ringIndex == 0 ? 18 : 24;
      for (var tick = 0; tick < tickCount; tick++) {
        final angle = -math.pi / 2 + math.pi * 2 * tick / tickCount;
        final tickIsFront = math.sin(angle) >= 0;
        if (tickIsFront != front) continue;
        final point = Offset(
          center.dx + math.cos(angle) * ring.width / 2,
          center.dy + math.sin(angle) * ring.height / 2,
        );
        final radius = tick % 3 == 0 ? 1.45 : .75;
        canvas.drawCircle(
          point,
          radius,
          Paint()
            ..color = foreground.withValues(alpha: tick % 3 == 0 ? .26 : .14),
        );
      }
    }

    if (segment == OrbitRingSegment.back) {
      canvas.drawCircle(
        center,
        2.2,
        Paint()..color = foreground.withValues(alpha: .38),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbitBackdropPainter oldDelegate) =>
      sceneTheme != oldDelegate.sceneTheme ||
      ringCount != oldDelegate.ringCount ||
      segment != oldDelegate.segment;
}

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
      GalleryTheme.moonlight => const [Color(0xFF101421), Color(0xFF3B3155)],
      GalleryTheme.botanical => const [Color(0xFFE2D7BC), Color(0xFF8A9B77)],
      GalleryTheme.cyanotype => const [Color(0xFF061D37), Color(0xFF1D5C80)],
      GalleryTheme.terracotta => const [Color(0xFFF2D7BD), Color(0xFF9C5C42)],
      GalleryTheme.starfield => const [Color(0xFF02040D), Color(0xFF15254A)],
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
    if (sceneTheme == GalleryTheme.starfield) {
      _paintStarfield(canvas, size);
    }
    if (room) _paintRoom(canvas, size);
    final lightCanvas =
        sceneTheme == GalleryTheme.paper ||
        sceneTheme == GalleryTheme.warm ||
        sceneTheme == GalleryTheme.botanical ||
        sceneTheme == GalleryTheme.terracotta;
    final vignette = lightCanvas
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

  void _paintStarfield(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.42, -.18),
        radius: .78,
        colors: [
          const Color(0xFF6D79C9).withValues(alpha: .14),
          const Color(0xFF2E8FA4).withValues(alpha: .055),
          Colors.transparent,
        ],
        stops: const [0, .38, 1],
      ).createShader(rect);
    canvas.drawRect(rect, nebulaPaint);

    for (var index = 0; index < 96; index++) {
      final xSeed = (index * 73 + index * index * 17 + 31) % 997;
      final ySeed = (index * 151 + index * index * 7 + 47) % 991;
      final point = Offset(size.width * xSeed / 997, size.height * ySeed / 991);
      final bright = index % 17 == 0;
      final radius = bright ? 1.35 : .35 + (index % 5) * .12;
      if (bright) {
        canvas.drawCircle(
          point,
          radius * 3.8,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    const Color(0xFFDBE9FF).withValues(alpha: .22),
                    Colors.transparent,
                  ],
                ).createShader(
                  Rect.fromCircle(center: point, radius: radius * 3.8),
                ),
        );
      }
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFAEC8FF),
            Colors.white,
            (index % 7) / 7,
          )!.withValues(alpha: bright ? .92 : .38 + (index % 4) * .11),
      );
    }
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

StoryPathGeometry resolveCustomStoryPathGeometry({
  required List<CustomPathAnchor> anchors,
  required Size viewport,
}) {
  if (anchors.isEmpty || viewport.isEmpty) {
    return const StoryPathGeometry.empty();
  }

  Offset normalizedPoint(double x, double y) => Offset(
    x.clamp(0.0, 1.0) * viewport.width,
    y.clamp(0.0, 1.0) * viewport.height,
  );

  final resolvedAnchors = <StoryPathAnchor>[];
  for (var index = 0; index < anchors.length; index++) {
    final point = normalizedPoint(anchors[index].x, anchors[index].y);
    resolvedAnchors.add(
      StoryPathAnchor(
        placementId: 'custom-path-$index',
        point: point,
        nodeRect: Rect.fromCenter(center: point, width: 1, height: 1),
      ),
    );
  }

  final segments = <StoryPathSegment>[];
  for (var index = 1; index < resolvedAnchors.length; index++) {
    final previousSource = anchors[index - 1];
    final source = anchors[index];
    final start = resolvedAnchors[index - 1].point;
    final end = resolvedAnchors[index].point;
    final control1 = previousSource.cp1x == null || previousSource.cp1y == null
        ? Offset.lerp(start, end, .34)!
        : normalizedPoint(previousSource.cp1x!, previousSource.cp1y!);
    final control2 = source.cp2x == null || source.cp2y == null
        ? Offset.lerp(start, end, .66)!
        : normalizedPoint(source.cp2x!, source.cp2y!);
    segments.add(
      StoryPathSegment(
        start: start,
        control1: control1,
        control2: control2,
        end: end,
      ),
    );
  }

  return StoryPathGeometry(anchors: resolvedAnchors, segments: segments);
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
    final color = sceneForegroundColor(sceneTheme).withValues(alpha: .20);
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
