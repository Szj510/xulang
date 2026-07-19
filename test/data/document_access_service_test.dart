import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/document_access_service.dart';
import 'package:xulang/share/exhibition_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        },
      );

  test('scanMusic finds audio files in authorized folders', () async {
    final temp = await Directory.systemTemp.createTemp(
      'xulang_document_access_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final mediaRoot = Directory('${temp.path}/media')..createSync();
    final authorized = Directory('${temp.path}/authorized')..createSync();
    final audio = File('${authorized.path}/summer-track.MP3');
    await audio.writeAsBytes([1, 2, 3, 4]);
    await File('${authorized.path}/notes.txt').writeAsString('ignore');

    final service = DocumentAccessService(mediaRoot: mediaRoot);
    final items = await service.scanMusic(
      authorizedDirectories: [authorized.path],
      displayNames: const {},
    );

    expect(items, hasLength(1));
    expect(items.single.fileName, 'summer-track.MP3');
    expect(items.single.displayName, 'summer-track');
    expect(items.single.source, DocumentCandidateSource.authorizedFolder);
  });

  test('local audio paths do not need Android URI materialization', () async {
    final service = DocumentAccessService(mediaRoot: Directory.systemTemp);

    expect(
      await service.materializeAudioForPlayback('/music/summer-track.mp3'),
      '/music/summer-track.mp3',
    );
  });

  test(
    'music scan cache can be shown before a new folder scan finishes',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'xulang_document_access_cache_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final mediaRoot = Directory('${temp.path}/media')..createSync();
      final service = DocumentAccessService(mediaRoot: mediaRoot);
      const cachedPath = '/music/summer-track.mp3';
      await service.writeCachedMusic([
        MusicLibraryItem(
          path: cachedPath,
          fileName: 'summer-track.mp3',
          displayName: 'Summer track',
          bytes: 1200,
          modifiedAt: DateTime.fromMillisecondsSinceEpoch(1234),
          source: DocumentCandidateSource.authorizedFolder,
        ),
      ]);

      final cached = await service.readCachedMusic(
        displayNames: const {cachedPath: 'Renamed track'},
      );

      expect(cached, hasLength(1));
      expect(cached.single.path, cachedPath);
      expect(cached.single.displayName, 'Renamed track');
    },
  );

  test('template candidate cache preserves summary and path', () async {
    final temp = await Directory.systemTemp.createTemp(
      'xulang_template_cache_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final service = DocumentAccessService(mediaRoot: Directory(temp.path));
    await service.writeCachedTemplates([
      TemplateFileCandidate(
        path: '/exports/xulang-Summer-template.json',
        name: 'xulang-Summer-template.json',
        bytes: 2048,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(5678),
        source: DocumentCandidateSource.appDirectory,
        summary: const TemplateSummary(
          title: 'Summer',
          firstChapterTitle: 'Arrival',
          chapterCount: 2,
          placementCount: 10,
          chapters: [
            TemplateChapterSummary(title: 'Arrival', slotCount: 5),
            TemplateChapterSummary(title: 'Return', slotCount: 5),
          ],
        ),
      ),
    ]);

    final cached = await service.readCachedTemplates();

    expect(cached, hasLength(1));
    expect(cached.single.path, '/exports/xulang-Summer-template.json');
    expect(cached.single.summary.title, 'Summer');
    expect(cached.single.summary.chapterCount, 2);
    expect(cached.single.summary.placementCount, 10);
  });

  test('scanTemplates ignores oversized template files', () async {
    final temp = await Directory.systemTemp.createTemp(
      'xulang_template_oversized_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final mediaRoot = Directory('${temp.path}/media')..createSync();
    final authorized = Directory('${temp.path}/authorized')..createSync();
    final padding = 'x' * ExhibitionTemplateCodec.maxTemplateBytes;
    await File('${authorized.path}/xulang-huge-template.json').writeAsString(
      '{"kind":"xulang-template","chapters":[],"padding":"$padding"}',
    );

    final service = DocumentAccessService(mediaRoot: mediaRoot);
    final templates = await service.scanTemplates(
      authorizedDirectories: [authorized.path],
    );

    expect(templates, isEmpty);
  });
}
