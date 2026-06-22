import 'dart:ui';

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
  const ResolvedNarrativeFrame({required this.progress, required this.nodes});

  final double progress;
  final List<NarrativeNodeFrame> nodes;

  @override
  bool operator ==(Object other) {
    if (other is! ResolvedNarrativeFrame ||
        progress != other.progress ||
        nodes.length != other.nodes.length) {
      return false;
    }
    for (var index = 0; index < nodes.length; index++) {
      if (nodes[index] != other.nodes[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(progress, Object.hashAll(nodes));
}

class ResolvedNarrativeTrack {
  const ResolvedNarrativeTrack({
    required this.keyframes,
    required this.visibilityWindow,
  });

  final List<NarrativeKeyframe> keyframes;
  final double visibilityWindow;

  ResolvedNarrativeFrame resolve(double rawProgress) {
    final progress = rawProgress.clamp(0.0, 1.0);
    return ResolvedNarrativeFrame(
      progress: progress,
      nodes: [
        for (final keyframe in keyframes) _resolveKeyframe(keyframe, progress),
      ],
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

double _lerpDouble(double begin, double end, double t) =>
    begin + (end - begin) * t;

double _easeInOut(double value) => value * value * (3 - 2 * value);
