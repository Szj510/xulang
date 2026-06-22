import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/layout_resolver.dart';

void main() {
  const placements = [
    GalleryPlacement(
      id: 'p1',
      mediaId: 'm1',
      order: 0,
      size: GallerySize.large,
    ),
    GalleryPlacement(id: 'p2', mediaId: 'm2', order: 1),
    GalleryPlacement(
      id: 'p3',
      mediaId: 'm3',
      order: 2,
      size: GallerySize.small,
    ),
    GalleryPlacement(id: 'p4', mediaId: 'm4', order: 3),
  ];
  final storyPlacements = List.generate(
    8,
    (index) => GalleryPlacement(
      id: 'story-$index',
      mediaId: 'story-media-$index',
      order: index,
      size: GallerySize.values[index % GallerySize.values.length],
    ),
  );

  GalleryChapter chapter(GalleryLayout layout) => GalleryChapter(
    id: 'chapter-1',
    title: '启程',
    order: 0,
    layout: layout,
    motion: GalleryMotion.push,
    placements: placements,
  );

  test('hero layout gives the first image narrative priority', () {
    final scene = LayoutResolver.resolve(
      chapter: chapter(GalleryLayout.hero),
      viewport: const Size(390, 844),
    );

    expect(scene.nodes, hasLength(4));
    expect(
      scene.nodes.first.rect.width,
      greaterThan(scene.nodes[1].rect.width),
    );
    expect(scene.nodes.first.depth, greaterThan(scene.nodes[1].depth));
    expect(scene.primaryAxis, Axis.vertical);
  });

  test('filmstrip resolves as a horizontal story lane', () {
    final scene = LayoutResolver.resolve(
      chapter: chapter(GalleryLayout.filmstrip),
      viewport: const Size(390, 844),
    );

    expect(scene.primaryAxis, Axis.horizontal);
    expect(scene.nodes[1].rect.left, greaterThan(scene.nodes[0].rect.left));
    expect(scene.contentExtent, greaterThan(390));
  });

  test('diptych changes composition without changing story order', () {
    final portrait = LayoutResolver.resolve(
      chapter: chapter(GalleryLayout.diptych),
      viewport: const Size(390, 844),
    );
    final landscape = LayoutResolver.resolve(
      chapter: chapter(GalleryLayout.diptych),
      viewport: const Size(844, 390),
    );

    expect(portrait.nodes.map((node) => node.placementId), [
      'p1',
      'p2',
      'p3',
      'p4',
    ]);
    expect(landscape.nodes.map((node) => node.placementId), [
      'p1',
      'p2',
      'p3',
      'p4',
    ]);
    expect(portrait.nodes.first.rect, isNot(landscape.nodes.first.rect));
  });

  test('collage adds restrained overlap and depth', () {
    final scene = LayoutResolver.resolve(
      chapter: chapter(GalleryLayout.collage),
      viewport: const Size(390, 844),
    );

    expect(scene.nodes.any((node) => node.rotation != 0), isTrue);
    expect(
      scene.nodes.map((node) => node.depth).toSet().length,
      greaterThan(1),
    );
    expect(scene.nodes[0].rect.overlaps(scene.nodes[1].rect), isTrue);
  });

  test('small medium and large change node area in every layout', () {
    for (final layout in GalleryLayout.values) {
      double areaFor(GallerySize size) {
        final resolved = LayoutResolver.resolve(
          chapter: chapter(
            layout,
          ).copyWith(placements: [placements.first.copyWith(size: size)]),
          viewport: const Size(390, 844),
        );
        final rect = resolved.nodes.single.rect;
        return rect.width * rect.height;
      }

      final small = areaFor(GallerySize.small);
      final medium = areaFor(GallerySize.medium);
      final large = areaFor(GallerySize.large);
      expect(small, lessThan(medium), reason: '${layout.name} small');
      expect(medium, lessThan(large), reason: '${layout.name} medium');
    }
  });

  test('portrait story path advances monotonically down the world', () {
    final scene = LayoutResolver.resolve(
      chapter: chapter(
        GalleryLayout.storyPath,
      ).copyWith(placements: storyPlacements),
      viewport: const Size(390, 844),
    );

    expect(scene.primaryAxis, Axis.vertical);
    for (var index = 1; index < scene.nodes.length; index++) {
      expect(
        scene.nodes[index].rect.top - scene.nodes[index - 1].rect.bottom,
        greaterThanOrEqualTo(24),
        reason: 'gap before story node $index',
      );
    }
    expect(scene.contentExtent, greaterThan(844));
  });

  test('landscape story path advances monotonically across the world', () {
    final scene = LayoutResolver.resolve(
      chapter: chapter(
        GalleryLayout.storyPath,
      ).copyWith(placements: storyPlacements),
      viewport: const Size(844, 390),
    );

    expect(scene.primaryAxis, Axis.horizontal);
    for (var index = 1; index < scene.nodes.length; index++) {
      expect(
        scene.nodes[index].rect.left - scene.nodes[index - 1].rect.right,
        greaterThanOrEqualTo(24),
        reason: 'gap before story node $index',
      );
    }
    expect(scene.contentExtent, greaterThan(844));
  });

  test('zero viewport resolves to a stable empty story scene', () {
    final scene = LayoutResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: Size.zero,
    );

    expect(scene.nodes, isEmpty);
    expect(scene.contentExtent, 0);
  });

  test('non-finite viewport resolves to a stable empty story scene', () {
    for (final viewport in const [
      Size(double.infinity, 390),
      Size(844, double.infinity),
    ]) {
      final scene = LayoutResolver.resolve(
        chapter: chapter(GalleryLayout.storyPath),
        viewport: viewport,
      );

      expect(scene.nodes, isEmpty, reason: '$viewport nodes');
      expect(scene.contentExtent, 0, reason: '$viewport extent');
    }
  });
}
