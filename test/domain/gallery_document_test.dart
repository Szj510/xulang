import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  group('GalleryDocument', () {
    test('new exhibition starts with one editable chapter', () {
      final createdAt = DateTime.utc(2026, 6, 22);

      final document = GalleryDocument.create(
        id: 'exhibition-1',
        title: '山海之间',
        createdAt: createdAt,
      );

      expect(document.title, '山海之间');
      expect(document.chapters, hasLength(1));
      expect(document.chapters.single.title, '第一章');
      expect(document.chapters.single.layout, GalleryLayout.hero);
      expect(document.updatedAt, createdAt);
    });

    test('moving a placement preserves a contiguous story order', () {
      final chapter = GalleryChapter(
        id: 'chapter-1',
        title: '启程',
        order: 0,
        layout: GalleryLayout.filmstrip,
        motion: GalleryMotion.pan,
        placements: const [
          GalleryPlacement(id: 'p1', mediaId: 'm1', order: 0),
          GalleryPlacement(id: 'p2', mediaId: 'm2', order: 1),
          GalleryPlacement(id: 'p3', mediaId: 'm3', order: 2),
        ],
      );

      final moved = chapter.movePlacement(0, 3);

      expect(moved.placements.map((item) => item.id), ['p2', 'p3', 'p1']);
      expect(moved.placements.map((item) => item.order), [0, 1, 2]);
    });
  });
}
