import 'dart:math' as math;
import 'dart:ui';

import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/orbit_geometry.dart';
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
  ResolvedNarrativeFrame({
    required this.progress,
    required List<NarrativeNodeFrame> nodes,
    required this.axis,
    required this.path,
  }) : nodes = List.unmodifiable(nodes);

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
    this.orbitMotion = false,
  });

  final List<NarrativeKeyframe> keyframes;
  final double visibilityWindow;
  final NarrativeAxis axis;
  final Size viewport;
  final double contentExtent;
  final bool sharedCamera;
  final bool orbitMotion;

  ResolvedNarrativeFrame resolve(double rawProgress) {
    final progress = rawProgress.clamp(0.0, 1.0);
    if (orbitMotion) return _resolveOrbit(progress);
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

  ResolvedNarrativeFrame _resolveOrbit(double progress) {
    if (keyframes.isEmpty || viewport.isEmpty) {
      return ResolvedNarrativeFrame(
        progress: progress,
        nodes: const [],
        axis: axis,
        path: const StoryPathGeometry.empty(),
      );
    }

    final center = Offset(viewport.width * .5, viewport.height * .49);
    final planeRotation = orbitPlaneRotation(viewport);
    final orbitPhase = progress * math.pi * 2;
    final nodes = <NarrativeNodeFrame>[];

    for (var index = 0; index < keyframes.length; index++) {
      final keyframe = keyframes[index];
      if (index == 0) {
        const focusWindow = .20;
        final focusDistance = (progress / focusWindow).clamp(0.0, 1.0);
        final focus = 1 - _easeInOut(focusDistance);
        nodes.add(
          NarrativeNodeFrame(
            placementId: keyframe.placementId,
            rect: _scaled(keyframe.focus.rect, .94 + focus * .06),
            depth: .58 + focus * .42,
            opacity: .58 + focus * .42,
            rotation: keyframe.focus.rotation,
            rotateY: 0,
          ),
        );
        continue;
      }

      final outerRing = index > 6;
      final radii = orbitRadii(viewport, outer: outerRing);
      final radiusX = radii.width;
      final radiusY = radii.height;
      final sourceCenter = keyframe.focus.rect.center;
      final sourceAngle = orbitAngleForPoint(
        point: sourceCenter,
        center: center,
        radiusX: radiusX,
        radiusY: radiusY,
        planeRotation: planeRotation,
      );
      final sourceEllipsePoint = orbitPoint(
        center: center,
        radiusX: radiusX,
        radiusY: radiusY,
        angle: sourceAngle,
        planeRotation: planeRotation,
      );
      final manualOffset = sourceCenter - sourceEllipsePoint;
      final angle = sourceAngle + orbitPhase;
      final animatedCenter =
          orbitPoint(
            center: center,
            radiusX: radiusX,
            radiusY: radiusY,
            angle: angle,
            planeRotation: planeRotation,
          ) +
          manualOffset;

      final front = (math.sin(angle) + 1) / 2;
      final focusWindow = math.min(.22, visibilityWindow * .42);
      final progressDistance =
          ((progress - keyframe.focusProgress).abs() / focusWindow).clamp(
            0.0,
            1.0,
          );
      final focus = 1 - _easeInOut(progressDistance);
      final orbitScale = .75 + front * .15 + focus * .14;
      final orbitDepth = .18 + front * .57;
      final orbitOpacity = .18 + front * .52;
      final rect = Rect.fromCenter(
        center: animatedCenter,
        width: keyframe.focus.rect.width,
        height: keyframe.focus.rect.height,
      );
      nodes.add(
        NarrativeNodeFrame(
          placementId: keyframe.placementId,
          rect: _scaled(rect, orbitScale),
          depth: math.max(orbitDepth, focus),
          opacity: math.max(orbitOpacity, focus),
          rotation:
              keyframe.focus.rotation + math.sin(angle + math.pi / 4) * .018,
          rotateY: (1 - front) * .14,
        ),
      );
    }

    return ResolvedNarrativeFrame(
      progress: progress,
      nodes: nodes,
      axis: axis,
      path: const StoryPathGeometry.empty(),
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
      final screenFocus = 1 - distance;
      final progressDistance =
          ((progress - keyframe.focusProgress).abs() / visibilityWindow).clamp(
            0.0,
            1.0,
          );
      final progressFocus = 1 - _easeInOut(progressDistance);
      final focus = math.max(screenFocus, progressFocus);
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
