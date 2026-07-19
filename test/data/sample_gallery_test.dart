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
        'sample-alley',
      );
      expect(sample.document.chapters.last.layout, GalleryLayout.storyPath);
      expect(sample.document.chapters.last.placements, hasLength(5));
      expect(
        sample.document.chapters.last.placements[1].frame,
        GalleryFrame.stamp,
      );
      expect(sample.media, hasLength(6));
      expect(
        sample.document.chapters.last.placements.map((item) => item.mediaId),
        contains('sample-portrait'),
      );
      expect(
        sample.document.chapters.last.placements.map((item) => item.caption),
        containsAll(['驶向湖畔', '山径', '海岸', '窗外日落', '草间微光']),
      );
      final mediaIds = sample.media.map((item) => item.id).toSet();
      expect(
        sample.document.chapters
            .expand((chapter) => chapter.placements)
            .every((placement) => mediaIds.contains(placement.mediaId)),
        isTrue,
      );
      expect(
        sample.media.every(
          (media) => media.originalPath.startsWith('asset://'),
        ),
        isTrue,
      );
    },
  );

  test('recognizes the obsolete sample revision for a safe refresh', () {
    final sample = buildSampleGallery(DateTime.utc(2026, 7, 20));
    final staleSample = sample.copyWith(
      media: [
        ...sample.media,
        const GalleryMedia(
          id: 'sample-friends',
          originalPath: 'asset://assets/sample/friends-lakeside.png',
          thumbnailPath: 'asset://assets/sample/friends-lakeside.png',
          width: 1536,
          height: 1024,
          contentHash: 'sample-friends',
        ),
      ],
    );

    expect(shouldRefreshBundledSample(sample), isFalse);
    expect(shouldRefreshBundledSample(staleSample), isTrue);
  });
}
