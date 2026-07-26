@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/screens/editor_screen.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/photo_frame.dart';

void main() {
  testWidgets('taped paper frame matches the scrapbook reference', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(260, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const media = GalleryMedia(
      id: 'taped-media',
      originalPath: 'asset://assets/sample/coast-sunset.jpg',
      thumbnailPath: 'asset://assets/sample/summer-walk.jpg',
      width: 1536,
      height: 1024,
      contentHash: 'taped-paper-golden',
    );
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: XulangColors.ink,
          child: Center(
            child: SizedBox(
              width: 190,
              height: 240,
              child: PhotoFrame(
                placement: GalleryPlacement(
                  id: 'taped-placement',
                  mediaId: 'taped-media',
                  order: 0,
                  frame: GalleryFrame.tapedPaper,
                ),
                media: media,
                depth: 1,
                useOriginals: false,
                sceneTheme: GalleryTheme.ink,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PhotoFrame));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/sample/summer-walk.jpg'),
        context,
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PhotoFrame),
      matchesGoldenFile('taped_paper_frame.png'),
    );
  });

  testWidgets('hand-drawn frame family stays visually distinct', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const media = GalleryMedia(
      id: 'media',
      originalPath: 'asset://assets/sample/coast-sunset.jpg',
      thumbnailPath: 'asset://assets/sample/summer-walk.jpg',
      width: 1536,
      height: 1024,
      contentHash: 'hand-drawn-golden',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: XulangColors.ink,
          child: Center(
            child: Wrap(
              spacing: 18,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                for (final frame in handDrawnGalleryFrames)
                  SizedBox(
                    width: 170,
                    height: 210,
                    child: PhotoFrame(
                      placement: GalleryPlacement(
                        id: 'placement-${frame.name}',
                        mediaId: media.id,
                        order: frame.index,
                        frame: frame,
                      ),
                      media: media,
                      depth: 1,
                      useOriginals: false,
                      sceneTheme: GalleryTheme.ink,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Wrap));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/sample/summer-walk.jpg'),
        context,
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('hand_drawn_frame_family.png'),
    );
  });

  testWidgets('compact orbit frame family keeps every photo prominent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(660, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const media = GalleryMedia(
      id: 'orbit-media',
      originalPath: 'asset://assets/sample/coast-sunset.jpg',
      thumbnailPath: 'asset://assets/sample/summer-walk.jpg',
      width: 1536,
      height: 1024,
      contentHash: 'orbit-frame-family-golden',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: XulangColors.ink,
          child: Center(
            child: Wrap(
              key: const Key('orbit-frame-family'),
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (final frame in GalleryFrame.values)
                  SizedBox(
                    width: 190,
                    height: 130,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 174,
                          height: 104,
                          child: PhotoFrame(
                            placement: GalleryPlacement(
                              id: 'orbit-placement-${frame.name}',
                              mediaId: media.id,
                              order: frame.index,
                              frame: frame,
                              frameCaption: frame == GalleryFrame.captionMat
                                  ? '山海之间'
                                  : '',
                            ),
                            media: media,
                            depth: .5,
                            useOriginals: false,
                            sceneTheme: GalleryTheme.ink,
                            compact: true,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          frame.name,
                          style: const TextStyle(
                            color: Color(0xFFB9B0A2),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(const Key('orbit-frame-family')));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/sample/summer-walk.jpg'),
        context,
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('orbit-frame-family')),
      matchesGoldenFile('orbit_compact_frame_family.png'),
    );
  });
}
