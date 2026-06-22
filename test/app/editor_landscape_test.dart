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
import 'package:xulang/widgets/scene_canvas.dart';

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

  Future<void> pumpEditor(
    WidgetTester tester, {
    Size size = const Size(844, 390),
  }) async {
    await tester.binding.setSurfaceSize(size);
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

  double progress(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.byKey(const Key('editor-camera-progress')),
    );
    return double.parse(text.data!.replaceAll('%', ''));
  }

  IconButton toolbarButton(WidgetTester tester, String action) {
    return tester.widget<IconButton>(
      find.byKey(Key('landscape-editor-$action')),
    );
  }

  testWidgets('landscape chrome overlays chapters without resizing preview', (
    tester,
  ) async {
    await pumpEditor(tester);

    expect(find.byKey(const Key('editor-app-bar')), findsNothing);
    expect(find.byKey(const Key('editor-chapter-rail')), findsNothing);
    expect(find.byKey(const Key('landscape-editor-toolbar')), findsOneWidget);
    final before = tester.getSize(
      find.byKey(const Key('editor-preview-gesture-surface')),
    );

    await tester.tap(find.byTooltip('章节'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landscape-chapter-overlay')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('landscape-chapter-overlay'))).height,
      lessThanOrEqualTo(64),
    );
    expect(
      tester.getSize(find.byKey(const Key('editor-preview-gesture-surface'))),
      before,
    );

    await tester.tap(find.textContaining('夏日散步'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landscape-chapter-overlay')), findsNothing);

    await tester.tap(find.byTooltip('章节'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor-preview-gesture-surface')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landscape-chapter-overlay')), findsNothing);

    final scroll = find.byKey(const Key('editor-inspector-scroll'));
    await tester.drag(scroll, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('裁切焦点与短注释').hitTestable(), findsOneWidget);
    expect(find.text('邮票边').hitTestable(), findsOneWidget);
  });

  testWidgets('portrait keeps app bar and rail and supports upward progress', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));

    expect(find.byKey(const Key('editor-app-bar')), findsOneWidget);
    expect(find.byKey(const Key('editor-chapter-rail')), findsOneWidget);
    expect(find.byKey(const Key('editor-vertical-progress')), findsOneWidget);
    expect(find.byKey(const Key('landscape-editor-toolbar')), findsNothing);
    expect(progress(tester), 0);

    await tester.drag(
      find.byKey(const Key('editor-preview-gesture-surface')),
      const Offset(0, -160),
    );
    await tester.pump();
    expect(progress(tester), greaterThan(0));
  });

  testWidgets('landscape locks navigation to horizontal drags', (tester) async {
    await pumpEditor(tester);
    final surface = find.byKey(const Key('editor-preview-gesture-surface'));

    await tester.drag(surface, const Offset(0, -160));
    await tester.pump();
    expect(progress(tester), 0);

    await tester.drag(surface, const Offset(-160, 0));
    await tester.pump();
    expect(progress(tester), greaterThan(0));
  });

  testWidgets('camera progress is retained independently for each chapter', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));
    final surface = find.byKey(const Key('editor-preview-gesture-surface'));

    await tester.tap(find.textContaining('夏日散步'));
    await tester.pumpAndSettle();
    await tester.drag(surface, const Offset(0, -180));
    await tester.pump();
    final secondProgress = progress(tester);
    expect(secondProgress, greaterThan(0));

    await tester.tap(find.textContaining('潮汐的方向'));
    await tester.pumpAndSettle();
    expect(progress(tester), 0);
    await tester.tap(find.textContaining('夏日散步'));
    await tester.pumpAndSettle();
    expect(progress(tester), secondProgress);
  });

  testWidgets('progress slider and canvas share camera progress', (
    tester,
  ) async {
    await pumpEditor(tester);

    final slider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(const Key('editor-horizontal-progress')),
        matching: find.byType(Slider),
      ),
    );
    slider.onChanged!(.6);
    await tester.pump();

    expect(progress(tester), 60);
    expect(
      tester.widget<SceneCanvas>(find.byType(SceneCanvas)).cameraProgress,
      .6,
    );
  });

  testWidgets('landscape toolbar reflects history and keeps play and import', (
    tester,
  ) async {
    await pumpEditor(tester);

    expect(toolbarButton(tester, 'undo').onPressed, isNull);
    expect(toolbarButton(tester, 'redo').onPressed, isNull);
    expect(toolbarButton(tester, 'play').onPressed, isNotNull);
    expect(find.text('导入图片'), findsOneWidget);

    await session.rename('新展览');
    await tester.pumpAndSettle();
    expect(toolbarButton(tester, 'undo').onPressed, isNotNull);
    await tester.tap(find.byTooltip('撤销'));
    await tester.pumpAndSettle();
    expect(toolbarButton(tester, 'redo').onPressed, isNotNull);
  });
}

class _NoImages implements ImageSelectionService {
  const _NoImages();

  @override
  Future<List<String>> selectImages() async => const [];
}
