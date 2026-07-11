import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/orbit_geometry.dart';

class LayoutResolver {
  const LayoutResolver._();

  static ResolvedScene resolve({
    required GalleryChapter chapter,
    required Size viewport,
  }) {
    return switch (chapter.layout) {
      GalleryLayout.hero => _hero(chapter.placements, viewport),
      GalleryLayout.filmstrip => _filmstrip(chapter.placements, viewport),
      GalleryLayout.diptych => _diptych(chapter.placements, viewport),
      GalleryLayout.collage => _collage(chapter.placements, viewport),
      GalleryLayout.storyPath => _storyPath(chapter.placements, viewport),
      GalleryLayout.orbit => _orbit(chapter.placements, viewport),
    };
  }

  static ResolvedScene _hero(List<GalleryPlacement> items, Size size) {
    final portrait = size.height >= size.width;
    final rects = portrait
        ? <Rect>[
            Rect.fromLTWH(
              size.width * .13,
              size.height * .16,
              size.width * .69,
              size.height * .56,
            ),
            Rect.fromLTWH(
              size.width * .70,
              size.height * .31,
              size.width * .26,
              size.height * .31,
            ),
            Rect.fromLTWH(
              size.width * .04,
              size.height * .27,
              size.width * .23,
              size.height * .23,
            ),
            Rect.fromLTWH(
              size.width * .57,
              size.height * .68,
              size.width * .31,
              size.height * .20,
            ),
          ]
        : <Rect>[
            Rect.fromLTWH(
              size.width * .20,
              size.height * .10,
              size.width * .57,
              size.height * .77,
            ),
            Rect.fromLTWH(
              size.width * .73,
              size.height * .23,
              size.width * .23,
              size.height * .52,
            ),
            Rect.fromLTWH(
              size.width * .04,
              size.height * .21,
              size.width * .23,
              size.height * .47,
            ),
            Rect.fromLTWH(
              size.width * .55,
              size.height * .66,
              size.width * .27,
              size.height * .25,
            ),
          ];
    return ResolvedScene(
      nodes: _nodesFromPattern(
        items,
        rects,
        viewport: size,
        depths: const [1, .45, .2, .6],
      ),
      primaryAxis: Axis.vertical,
      contentExtent: size.height,
    );
  }

  static ResolvedScene _filmstrip(List<GalleryPlacement> items, Size size) {
    final nodes = <SceneNode>[];
    var x = size.width * .09;
    for (final item in items) {
      final scale = _sizeScale(item.size);
      final width = size.width * .70 * scale;
      final height =
          size.height * (size.height >= size.width ? .58 : .72) * scale;
      nodes.add(
        _applyManualTransform(
          item: item,
          viewport: size,
          node: SceneNode(
            placementId: item.id,
            rect: Rect.fromLTWH(x, (size.height - height) / 2, width, height),
            depth: item.size == GallerySize.large ? 1 : .65,
          ),
        ),
      );
      x += width + size.width * .07;
    }
    return ResolvedScene(
      nodes: nodes,
      primaryAxis: Axis.horizontal,
      contentExtent: x + size.width * .02,
    );
  }

  static ResolvedScene _diptych(List<GalleryPlacement> items, Size size) {
    final portrait = size.height >= size.width;
    final rects = portrait
        ? <Rect>[
            Rect.fromLTWH(
              size.width * .06,
              size.height * .15,
              size.width * .44,
              size.height * .56,
            ),
            Rect.fromLTWH(
              size.width * .53,
              size.height * .22,
              size.width * .41,
              size.height * .56,
            ),
            Rect.fromLTWH(
              size.width * .12,
              size.height * .73,
              size.width * .32,
              size.height * .16,
            ),
            Rect.fromLTWH(
              size.width * .56,
              size.height * .06,
              size.width * .29,
              size.height * .15,
            ),
          ]
        : <Rect>[
            Rect.fromLTWH(
              size.width * .08,
              size.height * .08,
              size.width * .40,
              size.height * .82,
            ),
            Rect.fromLTWH(
              size.width * .52,
              size.height * .08,
              size.width * .40,
              size.height * .82,
            ),
            Rect.fromLTWH(
              size.width * .37,
              size.height * .65,
              size.width * .25,
              size.height * .27,
            ),
            Rect.fromLTWH(
              size.width * .39,
              size.height * .03,
              size.width * .22,
              size.height * .25,
            ),
          ];
    return ResolvedScene(
      nodes: _nodesFromPattern(
        items,
        rects,
        viewport: size,
        depths: const [.9, .8, .4, .35],
      ),
      primaryAxis: Axis.vertical,
      contentExtent: size.height,
    );
  }

