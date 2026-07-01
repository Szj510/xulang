import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/data/image_selection_service.dart';
import 'package:xulang/data/media_import_service.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/editor/editor_session.dart';
import 'package:xulang/share/exhibition_exporter.dart';

void main() {
  late GalleryDatabase database;
  late Directory mediaRoot;
  late GalleryRepository repository;
  late EditorSession session;

  setUp(() async {
    database = GalleryDatabase.forTesting(NativeDatabase.memory());
    mediaRoot = await Directory.systemTemp.createTemp('xulang-editor-');
    repository = GalleryRepository(
      database: database,
      mediaRoot: mediaRoot,
      createId: () => 'generated-id',
    );
    final now = DateTime(2026, 6, 22);
    final document = GalleryDocument(
      id: 'exhibition',
      title: '测试展览',
      createdAt: now,
      updatedAt: now,
      chapters: const [
        GalleryChapter(
          id: 'chapter',
          title: '第一章',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [
            GalleryPlacement(id: 'placement', mediaId: 'media', order: 0),
          ],
        ),
      ],
    );
    await repository.save(
      GalleryBundle(
        document: document,
        media: const [
          GalleryMedia(
            id: 'media',
            originalPath: 'missing.jpg',
            thumbnailPath: 'missing.webp',
            width: 1200,
            height: 800,
            contentHash: 'hash',
          ),
        ],
      ),
    );
    session = EditorSession(
      exhibitionId: 'exhibition',
      repository: repository,
      importer: MediaImportService(
        rootDirectory: mediaRoot,
        createId: () => 'imported-id',
      ),
      imageSelection: const _NoImages(),
    );
    await session.load();
  });

  tearDown(() async {
    session.dispose();
    await database.close();
    if (await mediaRoot.exists()) await mediaRoot.delete(recursive: true);
  });

  test('updates and clamps crop focus zoom and canvas transform', () async {
    await session.updatePlacement(
      'placement',
      focalX: 1.4,
      focalY: -0.2,
      zoom: 9,
      scale: 4,
      offsetX: .8,
      offsetY: -.8,
    );

    final placement = session.selectedChapter!.placements.single;
    expect(placement.focalX, 1);
    expect(placement.focalY, 0);
    expect(placement.zoom, 3);
    expect(placement.scale, 1.9);
    expect(placement.offsetX, .45);
    expect(placement.offsetY, -.45);
  });

  test('deletes a placement without deleting media', () async {
    final now = DateTime(2026, 7);
    final document = GalleryDocument(
      id: 'exhibition',
      title: 'Delete placement test',
      createdAt: now,
      updatedAt: now,
      chapters: const [
        GalleryChapter(
          id: 'chapter',
          title: 'Chapter',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [
            GalleryPlacement(id: 'first', mediaId: 'media', order: 0),
            GalleryPlacement(id: 'second', mediaId: 'media', order: 1),
          ],
        ),
      ],
    );
    await repository.save(
      GalleryBundle(document: document, media: session.bundle!.media),
    );
    await session.load();

    await session.deletePlacement('first');

    final chapter = session.selectedChapter!;
    expect(chapter.placements, hasLength(1));
    expect(chapter.placements.single.id, 'second');
    expect(chapter.placements.single.order, 0);
    expect(session.bundle!.media, hasLength(1));
    final persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.placements.single.id, 'second');
    expect(persisted.media, hasLength(1));
  });

  test('clears a recoverable editor error', () {
    session.error = StateError('temporary');

    session.clearError();

    expect(session.error, isNull);
  });

  test('updates and persists the exhibition scene theme', () async {
    await session.updateTheme(GalleryTheme.paper);

    expect(session.bundle!.document.theme, GalleryTheme.paper);
    final persisted = await repository.load('exhibition');
    expect(persisted!.document.theme, GalleryTheme.paper);
  });

  test('updates and clears custom story path anchors', () async {
    const anchors = [
      CustomPathAnchor(x: 0.15, y: 0.2, label: 'start'),
      CustomPathAnchor(x: 0.75, y: 0.8, label: 'end'),
    ];

    await session.updateChapterPath(anchors);

    expect(session.selectedChapter!.customPathAnchors, anchors);
    var persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.customPathAnchors, anchors);

    await session.clearCustomPath();

    expect(session.selectedChapter!.customPathAnchors, isNull);
    persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.customPathAnchors, isNull);
  });

  test('adds updates removes and clears custom path connections', () async {
    const connection = CustomPathConnection(
      id: 'connection-1',
      fromPlacementId: 'placement',
      toPlacementId: 'placement-2',
      points: [
        CustomPathPoint(x: 0.1, y: 0.2),
        CustomPathPoint(x: 0.7, y: 0.8),
      ],
      note: 'first note',
      noteX: 0.4,
      noteY: 0.5,
    );

    await session.addCustomPathConnection(connection);

    expect(session.selectedChapter!.customPathConnections, [connection]);
    var persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.customPathConnections, [
      connection,
    ]);

    final updated = connection.copyWith(note: 'updated note', noteX: 0.6);
    await session.updateCustomPathConnection(updated);

    expect(session.selectedChapter!.customPathConnections, [updated]);
    persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.customPathConnections, [
      updated,
    ]);

    await session.removeCustomPathConnection(connection.id);

    expect(session.selectedChapter!.customPathConnections, isEmpty);
    persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.customPathConnections, isEmpty);

    await session.addCustomPathConnection(connection);
    await session.clearCustomPathConnections();

    expect(session.selectedChapter!.customPathConnections, isEmpty);
    persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.customPathConnections, isEmpty);
  });

  test('imports and clears local background music', () async {
    final source = File('${mediaRoot.path}/source-track.mp3');
    await source.writeAsBytes([1, 2, 3, 4, 5]);

    await session.importBackgroundMusic(source.path);

    final document = session.bundle!.document;
    expect(document.musicTitle, 'source-track.mp3');
    expect(document.musicPath, isNotNull);
    expect(document.musicPath, isNot(source.path));
    expect(await File(document.musicPath!).readAsBytes(), [1, 2, 3, 4, 5]);

    await session.clearBackgroundMusic();

    expect(session.bundle!.document.musicPath, isNull);
    expect(session.bundle!.document.musicTitle, isNull);
  });

  test('applies imported template while preserving existing media', () async {
    final template = ExhibitionTemplateCodec().encode(
      GalleryDocument(
        id: 'template',
        title: '模板',
        createdAt: DateTime(2026, 6, 23),
        updatedAt: DateTime(2026, 6, 23),
        chapters: const [
          GalleryChapter(
            id: 'template-chapter',
            title: '木框胶片',
            order: 0,
            layout: GalleryLayout.filmstrip,
            motion: GalleryMotion.pan,
            placements: [
              GalleryPlacement(
                id: 'slot',
                mediaId: 'template-media',
                order: 0,
                frame: GalleryFrame.wood,
                size: GallerySize.large,
              ),
            ],
          ),
        ],
      ),
    );

    await session.applyTemplateJson(template);

    final chapter = session.bundle!.document.chapters.single;
    expect(chapter.title, '木框胶片');
    expect(chapter.layout, GalleryLayout.filmstrip);
    expect(chapter.placements.single.mediaId, 'media');
    expect(chapter.placements.single.frame, GalleryFrame.wood);
    final persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.layout, GalleryLayout.filmstrip);
  });

  test('renames chapters and refuses to delete the last chapter', () async {
    await session.renameChapter('Renamed chapter');

    expect(session.selectedChapter!.title, 'Renamed chapter');

    final deleted = await session.deleteChapter(0);

    expect(deleted, isFalse);
    expect(session.bundle!.document.chapters, hasLength(1));
    final persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters.single.title, 'Renamed chapter');
  });

  test('deletes a non-last chapter without deleting media assets', () async {
    await session.addChapter();
    await session.deleteChapter(0);

    expect(session.bundle!.document.chapters, hasLength(1));
    expect(session.bundle!.media.single.id, 'media');
    final persisted = await repository.load('exhibition');
    expect(persisted!.document.chapters, hasLength(1));
    expect(persisted.media.single.id, 'media');
  });
}

class _NoImages implements ImageSelectionService {
  const _NoImages();

  @override
  Future<List<String>> selectImages() async => const [];
}
