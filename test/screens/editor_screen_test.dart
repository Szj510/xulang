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
}
