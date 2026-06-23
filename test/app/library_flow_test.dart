import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/app.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/providers/app_providers.dart';

void main() {
  late GalleryDatabase database;
  late Directory mediaRoot;
  late GalleryRepository repository;
  var nextId = 0;

  setUp(() async {
    database = GalleryDatabase.forTesting(NativeDatabase.memory());
    mediaRoot = await Directory.systemTemp.createTemp('xulang-widget-');
    repository = GalleryRepository(
      database: database,
      mediaRoot: mediaRoot,
      createId: () => 'id-${nextId++}',
    );
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

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    setViewport(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(repository),
          exhibitionSummariesProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: const XulangApp(),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }

  testWidgets('empty library explains local storage and offers creation', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('叙廊'), findsOneWidget);
    expect(find.text('让照片沿着故事展开'), findsOneWidget);
    expect(find.text('创建第一个展览'), findsOneWidget);
    expect(find.textContaining('卸载应用会删除'), findsOneWidget);
  });

  testWidgets('creating an exhibition opens the curation editor', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('创建第一个展览'));
    await tester.pump();
    expect(find.text('新建展览'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '山海之间');
    await tester.tap(find.widgetWithText(FilledButton, '创建'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('山海之间'), findsWidgets);
    expect(find.text('导入图片'), findsOneWidget);
    expect(find.text('主视觉'), findsOneWidget);
    expect(find.text('横向胶片'), findsOneWidget);
    expect(find.text('双联画'), findsOneWidget);
    expect(find.text('叙事拼贴'), findsOneWidget);
    expect(find.text('路径线条'), findsOneWidget);
    expect(find.text('细线'), findsOneWidget);
    expect(find.text('虚线'), findsOneWidget);
    expect(find.text('微光'), findsOneWidget);
    expect(find.text('隐藏'), findsOneWidget);
    expect(find.text('平移'), findsNothing);
  });

  testWidgets('closing a text dialog does not outlive its input state', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('创建第一个展览'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '临时标题');
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('新建展览'), findsNothing);
  });
}
