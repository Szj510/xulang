import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/screens/editor_screen.dart';

void main() {
  test('path style controls only belong to the story path layout', () {
    for (final layout in GalleryLayout.values) {
      expect(
        showsStoryPathControls(layout),
        layout == GalleryLayout.storyPath,
        reason: layout.name,
      );
    }
  });

  test('all frame groups cover every frame once', () {
    final grouped = [...classicGalleryFrames, ...handDrawnGalleryFrames];

    expect(grouped, hasLength(GalleryFrame.values.length));
    expect(grouped.toSet(), GalleryFrame.values.toSet());
    expect(classicGalleryFrames, contains(GalleryFrame.tapedPaper));
    expect(handDrawnGalleryFrames, hasLength(7));
    expect(handDrawnGalleryFrames, contains(GalleryFrame.captionMat));
    for (final frame in classicGalleryFrames) {
      expect(frameFamilyFor(frame), FrameFamily.classic, reason: frame.name);
    }
    for (final frame in handDrawnGalleryFrames) {
      expect(frameFamilyFor(frame), FrameFamily.handDrawn, reason: frame.name);
    }
  });

  test('single-photo notes only belong to the story path layout', () {
    for (final layout in GalleryLayout.values) {
      expect(
        showsSinglePhotoCaption(layout),
        layout == GalleryLayout.storyPath,
        reason: layout.name,
      );
    }
  });
}
