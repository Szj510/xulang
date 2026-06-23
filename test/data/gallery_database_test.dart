import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  late GalleryDatabase database;

  setUp(() {
    database = GalleryDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and restores a complete exhibition document', () async {
    final createdAt = DateTime.utc(2026, 6, 22);
    final document = GalleryDocument(
      id: 'exhibition-1',
      title: '山海之间',
      theme: GalleryTheme.paper,
      coverMediaId: 'media-1',
      musicPath: '/music/theme.mp3',
      musicTitle: 'theme.mp3',
      showChapterTitleInPlayback: false,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 3)),
      chapters: const [
        GalleryChapter(
          id: 'chapter-1',
          title: '启程',
          caption: '风从海面吹来。',
          order: 0,
          layout: GalleryLayout.collage,
          motion: GalleryMotion.unfold,
          pathStyle: StoryPathStyle.glow,
          placements: [
            GalleryPlacement(
              id: 'placement-1',
              mediaId: 'media-1',
              order: 0,
              size: GallerySize.large,
              frame: GalleryFrame.stamp,
              focalX: 0.4,
              focalY: 0.7,
              zoom: 1.2,
              scale: 1.35,
              offsetX: 0.12,
              offsetY: -0.08,
              caption: '抵达海边',
            ),
          ],
        ),
      ],
    );
    const media = GalleryMedia(
      id: 'media-1',
      originalPath: '/media/original.jpg',
      thumbnailPath: '/media/thumb.webp',
      width: 4032,
      height: 3024,
      contentHash: 'abc123',
    );

    await database.saveDocument(document, const [media]);
    final restored = await database.loadDocument('exhibition-1');
    final restoredMedia = await database.loadMedia('exhibition-1');

    expect(restored, isNotNull);
    expect(restored!.title, '山海之间');
    expect(restored.theme, GalleryTheme.paper);
    expect(restored.musicPath, '/music/theme.mp3');
    expect(restored.musicTitle, 'theme.mp3');
    expect(restored.showChapterTitleInPlayback, isFalse);
    expect(restored.chapters.single.layout, GalleryLayout.collage);
    expect(restored.chapters.single.pathStyle, StoryPathStyle.glow);
    expect(
      restored.chapters.single.placements.single.frame,
      GalleryFrame.stamp,
    );
    expect(restored.chapters.single.placements.single.focalY, 0.7);
    expect(restored.chapters.single.placements.single.scale, 1.35);
    expect(restored.chapters.single.placements.single.offsetX, 0.12);
    expect(restored.chapters.single.placements.single.offsetY, -0.08);
    expect(restoredMedia.single.contentHash, 'abc123');
  });

  test('deleting an exhibition cascades to its story records', () async {
    final document = GalleryDocument.create(
      id: 'exhibition-1',
      title: '短暂展览',
      createdAt: DateTime.utc(2026, 6, 22),
    );
    await database.saveDocument(document, const []);

    await database.deleteExhibition('exhibition-1');

    expect(await database.loadDocument('exhibition-1'), isNull);
    expect(await database.loadMedia('exhibition-1'), isEmpty);
  });

  test('persists the story path layout by stable name', () async {
    final document = GalleryDocument.create(
      id: 'story-path-exhibition',
      title: '夏日散步',
      createdAt: DateTime.utc(2026, 6, 22),
    );
    final storyDocument = document.copyWith(
      chapters: [
        document.chapters.single.copyWith(layout: GalleryLayout.storyPath),
      ],
    );

    await database.saveDocument(storyDocument, const []);
    final restored = await database.loadDocument(storyDocument.id);

    expect(restored!.chapters.single.layout, GalleryLayout.storyPath);
  });
}
