import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_track_resolver.dart';

void main() {
  const placements = [
    GalleryPlacement(id: 'p1', mediaId: 'm1', order: 0),
    GalleryPlacement(id: 'p2', mediaId: 'm2', order: 1),
    GalleryPlacement(id: 'p3', mediaId: 'm3', order: 2),
    GalleryPlacement(id: 'p4', mediaId: 'm4', order: 3),
  ];

  GalleryChapter chapter(GalleryLayout layout) => GalleryChapter(
    id: 'chapter',
    title: '夏日散步',
    order: 0,
    layout: layout,
    motion: GalleryMotion.push,
    placements: placements,
  );

  test('three neighboring photos remain visible between focal points', () {
    final track = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: const Size(390, 844),
    );

    final frame = track.resolve(.5);

    expect(
      frame.nodes.where((node) => node.opacity > .05),
      hasLength(greaterThanOrEqualTo(3)),
    );
  });

  test('story path starts as an overview with every photo visible', () {
    final track = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: const Size(390, 844),
    );

    final overview = track.resolve(0);

    expect(
      overview.nodes.where((node) => node.opacity > .20),
      hasLength(placements.length),
    );
  });

  test('progress is clamped to the track boundaries', () {
    final track = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.hero),
      viewport: const Size(390, 844),
    );

    expect(track.resolve(-1), track.resolve(0));
    expect(track.resolve(2), track.resolve(1));
  });

  test('resolver is deterministic and preserves story order on rotation', () {
    final portrait = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: const Size(390, 844),
    );
    final portraitAgain = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: const Size(390, 844),
    );
    final landscape = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath),
      viewport: const Size(844, 390),
    );

    expect(portrait.keyframes, portraitAgain.keyframes);
    expect(
      landscape.keyframes.map((keyframe) => keyframe.placementId),
      portrait.keyframes.map((keyframe) => keyframe.placementId),
    );
    expect(portrait.resolve(.5), portraitAgain.resolve(.5));
    expect(portrait.resolve(.5).hashCode, portraitAgain.resolve(.5).hashCode);
    expect(portrait.keyframes.first.focusProgress, greaterThan(0));
    expect(portrait.keyframes.last.focusProgress, lessThan(1));
  });

  test('empty zero-sized story track resolves without invalid values', () {
    final track = NarrativeTrackResolver.resolve(
      chapter: chapter(GalleryLayout.storyPath).copyWith(placements: const []),
      viewport: Size.zero,
    );

    final frame = track.resolve(.5);

    expect(track.axis, NarrativeAxis.vertical);
    expect(track.viewport, Size.zero);
    expect(track.contentExtent, 0);
    expect(track.sharedCamera, isTrue);
    expect(frame.nodes, isEmpty);
    expect(frame.path.anchors, isEmpty);
    expect(frame.path.segments, isEmpty);
  });

  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    test('story nodes never reverse placement order in $viewport', () {
      final track = NarrativeTrackResolver.resolve(
        chapter: chapter(GalleryLayout.storyPath),
        viewport: viewport,
      );
      final axis = NarrativeAxis.fromViewport(viewport);

      for (final progress in const [0.0, .2, .5, .8, 1.0]) {
        final frame = track.resolve(progress);
        final primaryCenters = frame.nodes
            .map((node) => axis.primaryOffset(node.rect.center))
            .toList();

        for (var index = 1; index < primaryCenters.length; index++) {
          expect(
            primaryCenters[index],
            greaterThan(primaryCenters[index - 1]),
            reason: 'progress=$progress, nodes=${frame.nodes}',
          );
        }
      }
    });

    test(
      'story frame exposes its axis and ordered visible path in $viewport',
      () {
        final track = NarrativeTrackResolver.resolve(
          chapter: chapter(GalleryLayout.storyPath),
          viewport: viewport,
        );

        for (final progress in const [0.0, .2, .5, .8, 1.0]) {
          final frame = track.resolve(progress);
          final visibleIds = frame.nodes
              .where(
                (node) =>
                    node.opacity > .05 &&
                    node.rect.overlaps((Offset.zero & viewport).inflate(96)),
              )
              .map((node) => node.placementId)
              .toList();

          expect(frame.axis, NarrativeAxis.fromViewport(viewport));
          expect(
            frame.path.anchors.map((anchor) => anchor.placementId),
            visibleIds,
          );
          expect(
            frame.path.segments.length,
            lessThanOrEqualTo(frame.nodes.length - 1),
          );
        }
      },
    );
  }
}
