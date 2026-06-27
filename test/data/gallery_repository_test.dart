import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  late GalleryDatabase database;
  late Directory mediaRoot;

  setUp(() async {
    database = GalleryDatabase.forTesting(NativeDatabase.memory());
    mediaRoot = await Directory.systemTemp.createTemp('xulang-repository-');
  });

  tearDown(() async {
    await database.close();
    if (await mediaRoot.exists()) await mediaRoot.delete(recursive: true);
  });

  test('duplicate creates an independently deletable media copy', () async {
    final sourceDirectory = Directory(
      p.join(mediaRoot.path, 'source', 'media-1'),
    );
    await sourceDirectory.create(recursive: true);
    final original = File(p.join(sourceDirectory.path, 'original.jpg'));
    final thumbnail = File(p.join(sourceDirectory.path, 'thumbnail.webp'));
    await original.writeAsBytes([1, 2, 3]);
    await thumbnail.writeAsBytes([4, 5]);
    final document = GalleryDocument(
      id: 'source',
      title: '山海之间',
      coverMediaId: 'media-1',
      createdAt: DateTime.utc(2026, 6, 22),
      updatedAt: DateTime.utc(2026, 6, 22),
      chapters: const [
        GalleryChapter(
          id: 'chapter-1',
          title: '启程',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [
            GalleryPlacement(id: 'placement-1', mediaId: 'media-1', order: 0),
          ],
        ),
      ],
    );
    final media = GalleryMedia(
      id: 'media-1',
      originalPath: original.path,
      thumbnailPath: thumbnail.path,
      width: 100,
      height: 80,
      contentHash: 'hash',
    );
    await database.saveDocument(document, [media]);
    final ids = ['media-copy', 'chapter-copy', 'placement-copy'].iterator;
    String nextId() {
      ids.moveNext();
      return ids.current;
    }

    final repository = GalleryRepository(
      database: database,
      mediaRoot: mediaRoot,
      createId: nextId,
    );

    final duplicate = await repository.duplicateExhibition(
      sourceId: 'source',
      newId: 'copy',
      now: DateTime.utc(2026, 6, 23),
    );

    expect(duplicate.document.title, '山海之间 副本');
    expect(duplicate.document.coverMediaId, 'media-copy');
    expect(duplicate.document.chapters.single.id, 'chapter-copy');
    expect(
      duplicate.document.chapters.single.placements.single.mediaId,
      'media-copy',
    );
    expect(await File(duplicate.media.single.originalPath).exists(), isTrue);

    await repository.deleteExhibition('source');
    expect(await File(duplicate.media.single.originalPath).exists(), isTrue);
    expect(await repository.load('copy'), isNotNull);
  });

  test('duplicate keeps bundled sample asset media paths reusable', () async {
    const assetPath = 'asset://assets/sample/coast-sunset.png';
    final document = GalleryDocument(
      id: 'sample-source',
      title: '官方示例',
      coverMediaId: 'sample-media',
      createdAt: DateTime.utc(2026, 6, 24),
      updatedAt: DateTime.utc(2026, 6, 24),
      chapters: const [
        GalleryChapter(
          id: 'sample-chapter',
          title: '潮汐',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [
            GalleryPlacement(
              id: 'sample-placement',
              mediaId: 'sample-media',
              order: 0,
            ),
          ],
        ),
      ],
    );
    const media = GalleryMedia(
      id: 'sample-media',
      originalPath: assetPath,
      thumbnailPath: assetPath,
      width: 1536,
      height: 1024,
      contentHash: 'sample-coast',
    );
    await database.saveDocument(document, [media]);
    final ids = ['asset-media-copy', 'asset-chapter-copy', 'asset-placement-copy']
        .iterator;
    String nextId() {
      ids.moveNext();
      return ids.current;
    }

    final repository = GalleryRepository(
      database: database,
      mediaRoot: mediaRoot,
      createId: nextId,
    );

    final duplicate = await repository.duplicateExhibition(
      sourceId: 'sample-source',
      newId: 'sample-copy',
      now: DateTime.utc(2026, 6, 25),
    );

    expect(duplicate.document.coverMediaId, 'asset-media-copy');
    expect(duplicate.media.single.originalPath, assetPath);
    expect(duplicate.media.single.thumbnailPath, assetPath);
    expect(
      duplicate.document.chapters.single.placements.single.mediaId,
      'asset-media-copy',
    );
  });
}
