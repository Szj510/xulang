import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/narrative_axis.dart';

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
      GalleryLayout.depthWall => _depthWall(chapter.placements, viewport),
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

  static ResolvedScene _depthWall(List<GalleryPlacement> items, Size size) {
    final axis = NarrativeAxis.fromViewport(size);
    final primaryAxis = axis == NarrativeAxis.horizontal
        ? Axis.horizontal
        : Axis.vertical;
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
    final nodes = <SceneNode>[];
    var cursor = primarySize * .18;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final slot = index % 3;
      final group = index ~/ 3;
      final depthBase = switch (slot) {
        0 => .62,
        1 => 1.12,
        _ => .68,
      };
      final depth = (depthBase - group * .08).clamp(.35, 1.15);
      final scale = _sizeScale(item.size);
      final nodeWidth =
          size.width * (portrait ? (slot == 1 ? .46 : .45) : .30) * scale;
      final nodeHeight =
          size.height * (portrait ? (slot == 1 ? .38 : .48) : .62) * scale;
      final crossStart = portrait
          ? switch (slot) {
              0 => -nodeWidth * .22,
              1 => (crossSize - nodeWidth) / 2,
              _ => crossSize - nodeWidth * .78,
            }
          : switch (slot) {
              0 => 22.0,
              1 => (crossSize - nodeHeight) / 2,
              _ => crossSize - nodeHeight - 22,
            };
      final primaryShift = switch (slot) {
        0 => primarySize * .08,
        1 => primarySize * .16,
        _ => primarySize * .08,
      };
      final rect = axis.shiftPrimary(
        portrait
            ? Rect.fromLTWH(crossStart, 0, nodeWidth, nodeHeight)
            : Rect.fromLTWH(0, crossStart, nodeWidth, nodeHeight),
        cursor + primaryShift,
      );
      nodes.add(
        _applyManualTransform(
          item: item,
          viewport: size,
          node: SceneNode(
            placementId: item.id,
            rect: rect,
            depth: depth.clamp(0.0, 1.15),
            rotation: switch (slot) {
              0 => -.035,
              1 => 0,
              _ => .035,
            },
          ),
        ),
      );
      if (slot == 2) {
        cursor = axis.primaryOffset(rect.bottomRight) + primarySize * .18;
      }
    }

    return ResolvedScene(
      nodes: nodes,
      primaryAxis: primaryAxis,
      contentExtent: math.max(primarySize, cursor + primarySize * .18),
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
