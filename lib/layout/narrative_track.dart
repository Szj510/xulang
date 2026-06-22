import 'dart:math' as math;
import 'dart:ui';

import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/story_path_geometry.dart';

class NarrativeTransform {
  const NarrativeTransform({
    required this.rect,
    required this.depth,
    required this.opacity,
    required this.rotation,
    required this.rotateY,
  });

  final Rect rect;
  final double depth;
  final double opacity;
  final double rotation;
  final double rotateY;

  static NarrativeTransform lerp(
    NarrativeTransform begin,
    NarrativeTransform end,
    double t,
  ) {
    return NarrativeTransform(
      rect: Rect.lerp(begin.rect, end.rect, t)!,
      depth: _lerpDouble(begin.depth, end.depth, t),
      opacity: _lerpDouble(begin.opacity, end.opacity, t),
      rotation: _lerpDouble(begin.rotation, end.rotation, t),
      rotateY: _lerpDouble(begin.rotateY, end.rotateY, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NarrativeTransform &&
      rect == other.rect &&
      depth == other.depth &&
      opacity == other.opacity &&
      rotation == other.rotation &&
      rotateY == other.rotateY;

  @override
  int get hashCode => Object.hash(rect, depth, opacity, rotation, rotateY);
}

class NarrativeKeyframe {
  const NarrativeKeyframe({
    required this.placementId,
    required this.focusProgress,
    required this.enter,
    required this.focus,
    required this.exit,
  });

  final String placementId;
  final double focusProgress;
  final NarrativeTransform enter;
  final NarrativeTransform focus;
  final NarrativeTransform exit;

  @override
  bool operator ==(Object other) =>
      other is NarrativeKeyframe &&
      placementId == other.placementId &&
      focusProgress == other.focusProgress &&
      enter == other.enter &&
      focus == other.focus &&
      exit == other.exit;

  @override
  int get hashCode =>
      Object.hash(placementId, focusProgress, enter, focus, exit);
}

class NarrativeNodeFrame {
  const NarrativeNodeFrame({
    required this.placementId,
    required this.rect,
    required this.depth,
    required this.opacity,
    required this.rotation,
    required this.rotateY,
  });

  final String placementId;
  final Rect rect;
  final double depth;
  final double opacity;
  final double rotation;
  final double rotateY;

  @override
  bool operator ==(Object other) =>
      other is NarrativeNodeFrame &&
      placementId == other.placementId &&
      rect == other.rect &&
      depth == other.depth &&
      opacity == other.opacity &&
      rotation == other.rotation &&
      rotateY == other.rotateY;

  @override
  int get hashCode =>
      Object.hash(placementId, rect, depth, opacity, rotation, rotateY);
}

class ResolvedNarrativeFrame {
  const ResolvedNarrativeFrame({
    required this.progress,
    required this.nodes,
    required this.axis,
    required this.path,
  });

  final double progress;
  final List<NarrativeNodeFrame> nodes;
  final NarrativeAxis axis;
  final StoryPathGeometry path;

  @override
  bool operator ==(Object other) {
    if (other is! ResolvedNarrativeFrame ||
        progress != other.progress ||
        axis != other.axis ||
        path != other.path ||
        nodes.length != other.nodes.length) {
      return false;
    }
    for (var index = 0; index < nodes.length; index++) {
      if (nodes[index] != other.nodes[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(progress, Object.hashAll(nodes), axis, path);
}

class ResolvedNarrativeTrack {
  const ResolvedNarrativeTrack({
    required this.keyframes,
    required this.visibilityWindow,
    required this.axis,
    required this.viewport,
    required this.contentExtent,
    required this.sharedCamera,
  });

  final List<NarrativeKeyframe> keyframes;
  final double visibilityWindow;
  final NarrativeAxis axis;
  final Size viewport;
  final double contentExtent;
  final bool sharedCamera;

  ResolvedNarrativeFrame resolve(double rawProgress) {
    final progress = rawProgress.clamp(0.0, 1.0);
    if (sharedCamera) return _resolveSharedCamera(progress);
    return ResolvedNarrativeFrame(
      progress: progress,
      axis: axis,
      path: const StoryPathGeometry.empty(),
      nodes: [
        for (final keyframe in keyframes) _resolveKeyframe(keyframe, progress),
      ],
    );
  }

  ResolvedNarrativeFrame _resolveSharedCamera(double progress) {
    final viewportPrimary = axis.primaryExtent(viewport);
    final travel = math.max(0.0, contentExtent - viewportPrimary);
    final camera = travel * progress;
    final viewportCenter = viewportPrimary / 2;
    final focusRange = viewportPrimary * .72;
    final nodes = <NarrativeNodeFrame>[];
    for (final keyframe in keyframes) {
      final worldRect = axis.shiftPrimary(keyframe.focus.rect, -camera);
      final primaryCenter = axis.primaryOffset(worldRect.center);
      final distance = focusRange > 0
          ? ((primaryCenter - viewportCenter).abs() / focusRange).clamp(
              0.0,
              1.0,
            )
          : 1.0;
      final focus = 1 - distance;
      nodes.add(
        NarrativeNodeFrame(
          placementId: keyframe.placementId,
          rect: _scaled(worldRect, .88 + focus * .12),
          depth: .18 + focus * .82,
          opacity: .12 + focus * .88,
          rotation: keyframe.focus.rotation * (.72 + focus * .28),
          rotateY: (1 - focus) * .10,
        ),
      );
    }
    return ResolvedNarrativeFrame(
      progress: progress,
      nodes: nodes,
      axis: axis,
      path: StoryPathGeometry.resolve(
        axis: axis,
        viewport: viewport,
        nodes: [
          for (final node in nodes)
            StoryPathNodeInput(
              placementId: node.placementId,
              rect: node.rect,
              opacity: node.opacity,
            ),
        ],
      ),
    );
  }

  NarrativeNodeFrame _resolveKeyframe(
    NarrativeKeyframe keyframe,
    double progress,
  ) {
    final beforeFocus = progress <= keyframe.focusProgress;
    final distance = (progress - keyframe.focusProgress).abs();
    final linearT = (distance / visibilityWindow).clamp(0.0, 1.0);
    final easedT = _easeInOut(linearT);
    final transform = beforeFocus
        ? NarrativeTransform.lerp(keyframe.enter, keyframe.focus, 1 - easedT)
        : NarrativeTransform.lerp(keyframe.focus, keyframe.exit, easedT);
    return NarrativeNodeFrame(
      placementId: keyframe.placementId,
      rect: transform.rect,
      depth: transform.depth,
      opacity: transform.opacity,
      rotation: transform.rotation,
      rotateY: transform.rotateY,
    );
  }
}

Rect _scaled(Rect rect, double scale) => Rect.fromCenter(
  center: rect.center,
  width: rect.width * scale,
  height: rect.height * scale,
);

double _lerpDouble(double begin, double end, double t) =>
    begin + (end - begin) * t;

double _easeInOut(double value) => value * value * (3 - 2 * value);
