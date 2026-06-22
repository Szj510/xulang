import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
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
              placements: placements,
            );

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
}
