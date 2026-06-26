import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/data/sample_gallery.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/viewer_screen.dart';
import 'package:xulang/widgets/scene_canvas.dart';

void main() {
  late GalleryDatabase database;
  late Directory mediaRoot;
  late GalleryRepository repository;

  setUp(() async {
    database = GalleryDatabase.forTesting(NativeDatabase.memory());
    mediaRoot = await Directory.systemTemp.createTemp('xulang-viewer-');
    repository = GalleryRepository(
      database: database,
      mediaRoot: mediaRoot,
      createId: () => 'id',
    );
    await repository.save(buildSampleGallery(DateTime(2026, 6, 22)));
  });

  tearDown(() async {
    await database.close();
    if (await mediaRoot.exists()) await mediaRoot.delete(recursive: true);
  });

  void setViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [galleryRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: ViewerScreen(exhibitionId: 'sample-exhibition'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers continuous track and explicit fallback navigation', (
    tester,
  ) async {
    await pumpViewer(tester);

    expect(find.text('山海之间'), findsOneWidget);
    expect(find.textContaining('潮汐的方向'), findsOneWidget);
    expect(find.textContaining('进度 0%'), findsOneWidget);
    expect(find.byTooltip('下一项'), findsNothing);
    expect(find.byTooltip('上一项'), findsNothing);
    expect(find.byTooltip('回到全景'), findsNothing);
    expect(find.byTooltip('下一章'), findsOneWidget);
    expect(find.byKey(const Key('viewer-top-scrim')), findsOneWidget);
    expect(find.byKey(const Key('viewer-caption-scrim')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('narrative-gesture-surface')),
      const Offset(-150, 0),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.textContaining('进度 0%'), findsNothing);
  });

  testWidgets('recording mode hides chrome and restores it after replay double tap', (
    tester,
  ) async {
    await pumpViewer(tester);

    expect(find.byKey(const Key('viewer-recording-mode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('viewer-recording-mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('viewer-top-scrim')), findsNothing);
    expect(find.byKey(const Key('viewer-caption-scrim')), findsNothing);
    expect(find.byKey(const Key('viewer-track-progress')), findsNothing);
    expect(find.byKey(const Key('viewer-recording-mode')), findsNothing);

    await tester.pump(const Duration(seconds: 7));
    final surfaceCenter = tester.getCenter(
      find.byKey(const Key('narrative-gesture-surface')),
    );
    await tester.tapAt(surfaceCenter);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('viewer-recording-mode')), findsNothing);

    await tester.tapAt(surfaceCenter);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(surfaceCenter);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('viewer-top-scrim')), findsOneWidget);
    expect(find.byKey(const Key('viewer-caption-scrim')), findsOneWidget);
    expect(find.byKey(const Key('viewer-recording-mode')), findsOneWidget);
  });

  testWidgets('recording delay waits before playback starts', (tester) async {
    final delayed = buildSampleGallery(DateTime(2026, 6, 22));
    await repository.save(
      delayed.copyWith(
        document: delayed.document.copyWith(playbackDelaySeconds: 2),
      ),
    );
    await pumpViewer(tester);

    await tester.tap(find.byKey(const Key('viewer-recording-mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('viewer-recording-delay-countdown')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      tester.widget<SceneCanvas>(find.byType(SceneCanvas)).cameraProgress,
      0,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    expect(
      tester.widget<SceneCanvas>(find.byType(SceneCanvas)).cameraProgress,
      0,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const Key('viewer-recording-delay-countdown')), findsNothing);
    expect(
      tester.widget<SceneCanvas>(find.byType(SceneCanvas)).cameraProgress,
      greaterThan(0),
    );
  });

  testWidgets('keeps camera progress through orientation changes', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));
    await pumpViewer(tester);

    await tester.drag(
      find.byKey(const Key('narrative-gesture-surface')),
      const Offset(0, -220),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final progressBefore = tester
        .widget<SceneCanvas>(find.byType(SceneCanvas))
        .cameraProgress;
    expect(progressBefore, greaterThan(0));

    setViewport(tester, const Size(844, 390));
    await tester.pumpAndSettle();
    final progressAfter = tester
        .widget<SceneCanvas>(find.byType(SceneCanvas))
        .cameraProgress;
    expect(progressAfter, progressBefore);
    expect(find.textContaining('潮汐的方向'), findsOneWidget);
  });

  testWidgets('portrait needs a new boundary gesture to change chapter', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));
    await pumpViewer(tester);

    final surface = find.byKey(const Key('narrative-gesture-surface'));
    await tester.drag(surface, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.textContaining('潮汐的方向'), findsOneWidget);

    await tester.drag(surface, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.textContaining('夏日散步'), findsOneWidget);
  });

  testWidgets('landscape separates track and chapter axes', (tester) async {
    setViewport(tester, const Size(844, 390));
    await pumpViewer(tester);

    final surface = find.byKey(const Key('narrative-gesture-surface'));
    await tester.drag(surface, const Offset(-200, 0));
    await tester.pump();
    expect(find.text('进度 0%'), findsNothing);

    await tester.drag(surface, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.textContaining('夏日散步'), findsOneWidget);
  });
}
