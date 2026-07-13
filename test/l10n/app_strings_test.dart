import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';

void main() {
  test('Chinese playback speed label uses photos', () {
    final strings = AppStrings.from(
      const AppSettings(language: AppLanguage.chinese),
    );

    expect(strings.playbackSpeed(0.6), '播放速度 0.6 秒/张');
  });

  test('English operation panel labels are localized', () {
    final strings = AppStrings.from(
      const AppSettings(language: AppLanguage.english),
    );

    expect(strings.canvasTheme, 'Canvas theme');
    expect(strings.customCanvasImage, 'Custom canvas image');
    expect(strings.backgroundMusicAdded, 'Background music added');
    expect(strings.musicPlaybackFailed, 'Unable to play the background music');
    expect(strings.stickerPanelHint, startsWith('Choose a small object'));
    expect(strings.stickerRotation, 'Rotation');
    expect(
      strings.deleteStickerOnCanvas,
      'Tap the cross on the canvas to delete',
    );
    expect(strings.orbitLayout, 'Orbit');
    expect(strings.orbFrame, 'Circle');
    expect(strings.classicFrames, 'Classic');
    expect(strings.handDrawnFrames, 'Hand-drawn');
    expect(strings.tapedPaperFrame, 'Taped paper');
    expect(strings.crayonFrame, 'Oil pastel');
    expect(strings.watercolorFrame, 'Watercolor bloom');
    expect(strings.doodleTapeFrame, 'Playful doodle');
    expect(strings.scallopFrame, 'Looped lace');
    expect(strings.cornerSketchFrame, 'Corner sketch');
    expect(strings.wavyFrame, 'Wavy outline');
    expect(strings.starfieldCanvas, 'Starfield canvas');
    expect(strings.quickAccess, 'Shortcuts');
    expect(strings.libraryCategories, 'Categories');
    expect(strings.changeHomeHero, 'Change cover');
    expect(strings.homeAppearance, 'Home appearance');
    expect(strings.homeCover, 'Home cover');
    expect(strings.restoreDefaultHomeHero, 'Use the default cover');
    expect(strings.close, 'Close');
    expect(strings.importImagesWithCapacity(6), 'Import 6/16');
    expect(strings.galleryCapacityMessage(2), contains('2 extra photos'));
  });
}
