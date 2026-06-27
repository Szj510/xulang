import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_camera_controller.dart';
import 'package:xulang/layout/narrative_navigation_coordinator.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/recording/native_screen_recorder.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/scene_canvas.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({
    super.key,
    required this.exhibitionId,
    this.autoStartRecording = false,
  });

  final String exhibitionId;
  final bool autoStartRecording;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  late Future<GalleryBundle?> _bundle;
  final Map<String, double> _chapterProgress = {};
  int _chapterIndex = 0;
  int _slideDirection = 1;
  bool _showChrome = true;
  bool _recordingMode = false;
  double _recordingSpeed = 6.0;
  bool _musicPlaying = false;
  bool _changingChapter = false;
  bool _playbackFinished = false;
  bool _autoRecordingQueued = false;
  bool _recordingShareBusy = false;
  String? _activeRecordingPath;
  String? _recordingShareTitle;
  RecordingChapterMode _activeRecordingChapterMode =
      RecordingChapterMode.current;
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
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
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
          if (widget.autoStartRecording && !_autoRecordingQueued) {
            _autoRecordingQueued = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _recordingMode) return;
              unawaited(_setRecordingMode(bundle.document, appSettings, true));
            });
          }
          final chapterIndex = _chapterIndex.clamp(0, chapters.length - 1);
          final chapter = chapters[chapterIndex];
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _recordingMode
                ? null
                : () => setState(() => _showChrome = !_showChrome),
            onDoubleTap: _recordingMode && _playbackFinished
                ? () => unawaited(_restoreChromeAfterPlayback())
                : null,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? const Duration(milliseconds: 120)
                        : const Duration(milliseconds: 320),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final isNewWidget = child.key == ValueKey(chapter.id);
                          final axis = NarrativeAxis.fromViewport(
                            MediaQuery.sizeOf(context),
                          );
                          final direction = _slideDirection;

                          final Offset beginOffset;
                          final Offset endOffset;

                          if (axis == NarrativeAxis.vertical) {
                            if (isNewWidget) {
                              beginOffset = Offset(0.0, direction * 0.15);
                              endOffset = Offset.zero;
                            } else {
                              beginOffset = Offset.zero;
                              endOffset = Offset(0.0, -direction * 0.15);
                            }
                          } else {
                            if (isNewWidget) {
                              beginOffset = Offset(direction * 0.15, 0.0);
                              endOffset = Offset.zero;
                            } else {
                              beginOffset = Offset.zero;
                              endOffset = Offset(-direction * 0.15, 0.0);
                            }
                          }

                          final curve = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );

                          return FadeTransition(
                            opacity: curve,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: beginOffset,
                                end: endOffset,
                              ).animate(curve),
                              child: child,
                            ),
                          );
                        },
                    child: _ViewerChapter(
                      key: ValueKey(chapter.id),
                      chapter: chapter,
                      media: bundle.media,
                      sceneTheme: bundle.document.theme,
                      reduceMotion: MediaQuery.disableAnimationsOf(context),
                      showControls: _showChrome && !_recordingMode,
                      recordingMode: _recordingMode,
                      recordingSpeed: _recordingSpeed,
                      initialProgress: _chapterProgress[chapter.id] ?? 0,
                      hasPreviousChapter: chapterIndex > 0,
                      hasNextChapter: chapterIndex < chapters.length - 1,
                      onProgressChanged: (progress) =>
                          _chapterProgress[chapter.id] = progress,
                      onChapterIntent: (intent) =>
                          _changeChapter(chapters, intent),
                      onPlaybackCompleted: () =>
                          _handlePlaybackCompleted(chapters),
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
                        onStartRecording: () => _setRecordingMode(
                          bundle.document,
                          appSettings,
                          true,
                        ),
                        onToggleMusic: bundle.document.musicPath == null
                            ? null
                            : () => _toggleMusic(bundle.document),
                        onRecordingSpeedChanged: (v) =>
                            setState(() => _recordingSpeed = v),
                        musicPlaying: _musicPlaying,
                      ),
                    ),
                  ),
                if (_recordingMode && appSettings.recordingShowChapterTitle)
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
                          fontFamily: 'Noto Serif SC',
                          fontFamilyFallback: [
                            'Noto Sans SC',
                            'PingFang SC',
                            'Microsoft YaHei',
                          ],
                          fontSize: 18,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
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
      _slideDirection = delta;
      _chapterIndex = target;
    });
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 240),
    );
    if (mounted) setState(() => _changingChapter = false);
  }

  Future<void> _setRecordingMode(
    GalleryDocument document,
    AppSettings appSettings,
    bool enabled,
  ) async {
    if (enabled) {
      final options = await _showRecordingOptions(document, appSettings);
      if (options == null) return;
      await ref
          .read(galleryRepositoryProvider)
          .saveAppSettings(
            appSettings.copyWith(
              recordingChapterMode: options.chapterMode,
              recordingSpeed: options.speed,
              recordingUseMusic: options.useMusic,
            ),
          );
      if (!mounted) return;
      final recordingPath = await _startNativeRecording(document);
      if (recordingPath == null) return;
      setState(() {
        _activeRecordingPath = recordingPath;
        _recordingShareTitle = document.title;
        _recordingSpeed = options.speed;
        _recordingMode = true;
        _playbackFinished = false;
        _showChrome = false;
        _activeRecordingChapterMode = options.chapterMode;
        _chapterIndex = _recordingStartIndex(
          currentIndex: _chapterIndex,
          mode: options.chapterMode,
        );
      });
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (options.useMusic && document.musicPath != null) {
        await _playMusic(document);
      }
      return;
    }

    await _stopNativeRecording(share: false);
    if (mounted) {
      setState(() {
        _recordingMode = false;
        _showChrome = true;
        _playbackFinished = false;
      });
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _restoreChromeAfterPlayback() async {
    await _stopNativeRecording(share: false);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) {
      setState(() {
        _recordingMode = false;
        _showChrome = true;
        _playbackFinished = false;
      });
    }
  }

  void _handlePlaybackCompleted(List<GalleryChapter> chapters) {
    if (!mounted || _playbackFinished) return;
    if (_recordingMode) {
      final endIndex = _recordingEndIndex(
        chapterCount: chapters.length,
        currentIndex: _chapterIndex,
        mode: _activeRecordingChapterMode,
      );
      if (_chapterIndex < endIndex) {
        setState(() {
          _slideDirection = 1;
          _chapterIndex += 1;
        });
        return;
      }
      setState(() => _playbackFinished = true);
      unawaited(_stopNativeRecording(share: true));
      return;
    }
    setState(() => _playbackFinished = true);
  }

  Future<String?> _startNativeRecording(GalleryDocument document) async {
    if (!Platform.isAndroid) {
      _showRecorderMessage('当前自动录屏仅支持 Android；可使用系统录屏后再分享。');
      return null;
    }
    try {
      final physicalSize = View.of(context).physicalSize;
      final directory = Directory(
        p.join((await getTemporaryDirectory()).path, 'xulang-recordings'),
      );
      await directory.create(recursive: true);
      final fileName =
          'xulang-${document.id}-${DateTime.now().millisecondsSinceEpoch}.mp4';
      final outputPath = p.join(directory.path, fileName);
      return NativeScreenRecorder.start(
        outputPath: outputPath,
        width: physicalSize.width.round(),
        height: physicalSize.height.round(),
      );
    } on PlatformException catch (error) {
      _showRecorderMessage(error.message ?? '无法开始录屏');
      return null;
    } catch (error) {
      _showRecorderMessage('无法开始录屏：$error');
      return null;
    }
  }

  Future<void> _stopNativeRecording({required bool share}) async {
    final path = _activeRecordingPath;
    if (path == null || _recordingShareBusy) return;
    _recordingShareBusy = true;
    try {
      final stoppedPath = await NativeScreenRecorder.stop();
      final videoPath = stoppedPath ?? path;
      if (share && mounted && await File(videoPath).exists()) {
        await SharePlus.instance.share(
          ShareParams(
            text: '${_recordingShareTitle ?? '叙廊'} 录制视频',
            files: [XFile(videoPath)],
          ),
        );
      } else if (share) {
        _showRecorderMessage('录制结束，但没有找到生成的视频文件。');
      }
    } on PlatformException catch (error) {
      if (share) _showRecorderMessage(error.message ?? '录屏结束失败');
    } catch (error) {
      if (share) _showRecorderMessage('录屏结束失败：$error');
    } finally {
      _activeRecordingPath = null;
      _recordingShareBusy = false;
      if (mounted) {
        setState(() {
          _recordingMode = false;
          _showChrome = true;
        });
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _showRecorderMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _recordingStartIndex({
    required int currentIndex,
    required RecordingChapterMode mode,
  }) {
    return switch (mode) {
      RecordingChapterMode.all => 0,
      RecordingChapterMode.current ||
      RecordingChapterMode.fromCurrentToEnd => currentIndex,
    };
  }

  int _recordingEndIndex({
    required int chapterCount,
    required int currentIndex,
    required RecordingChapterMode mode,
  }) {
    return switch (mode) {
      RecordingChapterMode.current => currentIndex,
      RecordingChapterMode.fromCurrentToEnd ||
      RecordingChapterMode.all => chapterCount - 1,
    };
  }

  Future<_RecordingOptions?> _showRecordingOptions(
    GalleryDocument document,
    AppSettings settings,
  ) {
    var chapterMode = settings.recordingChapterMode;
    var speed = settings.recordingSpeed;
    var useMusic = settings.recordingUseMusic && document.musicPath != null;
    return showModalBottomSheet<_RecordingOptions>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '录制与分享',
                  style: TextStyle(
                    color: XulangColors.paper,
                    fontFamily: 'Noto Serif SC',
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '确认后会进入沉浸播放。Android 原生自动录屏接入后，会在播放结束时自动生成视频并弹出系统分享面板。',
                  style: TextStyle(
                    color: XulangColors.muted,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                const Text('章节范围'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final mode in RecordingChapterMode.values)
                      ChoiceChip(
                        selected: chapterMode == mode,
                        label: Text(_recordingChapterModeLabel(mode)),
                        onSelected: (_) =>
                            setSheetState(() => chapterMode = mode),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('播放速度 ${speed.toStringAsFixed(1)} 秒/章'),
                Slider(
                  value: speed,
                  min: 1,
                  max: 12,
                  divisions: 22,
                  label: '${speed.toStringAsFixed(1)} 秒/章',
                  onChanged: (value) => setSheetState(() => speed = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: useMusic,
                  onChanged: document.musicPath == null
                      ? null
                      : (value) => setSheetState(() => useMusic = value),
                  title: const Text('使用背景音乐'),
                  subtitle: Text(document.musicTitle ?? '当前展览没有背景音乐'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('取消'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        _RecordingOptions(
                          chapterMode: chapterMode,
                          speed: speed,
                          useMusic: useMusic,
                        ),
                      ),
                      icon: const Icon(Icons.videocam_outlined, size: 18),
                      label: const Text('开始录制播放'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _RecordingOptions {
  const _RecordingOptions({
    required this.chapterMode,
    required this.speed,
    required this.useMusic,
  });

  final RecordingChapterMode chapterMode;
  final double speed;
  final bool useMusic;
}

String _recordingChapterModeLabel(RecordingChapterMode mode) => switch (mode) {
  RecordingChapterMode.current => '当前章节',
  RecordingChapterMode.fromCurrentToEnd => '从当前到结尾',
  RecordingChapterMode.all => '全部章节',
};

class _ViewerChapter extends StatefulWidget {
  const _ViewerChapter({
    super.key,
    required this.chapter,
    required this.media,
    required this.sceneTheme,
    required this.reduceMotion,
    required this.showControls,
    this.recordingMode = false,
    this.recordingSpeed = 6.0,
    required this.initialProgress,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    required this.onProgressChanged,
    required this.onChapterIntent,
    required this.onPlaybackCompleted,
  });

  final bool recordingMode;
  final double recordingSpeed;

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
  final VoidCallback onPlaybackCompleted;

  @override
  State<_ViewerChapter> createState() => _ViewerChapterState();
}

class _ViewerChapterState extends State<_ViewerChapter>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _inertia;
  late final AnimationController _recorder;
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
    _recorder = AnimationController(vsync: this)
      ..addListener(() {
        final v = _recorder.value.clamp(0.0, 1.0);
        _camera.setProgress(v);
        widget.onProgressChanged(_camera.progress);
      })
      ..addStatusListener(_handleRecorderStatus);
    _transform.addListener(_readScale);
    _camera.addListener(_rebuild);
    _camera.setProgress(widget.initialProgress);
  }

  void _handleRecorderStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.recordingMode) {
      widget.onPlaybackCompleted();
    }
  }

  @override
  void didUpdateWidget(covariant _ViewerChapter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.recordingMode && widget.recordingMode) {
      _recorder.stop();
      _recorder.reset();
      final durationMs = (widget.recordingSpeed * 1000).round();
      _recorder.animateTo(
        1.0,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
    } else if (oldWidget.recordingMode && !widget.recordingMode) {
      _recorder.stop();
    }
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
    _recorder.removeStatusListener(_handleRecorderStatus);
    _camera.removeListener(_rebuild);
    _camera.dispose();
    _transform.dispose();
    _inertia.dispose();
    _recorder.dispose();
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
            bottom: widget.chapter.caption.isNotEmpty
                ? MediaQuery.paddingOf(context).bottom + 84
                : MediaQuery.paddingOf(context).bottom + 22,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .08),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '进度 ${(_camera.progress * 100).round()}%',
                      key: const Key('viewer-track-progress'),
                      style: const TextStyle(
                        color: XulangColors.paper,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
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
    this.onRecordingSpeedChanged,
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
  final ValueChanged<double>? onRecordingSpeedChanged;
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
            height: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .50),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ChromeGlassCircle(
                  child: _ChromeIconButton(
                    onPressed: onClose,
                    tooltip: '退出观看',
                    icon: Icons.close,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ChromeGlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            document.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: XulangColors.paper,
                              fontFamily: 'Noto Serif SC',
                              fontFamilyFallback: [
                                'Noto Sans SC',
                                'PingFang SC',
                                'Microsoft YaHei',
                              ],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${chapterIndex + 1} / $chapterCount · ${chapter.title}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: XulangColors.muted,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _ChromeGlassPill(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ChromeIconButton(
                        key: const Key('viewer-recording-mode'),
                        onPressed: onStartRecording,
                        tooltip: '录屏模式',
                        icon: Icons.videocam_outlined,
                      ),
                      PopupMenuButton<double>(
                        tooltip: '录屏速度',
                        icon: const Icon(
                          Icons.speed,
                          size: 18,
                          color: XulangColors.paper,
                        ),
                        onSelected: (v) => onRecordingSpeedChanged?.call(v),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 3.0,
                            child: Text('快 (3s)'),
                          ),
                          const PopupMenuItem(
                            value: 6.0,
                            child: Text('中 (6s)'),
                          ),
                          const PopupMenuItem(
                            value: 10.0,
                            child: Text('慢 (10s)'),
                          ),
                        ],
                      ),
                      if (onToggleMusic != null)
                        _ChromeIconButton(
                          key: const Key('viewer-music-toggle'),
                          onPressed: onToggleMusic,
                          tooltip: musicPlaying ? '暂停音乐' : '播放音乐',
                          icon: musicPlaying
                              ? Icons.music_off_outlined
                              : Icons.music_note_outlined,
                        ),
                    ],
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        key: const Key('viewer-caption-scrim'),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .50),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .08),
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          chapter.caption,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: XulangColors.paper,
                            fontFamily: 'Noto Serif SC',
                            fontFamilyFallback: [
                              'Noto Sans SC',
                              'PingFang SC',
                              'Microsoft YaHei',
                            ],
                            fontSize: 13.5,
                            letterSpacing: 0.8,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            top: MediaQuery.sizeOf(context).height * .44,
            child: _ChromeNavButton(
              tooltip: '上一章',
              onPressed: onPreviousChapter,
              icon: previousChapterIcon,
            ),
          ),
          Positioned(
            left: 8,
            top: MediaQuery.sizeOf(context).height * .52,
            child: _ChromeNavButton(
              tooltip: '下一章',
              onPressed: onNextChapter,
              icon: nextChapterIcon,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeGlassCircle extends StatelessWidget {
  const _ChromeGlassCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _ChromeGlassPill extends StatelessWidget {
  const _ChromeGlassPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: onPressed == null
                  ? XulangColors.muted.withValues(alpha: .35)
                  : XulangColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChromeNavButton extends StatelessWidget {
  const _ChromeNavButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onPressed == null ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: onPressed == null,
        child: Tooltip(
          message: tooltip,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .08),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(icon, size: 22, color: XulangColors.paper),
                  ),
                ),
              ),
            ),
          ),
        ),
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
            child: _ChromeIconButton(
              onPressed: onBack,
              tooltip: '返回',
              icon: Icons.close,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  size: 32,
                  color: XulangColors.muted,
                ),
                const SizedBox(height: 16),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: XulangColors.paper,
                    fontSize: 15,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