  static ResolvedScene _collage(List<GalleryPlacement> items, Size size) {
    final portrait = size.height >= size.width;
    final rects = portrait
        ? <Rect>[
            Rect.fromLTWH(
              size.width * .23,
              size.height * .18,
              size.width * .67,
              size.height * .44,
            ),
            Rect.fromLTWH(
              size.width * .06,
              size.height * .10,
              size.width * .48,
              size.height * .28,
            ),
            Rect.fromLTWH(
              size.width * .08,
              size.height * .53,
              size.width * .56,
              size.height * .31,
            ),
            Rect.fromLTWH(
              size.width * .55,
              size.height * .59,
              size.width * .38,
              size.height * .24,
            ),
          ]
        : <Rect>[
            Rect.fromLTWH(
              size.width * .31,
              size.height * .12,
              size.width * .48,
              size.height * .69,
            ),
            Rect.fromLTWH(
              size.width * .07,
              size.height * .08,
              size.width * .40,
              size.height * .46,
            ),
            Rect.fromLTWH(
              size.width * .12,
              size.height * .51,
              size.width * .42,
              size.height * .39,
            ),
            Rect.fromLTWH(
              size.width * .68,
              size.height * .54,
              size.width * .28,
              size.height * .34,
            ),
          ];
    return ResolvedScene(
      nodes: _nodesFromPattern(
        items,
        rects,
        viewport: size,
        depths: const [.95, .35, .62, .78],
        rotations: const [.018, -.052, -.018, .045],
      ),
      primaryAxis: Axis.vertical,
      contentExtent: size.height,
    );
  }

  static ResolvedScene _storyPath(List<GalleryPlacement> items, Size size) {
    final axis = NarrativeAxis.fromViewport(size);
    final primaryAxis = switch (axis) {
      NarrativeAxis.vertical => Axis.vertical,
      NarrativeAxis.horizontal => Axis.horizontal,
    };
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return ResolvedScene(
        nodes: const [],
        primaryAxis: primaryAxis,
        contentExtent: 0,
      );
    }

