import 'package:flutter/widgets.dart';
import 'package:xulang/layout/narrative_axis.dart';

class StoryPathNodeInput {
  const StoryPathNodeInput({
    required this.placementId,
    required this.rect,
    required this.opacity,
  });

  final String placementId;
  final Rect rect;
  final double opacity;
}

class StoryPathAnchor {
  const StoryPathAnchor({
    required this.placementId,
    required this.point,
    required this.nodeRect,
  });

  final String placementId;
  final Offset point;
  final Rect nodeRect;

  @override
  bool operator ==(Object other) =>
      other is StoryPathAnchor &&
      placementId == other.placementId &&
      point == other.point &&
      nodeRect == other.nodeRect;

  @override
  int get hashCode => Object.hash(placementId, point, nodeRect);
}

class StoryPathSegment {
  const StoryPathSegment({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  @override
  bool operator ==(Object other) =>
      other is StoryPathSegment &&
      start == other.start &&
      control1 == other.control1 &&
      control2 == other.control2 &&
      end == other.end;

  @override
  int get hashCode => Object.hash(start, control1, control2, end);
}

class StoryPathGeometry {
  const StoryPathGeometry({required this.anchors, required this.segments});

  const StoryPathGeometry.empty() : anchors = const [], segments = const [];

  final List<StoryPathAnchor> anchors;
  final List<StoryPathSegment> segments;

  static StoryPathGeometry resolve({
    required NarrativeAxis axis,
    required Size viewport,
    required List<StoryPathNodeInput> nodes,
  }) {
    final visibleBounds = (Offset.zero & viewport).inflate(96);
    final anchors = <StoryPathAnchor>[];
    for (final node in nodes) {
      if (node.opacity <= .05 || !node.rect.overlaps(visibleBounds)) continue;
      final index = anchors.length;
      final point = switch (axis) {
        NarrativeAxis.vertical => Offset(
          index.isEven ? node.rect.right + 10 : node.rect.left - 10,
          node.rect.bottom + 8,
        ),
        NarrativeAxis.horizontal => Offset(
          node.rect.right + 8,
          index.isEven ? node.rect.bottom + 10 : node.rect.top - 10,
        ),
      };
      anchors.add(
        StoryPathAnchor(
          placementId: node.placementId,
          point: point,
          nodeRect: node.rect,
        ),
      );
    }

    final segments = <StoryPathSegment>[];
    for (var index = 1; index < anchors.length; index++) {
      final start = anchors[index - 1].point;
      final end = anchors[index].point;
      final control1 = switch (axis) {
        NarrativeAxis.vertical => Offset(
          start.dx,
          start.dy + (end.dy - start.dy) / 3,
        ),
        NarrativeAxis.horizontal => Offset(
          start.dx + (end.dx - start.dx) / 3,
          start.dy,
        ),
      };
      final control2 = switch (axis) {
        NarrativeAxis.vertical => Offset(
          end.dx,
          start.dy + (end.dy - start.dy) * 2 / 3,
        ),
        NarrativeAxis.horizontal => Offset(
          start.dx + (end.dx - start.dx) * 2 / 3,
          end.dy,
        ),
      };
      segments.add(
        StoryPathSegment(
          start: start,
          control1: control1,
          control2: control2,
          end: end,
        ),
      );
    }
    return StoryPathGeometry(anchors: anchors, segments: segments);
  }

  @override
  bool operator ==(Object other) =>
      other is StoryPathGeometry &&
      _listEquals(anchors, other.anchors) &&
      _listEquals(segments, other.segments);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(anchors), Object.hashAll(segments));
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
