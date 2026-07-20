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

    test('new exhibition starts without a custom canvas image', () {
      final createdAt = DateTime.utc(2026, 6, 22);

      final document = GalleryDocument.create(
        id: 'exhibition-1',
        title: '山海之间',
        createdAt: createdAt,
      );

      expect(document.canvasBackgroundPath, isNull);
      expect(document.canvasBackgroundOpacity, 0.32);
    });

    test('custom canvas image settings can be updated and cleared', () {
      final createdAt = DateTime.utc(2026, 6, 22);
      final document = GalleryDocument.create(
        id: 'exhibition-1',
        title: '山海之间',
        createdAt: createdAt,
      );

      final withCanvas = document.copyWith(
        canvasBackgroundPath: '/canvas/night.png',
        canvasBackgroundOpacity: 0.7,
      );
      final cleared = withCanvas.copyWith(canvasBackgroundPath: null);

      expect(withCanvas.canvasBackgroundPath, '/canvas/night.png');
      expect(withCanvas.canvasBackgroundOpacity, 0.7);
      expect(cleared.canvasBackgroundPath, isNull);
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

    test('text decorations round-trip without affecting legacy stickers', () {
      const text = GallerySticker(
        id: 'text-1',
        kind: GalleryStickerKind.text,
        x: .42,
        y: .64,
        scale: 1.3,
        rotation: .2,
        text: '山海之间',
        textFont: GalleryTextFont.brush,
        textColor: 0xFF6F442A,
      );

      expect(GallerySticker.fromJson(text.toJson()), text);

      final legacy = GallerySticker.fromJson({
        'id': 'legacy-star',
        'kind': 'star',
        'x': .5,
        'y': .5,
      });
      expect(legacy.kind, GalleryStickerKind.star);
      expect(legacy.text, isEmpty);
      expect(legacy.textFont, GalleryTextFont.handwriting);
    });

    test('story note and frame caption remain independent', () {
      const placement = GalleryPlacement(
        id: 'photo',
        mediaId: 'media',
        order: 0,
        caption: '01 湖畔',
        frameCaption: '风从湖面吹来',
      );

      final updated = placement.copyWith(frameCaption: '潮声仍在');

      expect(updated.caption, '01 湖畔');
      expect(updated.frameCaption, '潮声仍在');
    });
  });
}
