import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';

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
      nodes: _nodesFromPattern(items, rects, depths: const [1, .45, .2, .6]),
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
        SceneNode(
          placementId: item.id,
          rect: Rect.fromLTWH(x, (size.height - height) / 2, width, height),
          depth: item.size == GallerySize.large ? 1 : .65,
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
      nodes: _nodesFromPattern(items, rects, depths: const [.9, .8, .4, .35]),
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
        depths: const [.95, .35, .62, .78],
        rotations: const [.018, -.052, -.018, .045],
      ),
      primaryAxis: Axis.vertical,
      contentExtent: size.height,
    );
  }

  static ResolvedScene _storyPath(List<GalleryPlacement> items, Size size) {
    final portrait = size.height >= size.width;
    final rects = portrait
        ? <Rect>[
            Rect.fromLTWH(
              size.width * -.03,
              size.height * .09,
              size.width * .43,
              size.height * .24,
            ),
            Rect.fromLTWH(
              size.width * .46,
              size.height * .15,
              size.width * .49,
              size.height * .34,
            ),
            Rect.fromLTWH(
              size.width * .09,
              size.height * .40,
              size.width * .52,
              size.height * .33,
            ),
            Rect.fromLTWH(
              size.width * .53,
              size.height * .63,
              size.width * .39,
              size.height * .24,
            ),
          ]
        : <Rect>[
            Rect.fromLTWH(
              size.width * .02,
              size.height * .12,
              size.width * .29,
              size.height * .55,
            ),
            Rect.fromLTWH(
              size.width * .29,
              size.height * .08,
              size.width * .34,
              size.height * .72,
            ),
            Rect.fromLTWH(
              size.width * .58,
              size.height * .24,
              size.width * .29,
              size.height * .58,
            ),
            Rect.fromLTWH(
              size.width * .78,
              size.height * .08,
              size.width * .24,
              size.height * .43,
            ),
          ];
    return ResolvedScene(
      nodes: _nodesFromPattern(
        items,
        rects,
        depths: const [.28, 1, .72, .48],
        rotations: const [-.055, .028, -.025, .065],
      ),
      primaryAxis: Axis.horizontal,
      contentExtent: size.width,
    );
  }

  static List<SceneNode> _nodesFromPattern(
    List<GalleryPlacement> items,
    List<Rect> pattern, {
    required List<double> depths,
    List<double>? rotations,
  }) {
    return [
      for (var index = 0; index < items.length; index++)
        SceneNode(
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
