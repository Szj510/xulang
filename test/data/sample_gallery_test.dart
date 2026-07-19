import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/sample_gallery.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  test(
    'sample exhibition demonstrates corridor and story path storytelling',
    () {
      final sample = buildSampleGallery(DateTime.utc(2026, 6, 22));

      expect(sample.document.title, '山海之间（官方示例）');
      expect(sample.document.chapters, hasLength(2));
      expect(sample.document.chapters.first.layout, GalleryLayout.hero);
      expect(
        sample.document.chapters.first.placements[1].mediaId,
        'sample-portrait',
      );
      expect(sample.document.chapters.last.layout, GalleryLayout.storyPath);
      expect(sample.document.chapters.last.placements, hasLength(8));
      expect(
        sample.document.chapters.last.placements[1].frame,
        GalleryFrame.stamp,
      );
      expect(sample.media, hasLength(9));
      expect(
        sample.document.chapters.last.placements.map((item) => item.mediaId),
        containsAll([
          'sample-friends',
          'sample-notes',
          'sample-rain',
          'sample-alley',
        ]),
      );
      expect(
        sample.media.every(
          (media) => media.originalPath.startsWith('asset://'),
        ),
        isTrue,
      );
    },
  );
}
