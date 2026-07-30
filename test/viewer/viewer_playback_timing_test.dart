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

  test('motion photo duration follows chapter range and playback speed', () {
    final now = DateTime(2026, 7, 30);
    final document = GalleryDocument(
      id: 'gallery',
      title: 'Gallery',
      createdAt: now,
      updatedAt: now,
      chapters: const [
        GalleryChapter(
          id: 'chapter-1',
          title: 'One',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [
            GalleryPlacement(id: 'p1', mediaId: 'm1', order: 0),
            GalleryPlacement(id: 'p2', mediaId: 'm2', order: 1),
          ],
        ),
        GalleryChapter(
          id: 'chapter-2',
          title: 'Two',
          order: 1,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [GalleryPlacement(id: 'p3', mediaId: 'm3', order: 0)],
        ),
      ],
    );

    expect(
      playbackDurationForRange(
        document: document,
        currentIndex: 1,
        mode: RecordingChapterMode.current,
        secondsPerPhoto: 1.5,
      ),
      const Duration(milliseconds: 1500),
    );
    expect(
      playbackDurationForRange(
        document: document,
        currentIndex: 1,
        mode: RecordingChapterMode.all,
        secondsPerPhoto: 2,
      ),
      const Duration(seconds: 6),
    );
  });

  test('estimated playback duration is localized', () {
    final chinese = AppStrings.from(
      const AppSettings(language: AppLanguage.chinese),
    );
    final english = AppStrings.from(
      const AppSettings(language: AppLanguage.english),
    );

    expect(
      chinese.estimatedPlaybackDuration(const Duration(seconds: 75)),
      '预计播放时长：1 分 15 秒',
    );
    expect(
      english.estimatedPlaybackDuration(const Duration(milliseconds: 2500)),
      'Estimated playback: 2.5s',
    );
  });

  test('short recordings wait before finalizing the Android encoder', () {
    final startedAt = DateTime(2026, 7, 30, 12);

    expect(
      recordingFinalizationDelay(
        startedAt: startedAt,
        now: startedAt.add(const Duration(milliseconds: 400)),
      ),
      const Duration(milliseconds: 1200),
    );
    expect(
      recordingFinalizationDelay(
        startedAt: startedAt,
        now: startedAt.add(const Duration(seconds: 2)),
      ),
      Duration.zero,
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
