import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:xulang/domain/gallery_document.dart';

class MediaImportService {
  MediaImportService({required this.rootDirectory, required this.createId});

  final Directory rootDirectory;
  final String Function() createId;

  Future<MediaImportResult> importFiles({
    required String exhibitionId,
    required List<String> sourcePaths,
    required Iterable<GalleryMedia> existingAssets,
    MediaImportMode importMode = MediaImportMode.copyIntoApp,
  }) async {
    final byHash = {
      for (final asset in existingAssets) asset.contentHash: asset,
    };
    final selectedAssets = <String, GalleryMedia>{};
    final selectionIds = <String>[];
    final batchId = DateTime.now().microsecondsSinceEpoch.toString();
    final stagingRoot = Directory(
      p.join(rootDirectory.path, '.staging', '$exhibitionId-$batchId'),
    );
    final pending = <({GalleryMedia media, Directory directory})>[];
    final movedDirectories = <Directory>[];

    try {
      for (final sourcePath in sourcePaths) {
        final source = File(sourcePath);
        if (!await source.exists()) {
          throw MediaImportException('找不到所选图片：$sourcePath');
        }
        final shouldCopyOriginal = importMode == MediaImportMode.copyIntoApp;
        final hash = shouldCopyOriginal
            ? await _sha256(source)
            : await _referenceFingerprint(source);
        if (shouldCopyOriginal) {
          final known = byHash[hash];
          if (known != null) {
            selectedAssets[known.id] = known;
            selectionIds.add(known.id);
            continue;
          }
        }

        final assetId = createId();
        final decoded = await _decodeAndThumbnail(sourcePath);
        final assetStaging = Directory(p.join(stagingRoot.path, assetId));
        await assetStaging.create(recursive: true);
        final extension = p.extension(sourcePath).toLowerCase();
        File? original;
        if (shouldCopyOriginal) {
          original = File(
            p.join(
              assetStaging.path,
              'original${extension.isEmpty ? '.img' : extension}',
            ),
          );
          await source.openRead().pipe(original.openWrite());
        }
        final thumbnail = File(p.join(assetStaging.path, 'thumbnail.webp'));
        await thumbnail.writeAsBytes(decoded.thumbnailBytes, flush: true);

        final finalDirectory = Directory(
          p.join(rootDirectory.path, exhibitionId, assetId),
        );
        final media = GalleryMedia(
          id: assetId,
          originalPath: shouldCopyOriginal
              ? p.join(finalDirectory.path, p.basename(original!.path))
              : sourcePath,
          thumbnailPath: p.join(finalDirectory.path, 'thumbnail.webp'),
          width: decoded.width,
          height: decoded.height,
          contentHash: hash,
        );
        selectedAssets[assetId] = media;
        if (shouldCopyOriginal) {
          byHash[hash] = media;
        }
        selectionIds.add(assetId);
        pending.add((media: media, directory: assetStaging));
      }

      if (pending.isNotEmpty) {
        final exhibitionDirectory = Directory(
          p.join(rootDirectory.path, exhibitionId),
        );
        await exhibitionDirectory.create(recursive: true);
        for (final item in pending) {
          final destination = Directory(
            p.join(exhibitionDirectory.path, item.media.id),
          );
          await item.directory.rename(destination.path);
          movedDirectories.add(destination);
        }
      }
      await _deleteIfExists(stagingRoot);
      return MediaImportResult(
        assets: selectedAssets.values.toList(growable: false),
        selectionMediaIds: List.unmodifiable(selectionIds),
      );
    } on MediaImportException {
      await _rollback(stagingRoot, movedDirectories);
      rethrow;
    } catch (error) {
      await _rollback(stagingRoot, movedDirectories);
      throw MediaImportException('导入图片失败', cause: error);
    }
  }

  Future<void> _rollback(
    Directory stagingRoot,
    List<Directory> movedDirectories,
  ) async {
    for (final directory in movedDirectories.reversed) {
      await _deleteIfExists(directory);
    }
    await _deleteIfExists(stagingRoot);
  }
}

class MediaImportResult {
  const MediaImportResult({
    required this.assets,
    required this.selectionMediaIds,
  });

  final List<GalleryMedia> assets;
  final List<String> selectionMediaIds;
}

class MediaImportException implements Exception {
  const MediaImportException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

Future<String> _sha256(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

Future<String> _referenceFingerprint(File file) async {
  final stat = await file.stat();
  final raw = utf8.encode(
    '${file.absolute.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}',
  );
  return 'reference:${sha256.convert(raw)}';
}

Future<_DecodedMedia> _decodeAndThumbnail(String path) {
  return Isolate.run(() {
    final bytes = File(path).readAsBytesSync();
    final source = img.decodeImage(bytes);
    if (source == null) {
      throw const MediaImportException('所选文件不是可读取的图片');
    }
    final oriented = img.bakeOrientation(source);
    final longest = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final scale = longest > 512 ? 512 / longest : 1.0;
    final thumbnail = img.copyResize(
      oriented,
      width: (oriented.width * scale).round(),
      height: (oriented.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
    return _DecodedMedia(
      width: oriented.width,
      height: oriented.height,
      thumbnailBytes: img.encodeWebP(thumbnail),
    );
  });
}

Future<void> _deleteIfExists(Directory directory) async {
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

class _DecodedMedia {
  const _DecodedMedia({
    required this.width,
    required this.height,
    required this.thumbnailBytes,
  });

  final int width;
  final int height;
  final List<int> thumbnailBytes;
}
