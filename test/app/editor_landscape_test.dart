import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/data/image_selection_service.dart';
import 'package:xulang/data/media_import_service.dart';
import 'package:xulang/data/sample_gallery.dart';
import 'package:xulang/editor/editor_session.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/editor_screen.dart';

void main() {
  late GalleryDatabase database;
  late Directory mediaRoot;
  late GalleryRepository repository;
  late EditorSession session;

  setUp(() async {
    database = GalleryDatabase.forTesting(NativeDatabase.memory());
    mediaRoot = await Directory.systemTemp.createTemp('xulang-editor-widget-');
    repository = GalleryRepository(
      database: database,
      mediaRoot: mediaRoot,
      createId: () => 'generated-id',
    );
    await repository.save(buildSampleGallery(DateTime(2026, 6, 22)));
    session = EditorSession(
      exhibitionId: 'sample-exhibition',
      repository: repository,
      importer: MediaImportService(
        rootDirectory: mediaRoot,
        createId: () => 'generated-id',
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

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorSessionProvider('sample-exhibition').overrideWithValue(session),
        ],
        child: const MaterialApp(
          home: EditorScreen(exhibitionId: 'sample-exhibition'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('landscape inspector scrolls every control into reach', (
    tester,
  ) async {
    await pumpEditor(tester);

    final scroll = find.byKey(const Key('editor-inspector-scroll'));
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('裁切焦点与短注释').hitTestable(), findsOneWidget);
    expect(find.text('邮票边').hitTestable(), findsOneWidget);
  });

  testWidgets('editor exposes a live continuous track preview', (tester) async {
    await pumpEditor(tester);

    expect(find.byKey(const Key('editor-camera-slider')), findsOneWidget);
  });
}

class _NoImages implements ImageSelectionService {
  const _NoImages();

  @override
  Future<List<String>> selectImages() async => const [];
}
