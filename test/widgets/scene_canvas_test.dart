import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/widgets/gallery_image.dart';
import 'package:xulang/widgets/scene_canvas.dart';

void main() {
  const media = GalleryMedia(
    id: 'media',
    originalPath: 'asset://assets/sample/coast-sunset.png',
    thumbnailPath: 'asset://assets/sample/train-lake.png',
    width: 1536,
    height: 1024,
    contentHash: 'hash',
  );
  const chapter = GalleryChapter(
    id: 'chapter',
    title: '章节',
    order: 0,
    layout: GalleryLayout.hero,
    motion: GalleryMotion.push,
    placements: [
      GalleryPlacement(
        id: 'placement',
        mediaId: 'media',
        order: 0,
        focalX: 1,
        focalY: 0,
        zoom: 2,
      ),
    ],
  );

  testWidgets('applies crop focus and zoom to each image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(chapter: chapter, media: [media]),
        ),
      ),
    );

    final image = tester.widget<GalleryImage>(find.byType(GalleryImage));
    expect(image.alignment, const Alignment(1, -1));
    expect(image.scale, 2);
    expect(image.path, media.thumbnailPath);
  });

  testWidgets('viewer mode selects the original image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            useOriginals: true,
          ),
        ),
      ),
    );

    final image = tester.widget<GalleryImage>(find.byType(GalleryImage));
    expect(image.path, media.originalPath);
  });

  testWidgets('paper theme changes the scene surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            sceneTheme: GalleryTheme.paper,
          ),
        ),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find.byKey(const Key('scene-background')),
    );
    expect(background.color, const Color(0xFFE8E0D3));
  });

  testWidgets('camera progress changes node transforms continuously', (
    tester,
  ) async {
    Future<void> pumpAt(double cameraProgress) {
      return tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 844,
            child: SceneCanvas(
              chapter: chapter,
              media: const [media],
              cameraProgress: cameraProgress,
            ),
          ),
        ),
      );
    }

    await pumpAt(.25);
    final before = tester
        .widget<Transform>(find.byKey(const Key('scene-node-placement')))
        .transform
        .clone();
    await pumpAt(.30);
    final after = tester
        .widget<Transform>(find.byKey(const Key('scene-node-placement')))
        .transform;

    expect(after, isNot(before));
  });
}
