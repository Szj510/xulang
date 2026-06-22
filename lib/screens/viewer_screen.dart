import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/narrative_camera_controller.dart';
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
  final PageController _chapters = PageController();
  int _chapterIndex = 0;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _bundle = ref.read(galleryRepositoryProvider).load(widget.exhibitionId);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _chapters.dispose();
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
          final chapters = bundle.document.chapters
              .where((chapter) => chapter.placements.isNotEmpty)
              .toList(growable: false);
          if (chapters.isEmpty) {
            return _ViewerMessage(
              onBack: () => Navigator.pop(context),
              text: '先导入图片，再开始观看',
            );
          }
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _showChrome = !_showChrome),
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _chapters,
                    scrollDirection: Axis.vertical,
                    itemCount: chapters.length,
                    onPageChanged: (value) =>
                        setState(() => _chapterIndex = value),
                    itemBuilder: (context, index) => _ViewerChapter(
                      key: ValueKey(chapters[index].id),
                      chapter: chapters[index],
                      media: bundle.media,
                      sceneTheme: bundle.document.theme,
                      reduceMotion: MediaQuery.disableAnimationsOf(context),
                      showControls: _showChrome,
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: !_showChrome,
                  child: AnimatedOpacity(
                    opacity: _showChrome ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: _ViewerChrome(
                      document: bundle.document,
                      chapter:
                          chapters[_chapterIndex.clamp(0, chapters.length - 1)],
                      chapterIndex: _chapterIndex,
                      chapterCount: chapters.length,
                      onClose: () => Navigator.pop(context),
                      onPreviousChapter: _chapterIndex == 0
                          ? null
                          : () => _chapters.previousPage(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                            ),
                      onNextChapter: _chapterIndex == chapters.length - 1
                          ? null
                          : () => _chapters.nextPage(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
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
}

class _ViewerChapter extends StatefulWidget {
  const _ViewerChapter({
    super.key,
    required this.chapter,
    required this.media,
    required this.sceneTheme,
    required this.reduceMotion,
    required this.showControls,
  });

  final GalleryChapter chapter;
  final List<GalleryMedia> media;
  final GalleryTheme sceneTheme;
  final bool reduceMotion;
  final bool showControls;

  @override
  State<_ViewerChapter> createState() => _ViewerChapterState();
}

class _ViewerChapterState extends State<_ViewerChapter>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _inertia;
  final TransformationController _transform = TransformationController();
  final NarrativeCameraController _camera = NarrativeCameraController();
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
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _applyInertia() {
    final raw = _inertia.value;
    _camera.setProgress(_camera.clampSimulationValue(raw));
    if (raw < 0 || raw > 1) _inertia.stop();
  }

  void _readScale() {
    final value = _transform.value.getMaxScaleOnAxis();
    if ((value - scale).abs() > .01 && mounted) {
      setState(() => scale = value);
      _camera.setScale(value);
    }
  }

  void _beginTrackDrag(DragStartDetails details) {
    _inertia.stop();
    _camera.begin(scale: scale);
  }

  void _updateTrackDrag(DragUpdateDetails details) {
    _camera.update(
      delta: details.delta,
      viewport: MediaQuery.sizeOf(context),
      itemCount: widget.chapter.placements.length,
      scale: scale,
    );
  }

  void _endTrackDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    _camera.end();
    if (velocity.abs() < 60 || widget.reduceMotion) return;
    final simulation = _camera.simulationForVelocity(
      pixelsPerSecond: velocity,
      viewportWidth: MediaQuery.sizeOf(context).width,
      itemCount: widget.chapter.placements.length,
    );
    _inertia.animateWith(simulation);
  }

  void _animateToNeighbor(int delta) {
    if (scale > 1.01 || widget.chapter.placements.length < 2) return;
    final last = widget.chapter.placements.length - 1;
    final rawIndex = _camera.progress * last;
    final targetIndex = delta > 0
        ? (rawIndex.floor() + 1).clamp(0, last)
        : (rawIndex.ceil() - 1).clamp(0, last);
    final target = targetIndex / last;
    _inertia.value = _camera.progress;
    _inertia.animateTo(
      target,
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
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
            onHorizontalDragStart: scale <= 1.01 ? _beginTrackDrag : null,
            onHorizontalDragUpdate: scale <= 1.01 ? _updateTrackDrag : null,
            onHorizontalDragEnd: scale <= 1.01 ? _endTrackDrag : null,
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
            bottom: MediaQuery.paddingOf(context).bottom + 78,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.chapter.layout == GalleryLayout.storyPath) ...[
                  IconButton.filledTonal(
                    tooltip: '回到全景',
                    onPressed: _camera.progress <= .001
                        ? null
                        : _camera.resetOverview,
                    icon: const Icon(Icons.fit_screen_outlined),
                  ),
                  const SizedBox(width: 10),
                ],
                IconButton.filledTonal(
                  tooltip: '上一项',
                  onPressed: _camera.progress <= .001
                      ? null
                      : () => _animateToNeighbor(-1),
                  icon: const Icon(Icons.arrow_back),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '进度 ${(_camera.progress * 100).round()}%',
                    key: const Key('viewer-track-progress'),
                    style: const TextStyle(
                      color: XulangColors.paper,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '下一项',
                  onPressed: _camera.progress >= .999
                      ? null
                      : () => _animateToNeighbor(1),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
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
  });

  final GalleryDocument document;
  final GalleryChapter chapter;
  final int chapterIndex;
  final int chapterCount;
  final VoidCallback onClose;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(width: 48),
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
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
          Positioned(
            left: 10,
            top: MediaQuery.sizeOf(context).height * .53,
            child: IconButton(
              tooltip: '下一章',
              onPressed: onNextChapter,
              icon: const Icon(Icons.keyboard_arrow_down),
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