    final portrait = axis == NarrativeAxis.vertical;
    final primarySize = axis.primaryExtent(size);
    final crossSize = axis.crossExtent(size);
    final crossFractions = portrait
        ? const [.35, .64, .40, .68]
        : const [.37, .62, .43, .66];
    const depths = [.42, 1.0, .72, .56];
    const rotations = [-.035, .022, -.018, .038];
    final nodes = <SceneNode>[];
    var cursor = primarySize * .10;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final scale = _sizeScale(item.size);
      final width = size.width * (portrait ? .58 : .34) * scale;
      final height = size.height * (portrait ? .29 : .64) * scale;
      final nodeSize = Size(width, height);
      final crossNodeExtent = axis.crossExtent(nodeSize);
      final desiredCrossStart =
          crossSize * crossFractions[index % crossFractions.length] -
          crossNodeExtent / 2;
      final crossStart = math
          .min(math.max(desiredCrossStart, 8), crossSize - crossNodeExtent - 8)
          .toDouble();
      final rect = axis.shiftPrimary(
        portrait
            ? Rect.fromLTWH(crossStart, 0, width, height)
            : Rect.fromLTWH(0, crossStart, width, height),
        cursor,
      );
      nodes.add(
        _applyManualTransform(
          item: item,
          viewport: size,
          node: SceneNode(
            placementId: item.id,
            rect: rect,
            depth: depths[index % depths.length],
            rotation: rotations[index % rotations.length],
          ),
        ),
      );
      final primaryEnd = axis.primaryOffset(rect.bottomRight);
      cursor = primaryEnd + 24.000001;
      if (cursor - primaryEnd < 24) {
        cursor += 1e-9;
      }
    }

    return ResolvedScene(
      nodes: nodes,
      primaryAxis: primaryAxis,
      contentExtent: math.max(primarySize, cursor + primarySize * .10),
    );
  }

  static ResolvedScene _orbit(List<GalleryPlacement> items, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return const ResolvedScene(
        nodes: [],
        primaryAxis: Axis.vertical,
        contentExtent: 0,
      );
    }
    if (items.isEmpty) {
      return ResolvedScene(
        nodes: const [],
        primaryAxis: Axis.vertical,
        contentExtent: size.height,
      );
    }

    final portrait = size.height >= size.width;
    final center = Offset(size.width * .5, size.height * .49);
    final planeRotation = orbitPlaneRotation(size);
    final nodes = <SceneNode>[];
    final occupiedOrbitSlots = <_OrbitSlot>[];
    final crowding = math.max(0, items.length - 4);
    final heroDensity = (1 - crowding * .025).clamp(.68, 1.0);
    final satelliteDensity = (1 - crowding * .014).clamp(.80, 1.0);

    final heroScale = _sizeScale(items.first.size);
    final heroSize = Size(
      size.width * (portrait ? .44 : .30) * heroScale * heroDensity,
      size.height * (portrait ? .18 : .44) * heroScale * heroDensity,
    );
    nodes.add(
      _applyManualTransform(
        item: items.first,
        viewport: size,
        node: SceneNode(
          placementId: items.first.id,
          rect: Rect.fromCenter(
            center: center,
            width: heroSize.width,
            height: heroSize.height,
          ),
          depth: 1,
        ),
      ),
    );

    const innerSlots = 6;
    final satelliteCount = items.length - 1;
    final innerCount = math.min(innerSlots, satelliteCount);
    final outerCount = math.max(0, satelliteCount - innerSlots);
    final orbitSeed = items.map((item) => item.id).join('|');
    final innerPhase =
        -math.pi / 2 + _stableUnit('inner:$orbitSeed') * math.pi * 2;
    final outerSpacing = outerCount == 0 ? 0.0 : math.pi * 2 / outerCount;
    final outerPhase =
        innerPhase +
        outerSpacing / 2 +
        (_stableUnit('outer:$orbitSeed') - .5) * outerSpacing * .28;
    for (var index = 1; index < items.length; index++) {
      final item = items[index];
      final satelliteIndex = index - 1;
      final outerRing = satelliteIndex >= innerSlots;
      final slot = outerRing ? satelliteIndex - innerSlots : satelliteIndex;
      final slots = outerRing ? outerCount : innerCount;
      final spacing = math.pi * 2 / slots;
      final jitter = (_stableUnit('orbit:${item.id}') - .5) * spacing * .26;
      final seededAngle =
          (outerRing ? outerPhase : innerPhase) + spacing * slot + jitter;
      final radii = orbitRadii(size, outer: outerRing);
      final radiusX = radii.width;
      final radiusY = radii.height;
      final scale =
          _sizeScale(item.size) * satelliteDensity * (outerRing ? .72 : 1);
      var nodeSize = Size(
        size.width * (portrait ? .25 : .17) * scale,
        size.height * (portrait ? .15 : .28) * scale,
      );
      var angle = seededAngle;
      if (outerRing) {
        final goldenAngle = math.pi * (3 - math.sqrt(5));
        var placed = false;
        for (var shrink = 0; shrink < 8 && !placed; shrink++) {
          for (var attempt = 0; attempt < 72; attempt++) {
            angle = seededAngle + goldenAngle * attempt;
            if (!_orbitSlotCollides(
              center: center,
              angle: angle,
              radiusX: radiusX,
              radiusY: radiusY,
              nodeSize: nodeSize,
              occupied: occupiedOrbitSlots,
              planeRotation: planeRotation,
            )) {
              placed = true;
              break;
            }
          }
          if (!placed) {
            nodeSize = Size(nodeSize.width * .82, nodeSize.height * .82);
          }
        }
      }
      occupiedOrbitSlots.add(
        _OrbitSlot(
          angle: angle,
          radiusX: radiusX,
          radiusY: radiusY,
          nodeSize: nodeSize,
        ),
      );
      final rawCenter = orbitPoint(
        center: center,
        radiusX: radiusX,
        radiusY: radiusY,
        angle: angle,
        planeRotation: planeRotation,
      );
      final margin = outerRing ? 5.0 : 8.0;
      final nodeCenter = Offset(
        rawCenter.dx.clamp(
          nodeSize.width / 2 + margin,
          size.width - nodeSize.width / 2 - margin,
        ),
        rawCenter.dy.clamp(
          nodeSize.height / 2 + margin,
          size.height - nodeSize.height / 2 - margin,
        ),
      );
      final rotationPattern = outerRing
          ? const [-.055, .035, -.025, .05, -.04]
          : const [-.045, .025, .05, -.03, .035, -.055];
      final depthPattern = outerRing
          ? const [.28, .38, .32, .44, .35]
          : const [.58, .76, .48, .68, .54, .82];
      nodes.add(
        _applyManualTransform(
          item: item,
          viewport: size,
          node: SceneNode(
            placementId: item.id,
            rect: Rect.fromCenter(
              center: nodeCenter,
              width: nodeSize.width,
              height: nodeSize.height,
            ),
            depth: depthPattern[slot % depthPattern.length],
            rotation: rotationPattern[slot % rotationPattern.length],
          ),
        ),
      );
    }

    return ResolvedScene(
      nodes: nodes,
      primaryAxis: Axis.vertical,
      contentExtent: size.height,
    );
  }

  static List<SceneNode> _nodesFromPattern(
    List<GalleryPlacement> items,
    List<Rect> pattern, {
    required Size viewport,
    required List<double> depths,
    List<double>? rotations,
  }) {
    return [
      for (var index = 0; index < items.length; index++)
        _applyManualTransform(
          item: items[index],
          viewport: viewport,
          node: SceneNode(
            placementId: items[index].id,
            rect: _scaleAroundCenter(
              pattern[index % pattern.length].shift(
                Offset(
                  0,
                  index < pattern.length ? 0 : 18.0 * (index ~/ pattern.length),
                ),
              ),
              items[index].size,
            ),
            depth: depths[index % depths.length],
            rotation: rotations?[index % rotations.length] ?? 0,
          ),
        ),
    ];
  }

  static double _sizeScale(GallerySize size) => switch (size) {
    GallerySize.small => .76,
    GallerySize.medium => .88,
    GallerySize.large => 1,
  };

  static double _stableUnit(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash / 0xFFFFFFFF;
  }

  static bool _orbitSlotCollides({
    required Offset center,
    required double angle,
    required double radiusX,
    required double radiusY,
    required Size nodeSize,
    required List<_OrbitSlot> occupied,
    required double planeRotation,
  }) {
    for (var sample = 0; sample < 72; sample++) {
      final phase = math.pi * 2 * sample / 72;
      final candidate = _orbitSlotRect(
        center: center,
        angle: angle + phase,
        radiusX: radiusX,
        radiusY: radiusY,
        nodeSize: nodeSize,
        planeRotation: planeRotation,
      );
      for (final slot in occupied) {
        final existing = _orbitSlotRect(
          center: center,
          angle: slot.angle + phase,
          radiusX: slot.radiusX,
          radiusY: slot.radiusY,
          nodeSize: slot.nodeSize,
          planeRotation: planeRotation,
        );
        if (_overlapRatio(candidate, existing) > .60) return true;
      }
    }
    return false;
  }

  static double _overlapRatio(Rect first, Rect second) {
    if (!first.overlaps(second)) return 0;
    final overlap = first.intersect(second);
    final overlapArea = overlap.width * overlap.height;
    final smallerArea = math.min(
      first.width * first.height,
      second.width * second.height,
    );
    return smallerArea <= 0 ? 0 : overlapArea / smallerArea;
  }

  static Rect _orbitSlotRect({
    required Offset center,
    required double angle,
    required double radiusX,
    required double radiusY,
    required Size nodeSize,
    required double planeRotation,
  }) {
    return Rect.fromCenter(
      center: orbitPoint(
        center: center,
        radiusX: radiusX,
        radiusY: radiusY,
        angle: angle,
        planeRotation: planeRotation,
      ),
      width: nodeSize.width,
      height: nodeSize.height,
    );
  }

  static Rect _scaleAroundCenter(Rect rect, GallerySize size) {
    final scale = _sizeScale(size);
    return Rect.fromCenter(
      center: rect.center,
      width: rect.width * scale,
      height: rect.height * scale,
    );
  }

  static SceneNode _applyManualTransform({
    required GalleryPlacement item,
    required Size viewport,
    required SceneNode node,
  }) {
    final scaled = Rect.fromCenter(
      center: node.rect.center,
      width: node.rect.width * item.scale.clamp(.45, 1.9),
      height: node.rect.height * item.scale.clamp(.45, 1.9),
    );
    return SceneNode(
      placementId: node.placementId,
      rect: scaled.shift(
        Offset(item.offsetX * viewport.width, item.offsetY * viewport.height),
      ),
      depth: node.depth,
      rotation: node.rotation,
    );
  }
}

class _OrbitSlot {
  const _OrbitSlot({
    required this.angle,
    required this.radiusX,
    required this.radiusY,
    required this.nodeSize,
  });

  final double angle;
  final double radiusX;
  final double radiusY;
  final Size nodeSize;
}

class ResolvedScene {
  const ResolvedScene({
    required this.nodes,
    required this.primaryAxis,
    required this.contentExtent,
  });

  final List<SceneNode> nodes;
  final Axis primaryAxis;
  final double contentExtent;
}

class SceneNode {
  const SceneNode({
    required this.placementId,
    required this.rect,
    required this.depth,
    this.rotation = 0,
  });

  final String placementId;
  final Rect rect;
  final double depth;
  final double rotation;
}
