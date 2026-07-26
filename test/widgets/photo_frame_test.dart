import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/widgets/gallery_image.dart';
import 'package:xulang/widgets/photo_frame.dart';

void main() {
  const media = GalleryMedia(
    id: 'media',
    originalPath: 'asset://assets/sample/coast-sunset.jpg',
    thumbnailPath: 'asset://assets/sample/train-lake.jpg',
    width: 1536,
    height: 1024,
    contentHash: 'hash',
  );

  for (final frame in GalleryFrame.values) {
    testWidgets('${frame.name} uses a visibly distinct frame structure', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 260,
            height: 340,
            child: PhotoFrame(
              placement: GalleryPlacement(
                id: 'placement',
                mediaId: 'media',
                order: 0,
                frame: frame,
                frameCaption: frame == GalleryFrame.captionMat ? '风从湖面吹来' : '',
              ),
              media: media,
              depth: 1,
              useOriginals: false,
              sceneTheme: GalleryTheme.ink,
            ),
          ),
        ),
      );

      expect(find.byKey(Key('frame-${frame.name}')), findsOneWidget);
      if (frame == GalleryFrame.stamp) {
        expect(find.byKey(const Key('stamp-edge-painter')), findsOneWidget);
      }
      if (frame == GalleryFrame.wood) {
        expect(find.byKey(const Key('wood-grain-painter')), findsOneWidget);
      }
      if (frame == GalleryFrame.darkWood) {
        expect(
          find.byKey(const Key('dark-wood-grain-painter')),
          findsOneWidget,
        );
      }
      if (frame == GalleryFrame.metal) {
        expect(find.byKey(const Key('metal-texture-painter')), findsOneWidget);
      }
      if (frame == GalleryFrame.vintage) {
        expect(find.byKey(const Key('vintage-paper-painter')), findsOneWidget);
      }
      if (frame == GalleryFrame.orb) {
        expect(find.byType(ClipOval), findsOneWidget);
        expect(
          tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
          1,
        );
      }
      if (frame == GalleryFrame.captionMat) {
        expect(
          find.byKey(const Key('caption-mat-frame-painter')),
          findsOneWidget,
        );
        expect(find.text('风从湖面吹来'), findsOneWidget);
      }
      final handDrawnPainterKeys = <GalleryFrame, Key>{
        GalleryFrame.tapedPaper: const Key('taped-paper-frame-painter'),
        GalleryFrame.crayon: const Key('crayon-frame-painter'),
        GalleryFrame.watercolor: const Key('watercolor-frame-painter'),
        GalleryFrame.doodleTape: const Key('doodle-tape-frame-painter'),
        GalleryFrame.scallop: const Key('scallop-frame-painter'),
        GalleryFrame.cornerSketch: const Key('corner-sketch-frame-painter'),
        GalleryFrame.wavy: const Key('wavy-frame-painter'),
      };
      if (handDrawnPainterKeys[frame] case final painterKey?) {
        expect(find.byKey(painterKey), findsOneWidget);
      }
    });
  }

  testWidgets(
    'compact orbit frames preserve photo area for every frame style',
    (tester) async {
      for (final frame in GalleryFrame.values) {
        Future<Size> imageSize({required bool compact}) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: 110,
                  height: 90,
                  child: PhotoFrame(
                    placement: GalleryPlacement(
                      id: 'placement',
                      mediaId: 'media',
                      order: 0,
                      frame: frame,
                      frameCaption: frame == GalleryFrame.captionMat
                          ? '山海之间'
                          : '',
                    ),
                    media: media,
                    depth: .5,
                    useOriginals: false,
                    sceneTheme: GalleryTheme.ink,
                    compact: compact,
                  ),
                ),
              ),
            ),
          );
          return tester.getSize(find.byType(GalleryImage));
        }

        final regular = await imageSize(compact: false);
        final compact = await imageSize(compact: true);

        expect(
          compact.width,
          greaterThanOrEqualTo(regular.width),
          reason: '${frame.name} should not use a thicker horizontal frame',
        );
        expect(
          compact.height,
          greaterThanOrEqualTo(regular.height),
          reason: '${frame.name} should not use a thicker vertical frame',
        );
        expect(
          compact.width / 110,
          greaterThanOrEqualTo(.70),
          reason: '${frame.name} should keep the photo horizontally prominent',
        );
        expect(
          compact.height / 90,
          greaterThanOrEqualTo(frame == GalleryFrame.captionMat ? .68 : .70),
          reason: '${frame.name} should keep the photo vertically prominent',
        );
      }
    },
  );

  testWidgets('tape and delicate outlines paint above the photo', (
    tester,
  ) async {
    final foregroundKeys = <GalleryFrame, Key>{
      GalleryFrame.captionMat: const Key('caption-mat-frame-painter'),
      GalleryFrame.tapedPaper: const Key('taped-paper-frame-painter'),
      GalleryFrame.doodleTape: const Key('doodle-tape-frame-painter'),
      GalleryFrame.scallop: const Key('scallop-frame-painter'),
      GalleryFrame.cornerSketch: const Key('corner-sketch-frame-painter'),
      GalleryFrame.wavy: const Key('wavy-frame-painter'),
    };

    for (final entry in foregroundKeys.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 110,
              height: 90,
              child: PhotoFrame(
                placement: GalleryPlacement(
                  id: 'placement',
                  mediaId: media.id,
                  order: 0,
                  frame: entry.key,
                  frameCaption: '山海之间',
                ),
                media: media,
                depth: .5,
                useOriginals: false,
                sceneTheme: GalleryTheme.ink,
                compact: true,
              ),
            ),
          ),
        ),
      );

      final paint = tester.widget<CustomPaint>(find.byKey(entry.value));
      expect(
        paint.foregroundPainter,
        isNotNull,
        reason: '${entry.key.name} must remain visible above the photo',
      );
    }
  });
}
