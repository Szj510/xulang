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

  Stream<List<GalleryCategoryInfo>> watchCategories() =>
      database.watchCategories();

  Stream<AppSettings> watchAppSettings() => database.watchAppSettings();

  Future<void> saveAppSettings(AppSettings settings) =>
      database.saveAppSettings(settings);

  Future<void> createCategory({
    required String id,
    required String title,
    required int sortOrder,
    required DateTime now,
  }) {
    return database.upsertCategory(
      GalleryCategoryInfo(
        id: id,
        title: title,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> renameCategory({
    required GalleryCategoryInfo category,
    required String title,
    required DateTime now,
  }) {
    return database.upsertCategory(
      GalleryCategoryInfo(
        id: category.id,
        title: title,
        sortOrder: category.sortOrder,
        createdAt: category.createdAt,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteCategory(String id) => database.deleteCategory(id);

  Future<void> moveExhibitionToCategory({
    required String exhibitionId,
    required String? categoryId,
    required DateTime now,
  }) {
    return database.moveExhibitionToCategory(exhibitionId, categoryId, now);
  }

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
    String? categoryId,
  }) async {
    final document = GalleryDocument.create(
      id: id,
      title: title,
      createdAt: now,
    );
    final categorized = document.copyWith(categoryId: categoryId);
    await database.saveDocument(categorized, const []);
    return GalleryBundle(document: categorized, media: const []);
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
    String? copiedCanvasBackgroundPath;
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
        final recordedChapter = chapter.recordCurrentLayoutState();
        final placementIdMap = <String, String>{};
        for (final placement in recordedChapter.placements) {
          placementIdMap[placement.id] = createId();
        }
        for (final state in recordedChapter.layoutStates.values) {
          for (final placement in state.placements) {
            placementIdMap.putIfAbsent(placement.id, createId);
          }
        }

        GalleryPlacement remapPlacement(GalleryPlacement placement) {
          return GalleryPlacement(
            id: placementIdMap[placement.id]!,
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
            frameCaption: placement.frameCaption,
          );
        }

        CustomPathConnection remapConnection(CustomPathConnection connection) {
          return connection.copyWith(
            fromPlacementId:
                placementIdMap[connection.fromPlacementId] ??
                connection.fromPlacementId,
            toPlacementId:
                placementIdMap[connection.toPlacementId] ??
                connection.toPlacementId,
          );
        }

        copiedChapters.add(
          GalleryChapter(
            id: newChapterId,
            title: recordedChapter.title,
            caption: recordedChapter.caption,
            order: recordedChapter.order,
            layout: recordedChapter.layout,
            motion: recordedChapter.motion,
            pathStyle: recordedChapter.pathStyle,
            placements: [
              for (final placement in recordedChapter.placements)
                remapPlacement(placement),
            ],
            customPathAnchors: recordedChapter.customPathAnchors,
            customPathConnections: [
              for (final connection in recordedChapter.customPathConnections)
                remapConnection(connection),
            ],
            stickers: recordedChapter.stickers,
            layoutStates: {
              for (final entry in recordedChapter.layoutStates.entries)
                entry.key: GalleryLayoutState(
                  placements: [
                    for (final placement in entry.value.placements)
                      remapPlacement(placement),
                  ],
                  pathStyle: entry.value.pathStyle,
                  customPathAnchors: entry.value.customPathAnchors,
                  customPathConnections: [
                    for (final connection in entry.value.customPathConnections)
                      remapConnection(connection),
                  ],
                  stickers: entry.value.stickers,
                ),
            },
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
      final canvasPath = source.document.canvasBackgroundPath;
      if (canvasPath != null && canvasPath.startsWith('asset://')) {
        copiedCanvasBackgroundPath = canvasPath;
      } else if (canvasPath != null && await File(canvasPath).exists()) {
        final canvasDirectory = Directory(
          p.join(destinationRoot.path, 'canvas'),
        );
        await canvasDirectory.create(recursive: true);
        copiedCanvasBackgroundPath = (await File(
          canvasPath,
        ).copy(p.join(canvasDirectory.path, p.basename(canvasPath)))).path;
      }
      final copiedDocument = GalleryDocument(
        id: newId,
        title: '${source.document.title} 副本',
        coverMediaId: source.document.coverMediaId == null
            ? null
            : mediaIdMap[source.document.coverMediaId!],
        categoryId: source.document.categoryId,
        theme: source.document.theme,
        canvasBackgroundPath: copiedCanvasBackgroundPath,
        canvasBackgroundOpacity: source.document.canvasBackgroundOpacity,
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

  Future<MediaCleanupResult> cleanupUnusedAppPrivateMedia() async {
    final summaries = await watchExhibitions().first;
    final referencedMediaIds = <String>{};
    final mediaById = <String, GalleryMedia>{};
    for (final summary in summaries) {
      final bundle = await load(summary.id);
      if (bundle == null) continue;
      for (final chapter in bundle.document.chapters) {
        for (final placement in chapter.placements) {
          referencedMediaIds.add(placement.mediaId);
        }
      }
      for (final item in bundle.media) {
        mediaById[item.id] = item;
      }
    }

    var deletedFiles = 0;
    var deletedBytes = 0;
    for (final media in mediaById.values) {
      if (referencedMediaIds.contains(media.id)) continue;
      for (final path in {media.originalPath, media.thumbnailPath}) {
        if (!_isAppPrivatePath(path, mediaRoot)) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final length = await file.length();
        await file.delete();
        deletedFiles += 1;
        deletedBytes += length;
      }
    }
    await _deleteEmptyDirectories(mediaRoot, mediaRoot);
    return MediaCleanupResult(
      deletedFileCount: deletedFiles,
      deletedBytes: deletedBytes,
    );
  }
}

class MediaCleanupResult {
  const MediaCleanupResult({
    required this.deletedFileCount,
    required this.deletedBytes,
  });

  final int deletedFileCount;
  final int deletedBytes;
}

bool _isAppPrivatePath(String path, Directory mediaRoot) {
  if (path.startsWith('asset://') || path.startsWith('content://')) {
    return false;
  }
  final root = p.normalize(mediaRoot.absolute.path);
  final target = p.normalize(File(path).absolute.path);
  return p.isWithin(root, target) || target == root;
}

Future<void> _deleteEmptyDirectories(
  Directory directory,
  Directory root,
) async {
  if (!await directory.exists()) return;
  final children = await directory.list(followLinks: false).toList();
  for (final child in children.whereType<Directory>()) {
    await _deleteEmptyDirectories(child, root);
  }
  if (p.equals(
    p.normalize(directory.absolute.path),
    p.normalize(root.absolute.path),
  )) {
    return;
  }
  final remaining = await directory.list(followLinks: false).isEmpty;
  if (remaining) {
    try {
      await directory.delete();
    } catch (_) {
      // Ignore directories that become non-empty during cleanup.
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
