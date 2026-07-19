import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/screens/viewer_screen.dart';

void main() {
  test('speed menu labels show seconds per photo', () {
    final l10n = AppStrings.from(
      const AppSettings(language: AppLanguage.chinese),
    );

    expect(l10n.fast3s, '快（1秒/张）');
    expect(l10n.medium6s, '中（3秒/张）');
    expect(l10n.slow10s, '慢（6秒/张）');
  });

  test('recording playback duration is based on image count', () {
    const chapter = GalleryChapter(
      id: 'chapter',
      title: 'Chapter',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [
        GalleryPlacement(id: 'p1', mediaId: 'm1', order: 0),
        GalleryPlacement(id: 'p2', mediaId: 'm2', order: 1),
        GalleryPlacement(id: 'p3', mediaId: 'm3', order: 2),
      ],
    );

    expect(
      playbackDurationForChapter(chapter: chapter, secondsPerPhoto: 2.5),
      const Duration(milliseconds: 7500),
    );
  });

  test('recording playback duration keeps a minimum for empty chapters', () {
    const chapter = GalleryChapter(
      id: 'empty',
      title: 'Empty',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [],
    );

    expect(
      playbackDurationForChapter(chapter: chapter, secondsPerPhoto: 0.2),
      const Duration(milliseconds: 200),
    );
  });

  test('recording playback duration supports sub-second per photo speed', () {
    const chapter = GalleryChapter(
      id: 'chapter',
      title: 'Chapter',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [GalleryPlacement(id: 'p1', mediaId: 'm1', order: 0)],
    );

    expect(
      playbackDurationForChapter(chapter: chapter, secondsPerPhoto: 0.5),
      const Duration(milliseconds: 500),
    );
  });

  test('viewer playback music is independent from the recording option', () {
    expect(
      shouldPlayViewerBackgroundMusic(
        musicPath: '/music/theme.mp3',
        isRecording: false,
        recordingUseMusic: false,
      ),
      isTrue,
    );
  });

  test('recording music still respects the recording option', () {
    expect(
      shouldPlayViewerBackgroundMusic(
        musicPath: '/music/theme.mp3',
        isRecording: true,
        recordingUseMusic: false,
      ),
      isFalse,
    );
    expect(
      shouldPlayViewerBackgroundMusic(
        musicPath: null,
        isRecording: false,
        recordingUseMusic: true,
      ),
      isFalse,
    );
  });
}
