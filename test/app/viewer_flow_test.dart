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
    expect(find.byTooltip('下一项'), findsOneWidget);
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

  testWidgets('keeps camera progress through orientation changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpViewer(tester);

    await tester.drag(
      find.byKey(const Key('narrative-gesture-surface')),
      const Offset(-110, 0),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final progressBefore = tester
        .widget<Text>(find.byKey(const Key('viewer-track-progress')))
        .data;
    expect(progressBefore, isNot('进度 0%'));

    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpAndSettle();
    final progressAfter = tester
        .widget<Text>(find.byKey(const Key('viewer-track-progress')))
        .data;
    expect(progressAfter, progressBefore);
    expect(find.textContaining('潮汐的方向'), findsOneWidget);
  });
}
