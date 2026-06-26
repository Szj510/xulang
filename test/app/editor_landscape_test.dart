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

  InkWell toolbarButton(WidgetTester tester, String action) {
    return tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(Key('landscape-editor-$action')),
        matching: find.byType(InkWell),
      ),
    );
  }

  Future<void> dragCanvasTrack(
    WidgetTester tester,
    Offset delta, {
    Offset? startOffset,
  }) async {
    final rect = tester.getRect(
      find.byKey(const Key('editor-preview-gesture-surface')),
    );
    await tester.dragFrom(
      rect.topLeft + (startOffset ?? const Offset(24, 24)),
      delta,
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

    await tester.tap(
      find.byKey(const Key('scene-node-gesture-sample-placement-4')),
    );
    await tester.pumpAndSettle();

    final scroll = find.byKey(const Key('editor-inspector-scroll'));
    await tester.drag(scroll, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('裁切与构图'), findsOneWidget);
    expect(find.text('邮票边'), findsOneWidget);
    expect(find.text('高级编辑'), findsNothing);
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

    await dragCanvasTrack(tester, const Offset(0, -160));
    await tester.pump();
    expect(progress(tester), greaterThan(0));
  });

  testWidgets('portrait preview background supports two finger pinch zoom', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));

    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('editor-preview-zoom')),
    );
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    final worldSize = tester.getSize(
      find.byKey(const Key('editor-infinite-world')),
    );
    expect(worldSize.width, greaterThan(390));
    expect(worldSize.height, greaterThan(844));
    expect(find.byIcon(Icons.zoom_out), findsOneWidget);
    expect(find.byIcon(Icons.fit_screen_outlined), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);

    await tester.tap(find.byIcon(Icons.zoom_out));
    await tester.pump();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      lessThan(1),
    );

    await tester.tap(find.byIcon(Icons.fit_screen_outlined));
    await tester.pump();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);

    final rect = tester.getRect(
      find.byKey(const Key('editor-preview-gesture-surface')),
    );
    final center = rect.topLeft + const Offset(60, 90);
    final first = await tester.createGesture();
    final second = await tester.createGesture();
    await first.down(center - const Offset(18, 0));
    await second.down(center + const Offset(18, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(54, 0));
    await second.moveTo(center + const Offset(54, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1.2),
    );
  });

  testWidgets('floating ball can be dragged vertically across the editor', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));

    final finder = find.byKey(const Key('editor-floating-ball'));
    final before = tester.getTopLeft(finder);

    await tester.drag(finder, const Offset(0, -220));
    await tester.pump();

    final after = tester.getTopLeft(finder);
    expect(after.dy, lessThan(before.dy - 160));
  });

  testWidgets('canvas panel exposes adjustable opacity control', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const Key('editor-floating-ball')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('editor-floating-panel-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('editor-panel-opacity-slider')),
      findsOneWidget,
    );
    expect(find.text('面板透明度'), findsOneWidget);

    final shell = tester.widget<DecoratedBox>(
      find.byKey(const Key('editor-floating-panel-shell')),
    );
    final before = (shell.decoration as BoxDecoration).color!.a;
    final slider = find.descendant(
      of: find.byKey(const Key('editor-panel-opacity-slider')),
      matching: find.byType(Slider),
    );

    await tester.drag(slider, const Offset(180, 0));
    await tester.pumpAndSettle();

    final updatedShell = tester.widget<DecoratedBox>(
      find.byKey(const Key('editor-floating-panel-shell')),
    );
    final after = (updatedShell.decoration as BoxDecoration).color!.a;
    expect(after, greaterThan(before));
  });

  testWidgets('editor modes isolate canvas image and sticker gestures', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));

    var viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('editor-preview-zoom')),
    );
    var canvas = tester.widget<SceneCanvas>(find.byType(SceneCanvas));
    expect(viewer.panEnabled, isTrue);
    expect(viewer.scaleEnabled, isTrue);
    expect(canvas.placementEditingEnabled, isFalse);
    expect(find.byKey(const Key('editor-mode-path')), findsNothing);
    expect(find.text('路径注释'), findsNothing);

    await tester.tap(
      find.byKey(const Key('scene-node-gesture-sample-placement-4')),
    );
    await tester.pumpAndSettle();

    viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('editor-preview-zoom')),
    );
    canvas = tester.widget<SceneCanvas>(find.byType(SceneCanvas));
    expect(viewer.panEnabled, isFalse);
    expect(viewer.scaleEnabled, isFalse);
    expect(canvas.placementEditingEnabled, isTrue);

    await tester.tap(find.byKey(const Key('editor-mode-sticker')));
    await tester.pumpAndSettle();

    viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('editor-preview-zoom')),
    );
    canvas = tester.widget<SceneCanvas>(find.byType(SceneCanvas));
    expect(viewer.panEnabled, isTrue);
    expect(viewer.scaleEnabled, isTrue);
    expect(canvas.placementEditingEnabled, isFalse);
    expect(find.text('贴画'), findsWidgets);
  });

  testWidgets('sticker mode places moves and deletes stickers', (tester) async {
    await pumpEditor(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const Key('editor-floating-ball')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor-mode-sticker')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editor-sticker-kind-star')));
    await tester.pumpAndSettle();

    final surface = find.byKey(const Key('scene-sticker-place-surface'));
    expect(surface, findsOneWidget);
    final rect = tester.getRect(surface);
    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();

    var stickers = session.selectedChapter!.stickers;
    expect(stickers, hasLength(1));
    final stickerId = stickers.single.id;
    final stickerFinder = find.byKey(Key('scene-sticker-$stickerId'));
    expect(stickerFinder, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('editor-infinite-world')),
        matching: stickerFinder,
      ),
      findsOneWidget,
    );

    final beforeX = stickers.single.x;
    await tester.drag(
      find.byKey(Key('scene-sticker-$stickerId')),
      const Offset(40, 0),
    );
    await tester.pumpAndSettle();
    stickers = session.selectedChapter!.stickers;
    expect(stickers.single.x, isNot(beforeX));

    await tester.tap(find.byKey(Key('scene-sticker-delete-$stickerId')));
    await tester.pumpAndSettle();
    expect(session.selectedChapter!.stickers, isEmpty);
  });

  testWidgets('landscape locks navigation to horizontal drags', (tester) async {
    await pumpEditor(tester);

    await dragCanvasTrack(tester, const Offset(0, -160));
    await tester.pump();
    expect(progress(tester), 0);

    await dragCanvasTrack(
      tester,
      const Offset(-160, 0),
      startOffset: const Offset(24, 300),
    );
    await tester.pump();
    expect(progress(tester), greaterThan(0));
  });

  testWidgets('camera progress is retained independently for each chapter', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(390, 844));

    await tester.tap(find.textContaining('夏日散步'));
    await tester.pumpAndSettle();
    await dragCanvasTrack(tester, const Offset(0, -180));
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

    expect(toolbarButton(tester, 'undo').onTap, isNull);
    expect(toolbarButton(tester, 'redo').onTap, isNull);
    expect(toolbarButton(tester, 'play').onTap, isNotNull);
    expect(find.text('导入图片'), findsOneWidget);

    await session.rename('新展览');
    await tester.pumpAndSettle();
    expect(toolbarButton(tester, 'undo').onTap, isNotNull);
    await tester.tap(find.byTooltip('撤销'));
    await tester.pumpAndSettle();
    expect(toolbarButton(tester, 'redo').onTap, isNotNull);
  });
}

class _NoImages implements ImageSelectionService {
  const _NoImages();

  @override
  Future<List<String>> selectImages() async => const [];
}
