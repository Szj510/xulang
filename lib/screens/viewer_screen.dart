import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_camera_controller.dart';
import 'package:xulang/layout/narrative_navigation_coordinator.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/scene_canvas.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key, required this.exhibitionId});

  final String exhibitionId;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  late Future<GalleryBundle?> _bundle;
  final Map<String, double> _chapterProgress = {};
  int _chapterIndex = 0;
  bool _showChrome = true;
  bool _recordingMode = false;
  bool _musicPlaying = false;
  bool _changingChapter = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingMusicPath;

  @override
  void initState() {
    super.initState();
    _bundle = ref.read(galleryRepositoryProvider).load(widget.exhibitionId);
    unawaited(_audioPlayer.setReleaseMode(ReleaseMode.loop));
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(_audioPlayer.dispose());
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<GalleryBundle?>(
        future: _bundle,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final bundle = snapshot.data;
          if (bundle == null) {
            return _ViewerMessage(
              onBack: () => Navigator.pop(context),
              text: '找不到这个展览',
            );
          }
          final chapters = bundle.document.chapters;
          if (chapters.every((chapter) => chapter.placements.isEmpty)) {
            return _ViewerMessage(
              onBack: () => Navigator.pop(context),
              text: '先导入图片，再开始观看',
            );
          }
          final chapterIndex = _chapterIndex.clamp(0, chapters.length - 1);
          final chapter = chapters[chapterIndex];
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _recordingMode
                ? null
                : () => setState(() => _showChrome = !_showChrome),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? const Duration(milliseconds: 120)
                        : const Duration(milliseconds: 240),
                    child: _ViewerChapter(
                      key: ValueKey(chapter.id),
                      chapter: chapter,
                      media: bundle.media,
                      sceneTheme: bundle.document.theme,
                      reduceMotion: MediaQuery.disableAnimationsOf(context),
                      showControls: _showChrome && !_recordingMode,
                      initialProgress: _chapterProgress[chapter.id] ?? 0,
                      hasPreviousChapter: chapterIndex > 0,
                      hasNextChapter: chapterIndex < chapters.length - 1,
                      onProgressChanged: (progress) =>
                          _chapterProgress[chapter.id] = progress,
                      onChapterIntent: (intent) =>
                          _changeChapter(chapters, intent),
                    ),
                  ),
                ),
                if (!_recordingMode)
                  IgnorePointer(
                    ignoring: !_showChrome,
                    child: AnimatedOpacity(
                      opacity: _showChrome ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: _ViewerChrome(
                        document: bundle.document,
                        chapter: chapter,
                        chapterIndex: chapterIndex,
                        chapterCount: chapters.length,
                        onClose: () => Navigator.pop(context),
                        onPreviousChapter: chapterIndex == 0
                            ? null
                            : () => _changeChapter(
                                chapters,
                                ChapterNavigationIntent.previous,
                              ),
                        onNextChapter: chapterIndex == chapters.length - 1
                            ? null
                            : () => _changeChapter(
                                chapters,
                                ChapterNavigationIntent.next,
                              ),
                        onStartRecording: () =>
                            _setRecordingMode(bundle.document, true),
                        onToggleMusic: bundle.document.musicPath == null
                            ? null
                            : () => _toggleMusic(bundle.document),
                        musicPlaying: _musicPlaying,
                      ),
                    ),
                  ),
                if (_recordingMode &&
                    bundle.document.showChapterTitleInPlayback)
                  Positioned(
                    key: const Key('viewer-recording-chapter-title'),
                    top: MediaQuery.paddingOf(context).top + 18,
                    left: 24,
                    right: 24,
                    child: IgnorePointer(
                      child: Text(
                        chapter.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: XulangColors.paper,
                          fontFamily: 'serif',
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeChapter(
    List<GalleryChapter> chapters,
    ChapterNavigationIntent intent,
  ) async {
    if (_changingChapter || intent == ChapterNavigationIntent.none) return;
    final delta = intent == ChapterNavigationIntent.next ? 1 : -1;
    final target = _chapterIndex + delta;
    if (target < 0 || target >= chapters.length) return;
    setState(() {
      _changingChapter = true;
      _chapterIndex = target;
    });
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 240),
    );
    if (mounted) setState(() => _changingChapter = false);
  }

  Future<void> _setRecordingMode(GalleryDocument document, bool enabled) async {
    if (mounted) {
      setState(() {
        _recordingMode = enabled;
        if (enabled) _showChrome = false;
      });
    }
    if (enabled) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (document.musicPath != null) {
        await _playMusic(document);
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _toggleMusic(GalleryDocument document) async {
    if (_musicPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _musicPlaying = false);
    } else {
      await _playMusic(document);
    }
  }

  Future<void> _playMusic(GalleryDocument document) async {
    final path = document.musicPath;
    if (path == null) return;
    if (_playingMusicPath != path) {
      _playingMusicPath = path;
      await _audioPlayer.play(DeviceFileSource(path));
    } else {
      await _audioPlayer.resume();
    }
    if (mounted) setState(() => _musicPlaying = true);
  }
}

class _ViewerChapter extends StatefulWidget {
  const _ViewerChapter({
    super.key,
    required this.chapter,
    required this.media,
    required this.sceneTheme,
    required this.reduceMotion,
    required this.showControls,
    required this.initialProgress,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    required this.onProgressChanged,
    required this.onChapterIntent,
  });

  final GalleryChapter chapter;
  final List<GalleryMedia> media;
  final GalleryTheme sceneTheme;
  final bool reduceMotion;
  final bool showControls;
  final double initialProgress;
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<ChapterNavigationIntent> onChapterIntent;

  @override
  State<_ViewerChapter> createState() => _ViewerChapterState();
}

class _ViewerChapterState extends State<_ViewerChapter>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _inertia;
  final TransformationController _transform = TransformationController();
  final NarrativeCameraController _camera = NarrativeCameraController();
  final NarrativeNavigationCoordinator _navigation =
      NarrativeNavigationCoordinator();
  Size? _lastViewport;
  bool _sentChapterIntent = false;
  double scale = 1;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 720),
    )..forward();
    _inertia = AnimationController.unbounded(vsync: this)
      ..addListener(_applyInertia);
    _transform.addListener(_readScale);
    _camera.addListener(_rebuild);
    _camera.setProgress(widget.initialProgress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebaseTransform(MediaQuery.sizeOf(context));
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _applyInertia() {
    final raw = _inertia.value;
    _camera.setProgress(_camera.clampSimulationValue(raw));
    widget.onProgressChanged(_camera.progress);
    if (raw < 0 || raw > 1) _inertia.stop();
  }

  void _readScale() {
    final value = _transform.value.getMaxScaleOnAxis();
    if ((value - scale).abs() > .01 && mounted) {
      setState(() => scale = value);
      _camera.setScale(value);
    }
  }

  void _beginPan(DragStartDetails details) {
    _inertia.stop();
    final axis = NarrativeAxis.fromViewport(MediaQuery.sizeOf(context));
    _camera.begin(scale: scale);
    _navigation.begin(
      progress: _camera.progress,
      axis: axis,
      itemCount: widget.chapter.placements.length,
    );
    _sentChapterIntent = false;
  }

  void _updatePan(DragUpdateDetails details) {
    final viewport = MediaQuery.sizeOf(context);
    final axis = NarrativeAxis.fromViewport(viewport);
    final gesture = _camera.update(
      delta: details.delta,
      viewport: viewport,
      itemCount: widget.chapter.placements.length,
      scale: scale,
      axis: axis,
    );
    widget.onProgressChanged(_camera.progress);
    final intent = _navigation.update(details.delta, gesture);
    if (intent != ChapterNavigationIntent.none) {
      _sentChapterIntent = true;
      widget.onChapterIntent(intent);
    }
  }

  void _endPan(DragEndDetails details) {
    final viewport = MediaQuery.sizeOf(context);
    final axis = NarrativeAxis.fromViewport(viewport);
    final direction = _camera.direction;
    _camera.end();
    _navigation.end();
    final expected = axis == NarrativeAxis.vertical
        ? GalleryGesture.vertical
        : GalleryGesture.horizontal;
    if (_sentChapterIntent || direction != expected || widget.reduceMotion) {
      return;
    }
    if (axis == NarrativeAxis.vertical) return;
    final velocity = axis.primaryOffset(details.velocity.pixelsPerSecond);
    if (velocity.abs() < 60) return;
    final simulation = _camera.simulationForVelocity(
      pixelsPerSecond: velocity,
      viewport: viewport,
      itemCount: widget.chapter.placements.length,
      axis: axis,
    );
    _inertia.value = _camera.progress;
    _inertia.animateWith(simulation);
  }

  void _cancelPan() {
    _camera.end();
    _navigation.end();
  }

  void _rebaseTransform(Size nextViewport) {
    final previous = _lastViewport;
    _lastViewport = nextViewport;
    if (previous == null || previous == nextViewport) return;
    _inertia.stop();
    _camera.end();
    _navigation.end();
    final matrix = _transform.value.clone();
    final translation = matrix.getTranslation();
    matrix.setTranslationRaw(
      previous.width <= 0
          ? translation.x
          : translation.x / previous.width * nextViewport.width,
      previous.height <= 0
          ? translation.y
          : translation.y / previous.height * nextViewport.height,
      translation.z,
    );
    _transform.value = matrix;
  }

  @override
  void dispose() {
    _transform.removeListener(_readScale);
    _camera.removeListener(_rebuild);
    _camera.dispose();
    _transform.dispose();
    _inertia.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const Key('narrative-gesture-surface'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: scale <= 1.01 ? _beginPan : null,
            onHorizontalDragUpdate: scale <= 1.01 ? _updatePan : null,
            onHorizontalDragEnd: scale <= 1.01 ? _endPan : null,
            onHorizontalDragCancel: scale <= 1.01 ? _cancelPan : null,
            onVerticalDragStart: scale <= 1.01 ? _beginPan : null,
            onVerticalDragUpdate: scale <= 1.01 ? _updatePan : null,
            onVerticalDragEnd: scale <= 1.01 ? _endPan : null,
            onVerticalDragCancel: scale <= 1.01 ? _cancelPan : null,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 4,
              panEnabled: scale > 1.01,
              child: AnimatedBuilder(
                animation: _entry,
                builder: (context, child) => SceneCanvas(
                  chapter: widget.chapter,
                  media: widget.media,
                  cameraProgress: _camera.progress,
                  progress: Curves.easeOutCubic.transform(_entry.value),
                  reduceMotion: widget.reduceMotion,
                  useOriginals: true,
                  sceneTheme: widget.sceneTheme,
                ),
              ),
            ),
          ),
        ),
        if (widget.showControls)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 22,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Text(
                    '进度 ${(_camera.progress * 100).round()}%',
                    key: const Key('viewer-track-progress'),
                    style: const TextStyle(
                      color: XulangColors.paper,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ViewerChrome extends StatelessWidget {
  const _ViewerChrome({
    required this.document,
    required this.chapter,
    required this.chapterIndex,
    required this.chapterCount,
    required this.onClose,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.onStartRecording,
    required this.onToggleMusic,
    required this.musicPlaying,
  });

  final GalleryDocument document;
  final GalleryChapter chapter;
  final int chapterIndex;
  final int chapterCount;
  final VoidCallback onClose;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback onStartRecording;
  final VoidCallback? onToggleMusic;
  final bool musicPlaying;

  @override
  Widget build(BuildContext context) {
    final axis = NarrativeAxis.fromViewport(MediaQuery.sizeOf(context));
    final previousChapterIcon = axis == NarrativeAxis.vertical
        ? Icons.keyboard_arrow_up
        : Icons.keyboard_arrow_left;
    final nextChapterIcon = axis == NarrativeAxis.vertical
        ? Icons.keyboard_arrow_down
        : Icons.keyboard_arrow_right;
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            key: const Key('viewer-top-scrim'),
            top: 0,
            left: 0,
            right: 0,
            height: 112,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .78),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 18,
            right: 18,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onClose,
                  tooltip: '退出观看',
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          color: XulangColors.paper,
                          fontFamily: 'serif',
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${chapterIndex + 1} / $chapterCount · ${chapter.title}',
                        style: const TextStyle(
                          color: XulangColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('viewer-recording-mode'),
                  onPressed: onStartRecording,
                  tooltip: '录屏模式',
                  icon: const Icon(Icons.videocam_outlined),
                ),
                IconButton.filledTonal(
                  key: const Key('viewer-music-toggle'),
                  onPressed: onToggleMusic,
                  tooltip: musicPlaying ? '暂停音乐' : '播放音乐',
                  icon: Icon(
                    musicPlaying
                        ? Icons.music_off_outlined
                        : Icons.music_note_outlined,
                  ),
                ),
              ],
            ),
          ),
          if (chapter.caption.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: DecoratedBox(
                    key: const Key('viewer-caption-scrim'),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .62),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text(
                        chapter.caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: XulangColors.paper,
                          fontFamily: 'serif',
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 10,
            top: MediaQuery.sizeOf(context).height * .45,
            child: IconButton(
              tooltip: '上一章',
              onPressed: onPreviousChapter,
              icon: Icon(previousChapterIcon),
            ),
          ),
          Positioned(
            left: 10,
            top: MediaQuery.sizeOf(context).height * .53,
            child: IconButton(
              tooltip: '下一章',
              onPressed: onNextChapter,
              icon: Icon(nextChapterIcon),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  const _ViewerMessage({required this.onBack, required this.text});

  final VoidCallback onBack;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(onPressed: onBack, icon: const Icon(Icons.close)),
          ),
          Center(
            child: Text(
              text,
              style: const TextStyle(color: XulangColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}
