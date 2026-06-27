import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/domain/gallery_document.dart';

class GalleryRepository {
  GalleryRepository({
    required this.database,
    required this.mediaRoot,
    required this.createId,
  });

  final GalleryDatabase database;
  final Directory mediaRoot;
  final String Function() createId;

  Stream<List<ExhibitionSummary>> watchExhibitions() =>
      database.watchExhibitions();

  Future<GalleryBundle?> load(String exhibitionId) async {
    final document = await database.loadDocument(exhibitionId);
    if (document == null) return null;
    return GalleryBundle(
      document: document,
      media: await database.loadMedia(exhibitionId),
    );
  }

  Future<GalleryBundle> createExhibition({
    required String id,
    required String title,
    required DateTime now,
  }) async {
    final document = GalleryDocument.create(
      id: id,
      title: title,
      createdAt: now,
    );
    await database.saveDocument(document, const []);
    return GalleryBundle(document: document, media: const []);
  }

  Future<void> save(GalleryBundle bundle) {
    return database.saveDocument(bundle.document, bundle.media);
  }

  Future<void> renameExhibition(String id, String title, DateTime now) async {
    final bundle = await load(id);
    if (bundle == null) return;
    await save(
      bundle.copyWith(
        document: bundle.document.copyWith(title: title, updatedAt: now),
      ),
    );
  }

  Future<GalleryBundle> duplicateExhibition({
    required String sourceId,
    required String newId,
    required DateTime now,
  }) async {
    final source = await load(sourceId);
    if (source == null) {
      throw StateError('找不到要复制的展览');
    }
    final destinationRoot = Directory(p.join(mediaRoot.path, newId));
    final mediaIdMap = <String, String>{};
    final copiedMedia = <GalleryMedia>[];
    String? copiedMusicPath;
    try {
      for (final media in source.media) {
        final newMediaId = createId();
        mediaIdMap[media.id] = newMediaId;
        final destination = Directory(p.join(destinationRoot.path, newMediaId));
        final originalPath = await _copyMediaPath(
          sourcePath: media.originalPath,
          destination: destination,
        );
        final thumbnailPath = await _copyMediaPath(
          sourcePath: media.thumbnailPath,
          destination: destination,
        );
        copiedMedia.add(
          GalleryMedia(
            id: newMediaId,
            originalPath: originalPath,
            thumbnailPath: thumbnailPath,
            width: media.width,
            height: media.height,
            contentHash: media.contentHash,
          ),
        );
      }

      final copiedChapters = <GalleryChapter>[];
      for (final chapter in source.document.chapters) {
        final newChapterId = createId();
        copiedChapters.add(
          GalleryChapter(
            id: newChapterId,
            title: chapter.title,
            caption: chapter.caption,
            order: chapter.order,
            layout: chapter.layout,
            motion: chapter.motion,
            pathStyle: chapter.pathStyle,
            placements: [
              for (final placement in chapter.placements)
                GalleryPlacement(
                  id: createId(),
                  mediaId: mediaIdMap[placement.mediaId]!,
                  order: placement.order,
                  size: placement.size,
                  frame: placement.frame,
                  focalX: placement.focalX,
                  focalY: placement.focalY,
                  zoom: placement.zoom,
                  scale: placement.scale,
                  offsetX: placement.offsetX,
                  offsetY: placement.offsetY,
                  rotation: placement.rotation,
                  caption: placement.caption,
                ),
            ],
          ),
        );
      }
      final musicPath = source.document.musicPath;
      if (musicPath != null && await File(musicPath).exists()) {
        final musicDirectory = Directory(p.join(destinationRoot.path, 'music'));
        await musicDirectory.create(recursive: true);
        copiedMusicPath = (await File(
          musicPath,
        ).copy(p.join(musicDirectory.path, p.basename(musicPath)))).path;
      }
      final copiedDocument = GalleryDocument(
        id: newId,
        title: '${source.document.title} 副本',
        coverMediaId: source.document.coverMediaId == null
            ? null
            : mediaIdMap[source.document.coverMediaId!],
        theme: source.document.theme,
        musicPath: copiedMusicPath,
        musicTitle: source.document.musicTitle,
        showChapterTitleInPlayback: source.document.showChapterTitleInPlayback,
        playbackDelaySeconds: source.document.playbackDelaySeconds,
        createdAt: now,
        updatedAt: now,
        chapters: copiedChapters,
      );
      final bundle = GalleryBundle(
        document: copiedDocument,
        media: copiedMedia,
      );
      await save(bundle);
      return bundle;
    } catch (_) {
      if (await destinationRoot.exists()) {
        await destinationRoot.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> deleteExhibition(String id) async {
    await database.deleteExhibition(id);
    final directory = Directory(p.join(mediaRoot.path, id));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

Future<String> _copyMediaPath({
  required String sourcePath,
  required Directory destination,
}) async {
  if (sourcePath.startsWith('asset://')) return sourcePath;
  await destination.create(recursive: true);
  final targetPath = p.join(destination.path, p.basename(sourcePath));
  await File(sourcePath).openRead().pipe(File(targetPath).openWrite());
  return targetPath;
}

class GalleryBundle {
  const GalleryBundle({required this.document, required this.media});

  final GalleryDocument document;
  final List<GalleryMedia> media;

  GalleryBundle copyWith({
    GalleryDocument? document,
    List<GalleryMedia>? media,
  }) {
    return GalleryBundle(
      document: document ?? this.document,
      media: media ?? this.media,
    );
  }
}
