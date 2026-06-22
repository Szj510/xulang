import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/widgets/photo_frame.dart';

void main() {
  const media = GalleryMedia(
    id: 'media',
    originalPath: 'asset://assets/sample/coast-sunset.png',
    thumbnailPath: 'asset://assets/sample/train-lake.png',
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
    });
  }
}
