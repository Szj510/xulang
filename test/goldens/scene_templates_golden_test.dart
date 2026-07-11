import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/layout_resolver.dart';
import 'package:xulang/widgets/scene_canvas.dart';

void main() {
  const media = [
    GalleryMedia(
      id: 'coast',
      originalPath: 'asset://assets/sample/coast-sunset.png',
      thumbnailPath: 'asset://assets/sample/coast-sunset.png',
      width: 1536,
      height: 1024,
      contentHash: 'coast',
    ),
    GalleryMedia(
      id: 'alley',
      originalPath: 'asset://assets/sample/coastal-alley.png',
      thumbnailPath: 'asset://assets/sample/coastal-alley.png',
      width: 1024,
      height: 1536,
      contentHash: 'alley',
    ),
    GalleryMedia(
      id: 'walk',
      originalPath: 'asset://assets/sample/summer-walk.png',
      thumbnailPath: 'asset://assets/sample/summer-walk.png',
      width: 1024,
      height: 1536,
      contentHash: 'walk',
    ),
    GalleryMedia(
      id: 'train',
      originalPath: 'asset://assets/sample/train-lake.png',
      thumbnailPath: 'asset://assets/sample/train-lake.png',
      width: 1536,
      height: 1024,
      contentHash: 'train',
    ),
  ];
  const placements = [
    GalleryPlacement(
      id: 'one',
      mediaId: 'coast',
      order: 0,
      frame: GalleryFrame.none,
      caption: '启程',
    ),
    GalleryPlacement(
      id: 'two',
      mediaId: 'alley',
      order: 1,
      size: GallerySize.large,
      frame: GalleryFrame.stamp,
      caption: '巷遇',
    ),
    GalleryPlacement(
      id: 'three',
      mediaId: 'walk',
      order: 2,
      size: GallerySize.large,
      frame: GalleryFrame.mat,
      caption: '海风',
    ),
    GalleryPlacement(
      id: 'four',
      mediaId: 'train',
      order: 3,
      frame: GalleryFrame.none,
      caption: '归途',
    ),
  ];

  for (final layout in GalleryLayout.values) {
    for (final portrait in [true, false]) {
      for (final cameraProgress in [0.0, .35, .70]) {
        final orientation = portrait ? 'portrait' : 'landscape';
        final theme = portrait ? GalleryTheme.ink : GalleryTheme.paper;
        final progressName = (cameraProgress * 100).round();
        testWidgets(
          '${layout.name} $orientation at $progressName% scene golden',
          (tester) async {
            await tester.binding.setSurfaceSize(
              portrait ? const Size(390, 844) : const Size(844, 390),
            );
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final chapter = GalleryChapter(
              id: 'chapter',
              title: '山海之间',
              order: 0,
              layout: layout,
              motion: GalleryMotion.unfold,
              placements: layout == GalleryLayout.orbit
                  ? [
                      for (final placement in placements)
                        placement.copyWith(frame: GalleryFrame.orb),
                    ]
                  : placements,
            );
            if (layout == GalleryLayout.storyPath) {
              final scene = LayoutResolver.resolve(
                chapter: chapter,
                viewport: portrait
                    ? const Size(390, 844)
                    : const Size(844, 390),
              );
              expect(
                scene.primaryAxis,
                portrait ? Axis.vertical : Axis.horizontal,
              );
            }

            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                home: SceneCanvas(
                  chapter: chapter,
                  media: media,
                  cameraProgress: cameraProgress,
                  sceneTheme: theme,
                  reduceMotion: !portrait,
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (layout == GalleryLayout.orbit) {
              final context = tester.element(find.byType(SceneCanvas));
              await tester.runAsync(() async {
                for (final item in media) {
                  await precacheImage(
                    ResizeImage.resizeIfNeeded(
                      portrait ? 780 : 1688,
                      null,
                      AssetImage(
                        item.thumbnailPath.replaceFirst('asset://', ''),
                      ),
                    ),
                    context,
                  );
                }
              });
              await tester.pumpAndSettle();
            }

            await expectLater(
              find.byType(SceneCanvas),
              matchesGoldenFile(
                '${layout.name}_${orientation}_${theme.name}_p$progressName.png',
              ),
            );
          },
        );
      }
    }
  }

  testWidgets('orbit at the chapter limit stays legible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final densePlacements = List.generate(
      maxGalleryPlacementsPerChapter,
      (index) => GalleryPlacement(
        id: 'dense-$index',
        mediaId: media[index % media.length].id,
        order: index,
        size: index == 0 ? GallerySize.large : GallerySize.medium,
        frame: GalleryFrame.orb,
      ),
    );
    final chapter = GalleryChapter(
      id: 'dense-orbit',
      title: 'Dense orbit',
      order: 0,
      layout: GalleryLayout.orbit,
      motion: GalleryMotion.unfold,
      placements: densePlacements,
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SceneCanvas(
          chapter: chapter,
          media: media,
          cameraProgress: .42,
          sceneTheme: GalleryTheme.ink,
        ),
      ),
    );
    final context = tester.element(find.byType(SceneCanvas));
    await tester.runAsync(() async {
      for (final item in media) {
        await precacheImage(
          ResizeImage.resizeIfNeeded(
            780,
            null,
            AssetImage(item.thumbnailPath.replaceFirst('asset://', '')),
          ),
          context,
        );
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SceneCanvas),
      matchesGoldenFile('orbit_dense_portrait_ink.png'),
    );
  });

  testWidgets('orbit matches the Saturn layering reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final chapter = GalleryChapter(
      id: 'saturn-reference',
      title: 'Saturn reference',
      order: 0,
      layout: GalleryLayout.orbit,
      motion: GalleryMotion.unfold,
      placements: [
        for (final placement in placements)
          placement.copyWith(frame: GalleryFrame.orb),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SceneCanvas(
          chapter: chapter,
          media: media,
          cameraProgress: .35,
          sceneTheme: GalleryTheme.ink,
        ),
      ),
    );
    final context = tester.element(find.byType(SceneCanvas));
    await tester.runAsync(() async {
      for (final item in media) {
        await precacheImage(
          ResizeImage.resizeIfNeeded(
            1688,
            null,
            AssetImage(item.thumbnailPath.replaceFirst('asset://', '')),
          ),
          context,
        );
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SceneCanvas),
      matchesGoldenFile('orbit_saturn_landscape_ink.png'),
    );
  });

  testWidgets('starfield canvas keeps photos readable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const chapter = GalleryChapter(
      id: 'starfield-canvas',
      title: 'Under the stars',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.focus,
      placements: placements,
    );

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SceneCanvas(
          chapter: chapter,
          media: media,
          cameraProgress: .35,
          sceneTheme: GalleryTheme.starfield,
        ),
      ),
    );
    final context = tester.element(find.byType(SceneCanvas));
    await tester.runAsync(() async {
      for (final item in media) {
        await precacheImage(
          ResizeImage.resizeIfNeeded(
            780,
            null,
            AssetImage(item.thumbnailPath.replaceFirst('asset://', '')),
          ),
          context,
        );
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SceneCanvas),
      matchesGoldenFile('starfield_canvas_portrait.png'),
    );
  });
}
