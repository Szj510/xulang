import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/data/media_import_service.dart';

void main() {
  late Directory root;
  late Directory sources;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('xulang-media-root-');
    sources = await Directory.systemTemp.createTemp('xulang-media-source-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
    if (await sources.exists()) await sources.delete(recursive: true);
  });

  test('copies originals and creates a bounded WebP thumbnail', () async {
    final source = File('${sources.path}/wide.jpg');
    final picture = img.Image(width: 1200, height: 600);
    img.fill(picture, color: img.ColorRgb8(35, 92, 140));
    await source.writeAsBytes(img.encodeJpg(picture));
    final importer = MediaImportService(
      rootDirectory: root,
      createId: () => 'asset-1',
    );

    final result = await importer.importFiles(
      exhibitionId: 'exhibition-1',
      sourcePaths: [source.path],
      existingAssets: const [],
    );

    expect(result.assets, hasLength(1));
    expect(result.selectionMediaIds, ['asset-1']);
    expect(await File(result.assets.single.originalPath).exists(), isTrue);
    expect(result.assets.single.thumbnailPath, endsWith('.webp'));
    final thumbnail = img.decodeImage(
      await File(result.assets.single.thumbnailPath).readAsBytes(),
    );
    expect(thumbnail, isNotNull);
    expect(thumbnail!.width, 512);
    expect(thumbnail.height, 256);
  });

  test(
    'deduplicates identical selections while preserving placement intent',
    () async {
      final source = File('${sources.path}/same.png');
      final picture = img.Image(width: 32, height: 32);
      img.fill(picture, color: img.ColorRgb8(120, 50, 30));
      await source.writeAsBytes(img.encodePng(picture));
      final importer = MediaImportService(
        rootDirectory: root,
        createId: () => 'asset-1',
      );

      final result = await importer.importFiles(
        exhibitionId: 'exhibition-1',
        sourcePaths: [source.path, source.path],
        existingAssets: const [],
      );

      expect(result.assets, hasLength(1));
      expect(result.selectionMediaIds, ['asset-1', 'asset-1']);
    },
  );

  test('reference mode keeps each selected path as a fast reference', () async {
    var nextId = 0;
    final source = File('${sources.path}/referenced.png');
    final picture = img.Image(width: 80, height: 60);
    img.fill(picture, color: img.ColorRgb8(16, 42, 80));
    await source.writeAsBytes(img.encodePng(picture));
    final importer = MediaImportService(
      rootDirectory: root,
      createId: () => 'asset-${++nextId}',
    );

    final result = await importer.importFiles(
      exhibitionId: 'exhibition-1',
      sourcePaths: [source.path, source.path],
      existingAssets: const [],
      importMode: MediaImportMode.referenceOriginal,
    );

    expect(result.assets, hasLength(2));
    expect(result.selectionMediaIds, ['asset-1', 'asset-2']);
    expect(result.assets.map((asset) => asset.originalPath), [
      source.path,
      source.path,
    ]);
    for (final asset in result.assets) {
      expect(asset.contentHash, startsWith('reference:'));
      expect(await File(asset.thumbnailPath).exists(), isTrue);
      final assetDirectory = Directory('${root.path}/exhibition-1/${asset.id}');
      final copiedOriginals = await assetDirectory
          .list()
          .where((entity) => entity is File && !entity.path.endsWith('.webp'))
          .toList();
      expect(copiedOriginals, isEmpty);
    }
  });

  test('removes staging files when a selected image is invalid', () async {
    final valid = File('${sources.path}/valid.png');
    final picture = img.Image(width: 32, height: 32);
    await valid.writeAsBytes(img.encodePng(picture));
    final invalid = File('${sources.path}/broken.jpg');
    await invalid.writeAsString('not-an-image');
    final importer = MediaImportService(
      rootDirectory: root,
      createId: () => 'asset-1',
    );

    await expectLater(
      importer.importFiles(
        exhibitionId: 'exhibition-1',
        sourcePaths: [valid.path, invalid.path],
        existingAssets: const [],
      ),
      throwsA(isA<MediaImportException>()),
    );

    final exhibition = Directory('${root.path}/exhibition-1');
    expect(await exhibition.exists(), isFalse);
  });
}
