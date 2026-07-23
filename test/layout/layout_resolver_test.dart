import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/layout_resolver.dart';

void main() {
  final placements = List.generate(
    10,
    (index) => GalleryPlacement(
      id: 'placement-$index',
      mediaId: 'media-$index',
      order: index,
    ),
  );

  GalleryChapter orbitChapter() => GalleryChapter(
    id: 'orbit',
    title: 'Orbit',
    order: 0,
    layout: GalleryLayout.orbit,
    motion: GalleryMotion.unfold,
    placements: placements,
  );

  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    test(
      'orbit keeps its hero centered and satellites in bounds in $viewport',
      () {
        final scene = LayoutResolver.resolve(
          chapter: orbitChapter(),
          viewport: viewport,
        );
        final canvas = Offset.zero & viewport;
        final hero = scene.nodes.first;

        expect(scene.nodes, hasLength(placements.length));
        expect(hero.placementId, placements.first.id);
        expect(hero.rect.center.dx, closeTo(viewport.width * .5, .001));
        expect(hero.rect.center.dy, closeTo(viewport.height * .49, .001));
        expect(hero.depth, 1);
        expect(
          scene.nodes
              .skip(1)
              .every((node) => canvas.contains(node.rect.center)),
          isTrue,
        );
        expect(
          scene.nodes
              .skip(1)
              .every(
                (node) =>
                    node.rect.center != hero.rect.center && node.depth < 1,
              ),
          isTrue,
        );
      },
    );
  }

  test('orbit moves overflow into a quieter outer ring', () {
    final scene = LayoutResolver.resolve(
      chapter: orbitChapter(),
      viewport: const Size(390, 844),
    );

    expect(scene.nodes[7].rect.width, lessThan(scene.nodes[1].rect.width));
    expect(scene.nodes[7].rect.center, isNot(scene.nodes[1].rect.center));
    expect(scene.nodes[7].depth, lessThan(scene.nodes[1].depth));
  });

  test('orbit uses stable varied positions without excessive overlap', () {
    final first = LayoutResolver.resolve(
      chapter: orbitChapter(),
      viewport: const Size(390, 844),
    );
    final again = LayoutResolver.resolve(
      chapter: orbitChapter(),
      viewport: const Size(390, 844),
    );

    expect(
      again.nodes.map((node) => node.rect.center),
      orderedEquals(first.nodes.map((node) => node.rect.center)),
    );
    final satellites = first.nodes.skip(1).toList();
    for (var left = 0; left < satellites.length; left++) {
      for (var right = left + 1; right < satellites.length; right++) {
        expect(
          _overlapRatio(satellites[left].rect, satellites[right].rect),
          lessThanOrEqualTo(.62),
          reason:
              '${satellites[left].placementId} and '
              '${satellites[right].placementId}',
        );
      }
    }
  });

  test('orbit scales every layer down as the chapter gets crowded', () {
    final sparse = LayoutResolver.resolve(
      chapter: orbitChapter().copyWith(placements: placements.take(4).toList()),
      viewport: const Size(390, 844),
    );
    final crowdedPlacements = List.generate(
      maxGalleryPlacementsPerChapter,
      (index) => GalleryPlacement(
        id: 'crowded-$index',
        mediaId: 'media-$index',
        order: index,
      ),
    );
    final crowded = LayoutResolver.resolve(
      chapter: orbitChapter().copyWith(placements: crowdedPlacements),
      viewport: const Size(390, 844),
    );

    expect(
      crowded.nodes.first.rect.width,
      lessThan(sparse.nodes.first.rect.width),
    );
    expect(crowded.nodes[1].rect.width, lessThan(sparse.nodes[1].rect.width));
  });

  test('orbit reserves caption space without shrinking the photo area', () {
    const viewport = Size(390, 844);
    final plain = LayoutResolver.resolve(
      chapter: orbitChapter().copyWith(
        placements: [
          placements.first,
          placements[1].copyWith(frame: GalleryFrame.none),
        ],
      ),
      viewport: viewport,
    );
    final captioned = LayoutResolver.resolve(
      chapter: orbitChapter().copyWith(
        placements: [
          placements.first,
          placements[1].copyWith(
            frame: GalleryFrame.captionMat,
            frameCaption: 'A caption that should not crush the photo',
          ),
        ],
      ),
      viewport: viewport,
    );

    expect(captioned.nodes[1].rect.width, plain.nodes[1].rect.width);
    expect(
      captioned.nodes[1].rect.height,
      greaterThan(plain.nodes[1].rect.height * 1.3),
    );
    expect(
      captioned.nodes[1].rect.height * .74,
      closeTo(plain.nodes[1].rect.height, .001),
    );
  });
}

double _overlapRatio(Rect first, Rect second) {
  if (!first.overlaps(second)) return 0;
  final overlap = first.intersect(second);
  final smallerArea = [
    first.width * first.height,
    second.width * second.height,
  ].reduce((a, b) => a < b ? a : b);
  return overlap.width * overlap.height / smallerArea;
}
