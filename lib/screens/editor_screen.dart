import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/editor/editor_session.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_camera_controller.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/viewer_screen.dart';
import 'package:xulang/share/export_file_service.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/gallery_image.dart';
import 'package:xulang/widgets/scene_canvas.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key, required this.exhibitionId});

  final String exhibitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(editorSessionProvider(exhibitionId));
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (session.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (session.bundle == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('无法打开展览\n${session.error ?? ''}')),
          );
        }
        return _EditorBody(session: session);
      },
    );
  }
}

class _EditorBody extends StatefulWidget {
  const _EditorBody({required this.session});

  final EditorSession session;

  @override
  State<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends State<_EditorBody> {
  bool _showChapters = false;
  _EditorPanelMode _panelMode = _EditorPanelMode.canvas;
  String? _selectedPlacementId;

  EditorSession get session => widget.session;

  void _focusCanvas() {
    setState(() {
      _panelMode = _EditorPanelMode.canvas;
      _selectedPlacementId = null;
    });
  }

  void _focusPlacement(String placementId) {
    setState(() {
      _panelMode = _EditorPanelMode.placement;
      _selectedPlacementId = placementId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundle = session.bundle!;
    final document = bundle.document;
    final chapter = session.selectedChapter!;
    return OrientationBuilder(
      builder: (context, orientation) {
        final landscape = orientation == Orientation.landscape;
        return Scaffold(
          appBar: landscape
              ? null
              : AppBar(
                  key: const Key('editor-app-bar'),
                  backgroundColor: XulangColors.ink,
                  titleSpacing: 4,
                  title: InkWell(
                    onTap: () => _rename(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            document.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: XulangColors.muted,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: '撤销',
                      onPressed: session.canUndo ? session.undo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: '重做',
                      onPressed: session.canRedo ? session.redo : null,
                      icon: const Icon(Icons.redo),
                    ),
                    IconButton(
                      tooltip: '沉浸观看',
                      onPressed: chapter.placements.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ViewerScreen(exhibitionId: document.id),
                              ),
                            ),
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                    PopupMenuButton<_EditorExportAction>(
                      tooltip: '导出与分享',
                      onSelected: (action) =>
                          _handleExportAction(context, action),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _EditorExportAction.template,
                          child: Text('分享模板'),
                        ),
                        PopupMenuItem(
                          value: _EditorExportAction.importTemplate,
                          child: Text('导入模板'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (landscape) {
                final inspectorWidth = (constraints.maxWidth * .36).clamp(
                  280.0,
                  340.0,
                );
                return Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Preview(
                            session: session,
                            onCanvasTap: () {
                              _hideChapters();
                              _focusCanvas();
                            },
                            onPlacementTap: (placementId) {
                              _hideChapters();
                              _focusPlacement(placementId);
                            },
                          ),
                        ),
                        SizedBox(
                          width: inspectorWidth,
                          child: _Inspector(
                            session: session,
                            panelMode: _panelMode,
                            selectedPlacementId: _selectedPlacementId,
                            onFocusCanvas: _focusCanvas,
                            onFocusPlacement: _focusPlacement,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: SafeArea(
                        child: SizedBox.square(
                          dimension: 48,
                          child: IconButton(
                            tooltip: '返回',
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      child: SafeArea(
                        child: Material(
                          key: const Key('landscape-editor-toolbar'),
                          color: XulangColors.ink.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(24),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: '章节',
                                onPressed: () => setState(
                                  () => _showChapters = !_showChapters,
                                ),
                                icon: const Icon(Icons.view_carousel_outlined),
                              ),
                              IconButton(
                                key: const Key('landscape-editor-undo'),
                                tooltip: '撤销',
                                onPressed: session.canUndo
                                    ? session.undo
                                    : null,
                                icon: const Icon(Icons.undo),
                              ),
                              IconButton(
                                key: const Key('landscape-editor-redo'),
                                tooltip: '重做',
                                onPressed: session.canRedo
                                    ? session.redo
                                    : null,
                                icon: const Icon(Icons.redo),
                              ),
                              IconButton(
                                key: const Key('landscape-editor-play'),
                                tooltip: '沉浸观看',
                                onPressed: chapter.placements.isEmpty
                                    ? null
                                    : () => _play(context),
                                icon: const Icon(Icons.play_arrow_rounded),
                              ),
                              PopupMenuButton<_EditorExportAction>(
                                tooltip: '导出与分享',
                                onSelected: (action) =>
                                    _handleExportAction(context, action),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: _EditorExportAction.template,
                                    child: Text('分享模板'),
                                  ),
                                  PopupMenuItem(
                                    value: _EditorExportAction.importTemplate,
                                    child: Text('导入模板'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_showChapters)
                      Positioned(
                        left: 48,
                        right: 8,
                        top: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 56),
                            child: _ChapterRail(
                              key: const Key('landscape-chapter-overlay'),
                              session: session,
                              onSelected: (index) {
                                session.selectChapter(index);
                                _hideChapters();
                              },
                              onRename: () => _rename(context),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  _ChapterRail(
                    key: const Key('editor-chapter-rail'),
                    session: session,
                  ),
                  Expanded(
                    child: _Preview(
                      session: session,
                      onCanvasTap: _focusCanvas,
                      onPlacementTap: _focusPlacement,
                    ),
                  ),
                  SizedBox(
                    height: 214,
                    child: _Inspector(
                      session: session,
                      panelMode: _panelMode,
                      selectedPlacementId: _selectedPlacementId,
                      onFocusCanvas: _focusCanvas,
                      onFocusPlacement: _focusPlacement,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _hideChapters() {
    if (_showChapters) setState(() => _showChapters = false);
  }

  void _play(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewerScreen(exhibitionId: session.bundle!.document.id),
      ),
    );
  }

  Future<void> _handleExportAction(
    BuildContext context,
    _EditorExportAction action,
  ) async {
    final bundle = session.bundle;
    if (bundle == null) return;
    try {
      final service = await _exportFileService();
      switch (action) {
        case _EditorExportAction.template:
          final file = await service.writeTemplate(bundle.document);
          await service.shareFile(file, title: '${bundle.document.title} 模板');
          if (context.mounted) {
            _showSnack(context, '已生成并打开分享：${p.basename(file.path)}');
          }
        case _EditorExportAction.importTemplate:
          final file = await openFile(
            acceptedTypeGroups: const [
              XTypeGroup(
                label: '叙廊模板',
                extensions: ['json'],
                mimeTypes: ['application/json'],
              ),
            ],
          );
          if (file == null) return;
          await session.applyTemplateJson(await file.readAsString());
          if (context.mounted) _showSnack(context, '已套用模板');
      }
    } catch (caught) {
      if (context.mounted) _showSnack(context, '操作失败：$caught');
    }
  }

  Future<ExportFileService> _exportFileService() async {
    final root = await getApplicationDocumentsDirectory();
    return ExportFileService(
      outputDirectory: Directory(p.join(root.path, 'exports')),
    );
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _rename(BuildContext context) async {
    var title = session.bundle!.document.title;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('展览名称'),
        content: TextFormField(
          initialValue: title,
          autofocus: true,
          onChanged: (next) => title = next,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, title),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value != null) await session.rename(value);
  }
}

enum _EditorExportAction { template, importTemplate }

class _ChapterRail extends StatelessWidget {
  const _ChapterRail({
    super.key,
    required this.session,
    this.onSelected,
    this.onRename,
  });

  final EditorSession session;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final chapters = session.bundle!.document.chapters;
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: XulangColors.surface,
        border: Border(bottom: BorderSide(color: XulangColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              itemCount: chapters.length,
              onReorder: session.moveChapter,
              itemBuilder: (context, index) {
                final selected = index == session.selectedChapterIndex;
                return Padding(
                  key: ValueKey(chapters[index].id),
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    onSelected: (_) =>
                        (onSelected ?? session.selectChapter)(index),
                    label: Text('${index + 1}  ${chapters[index].title}'),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: '添加章节',
            onPressed: session.addChapter,
            icon: const Icon(Icons.add),
          ),
          if (onRename != null)
            IconButton(
              tooltip: '重命名展览',
              onPressed: onRename,
              icon: const Icon(Icons.edit_outlined),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Preview extends StatefulWidget {
  const _Preview({
    required this.session,
    this.onCanvasTap,
    this.onPlacementTap,
  });

  final EditorSession session;
  final VoidCallback? onCanvasTap;
  final ValueChanged<String>? onPlacementTap;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final Map<String, double> _cameraProgressByChapter = {};
  final Map<String, GalleryPlacement> _placementDrafts = {};
  final NarrativeCameraController _cameraController =
      NarrativeCameraController();
  GalleryPlacement? _gestureStartPlacement;

  EditorSession get session => widget.session;
  String get _chapterId => session.selectedChapter!.id;
  double get _cameraProgress => _cameraProgressByChapter[_chapterId] ?? 0;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _setProgress(double value) {
    final next = value.clamp(0.0, 1.0);
    _cameraController.setProgress(next);
    setState(() => _cameraProgressByChapter[_chapterId] = next);
  }

  GalleryChapter _chapterWithDrafts(GalleryChapter chapter) {
    if (_placementDrafts.isEmpty) return chapter;
    return chapter.copyWith(
      placements: [
        for (final placement in chapter.placements)
          _placementDrafts[placement.id] ?? placement,
      ],
    );
  }

  void _startPlacementTransform(String placementId) {
    final chapter = session.selectedChapter;
    if (chapter == null) return;
    GalleryPlacement? placement = _placementDrafts[placementId];
    if (placement == null) {
      for (final item in chapter.placements) {
        if (item.id == placementId) {
          placement = item;
          break;
        }
      }
    }
    _gestureStartPlacement = placement;
  }

  void _updatePlacementTransform(
    String placementId,
    double scaleDelta,
    Offset delta,
    Size viewport,
  ) {
    final start = _gestureStartPlacement;
    if (start == null || start.id != placementId) return;
    final current = _placementDrafts[placementId] ?? start;
    final next = start.copyWith(
      scale: (start.scale * scaleDelta).clamp(.45, 1.9),
      offsetX: (current.offsetX + delta.dx / viewport.width).clamp(-.45, .45),
      offsetY: (current.offsetY + delta.dy / viewport.height).clamp(-.45, .45),
    );
    setState(() => _placementDrafts[placementId] = next);
  }

  Future<void> _endPlacementTransform(String placementId) async {
    final draft = _placementDrafts.remove(placementId);
    _gestureStartPlacement = null;
    if (draft == null) return;
    await session.updatePlacement(
      placementId,
      scale: draft.scale,
      offsetX: draft.offsetX,
      offsetY: draft.offsetY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final landscape =
            NarrativeAxis.fromViewport(viewport) == NarrativeAxis.horizontal;
        final chapter = _chapterWithDrafts(session.selectedChapter!);
        final progress = _cameraProgress;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('editor-preview-gesture-surface'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onCanvasTap,
                onPanStart: (_) {
                  _cameraController.setProgress(_cameraProgress);
                  _cameraController.begin(scale: 1);
                },
                onPanUpdate: (details) {
                  _cameraController.update(
                    delta: details.delta,
                    viewport: viewport,
                    itemCount: chapter.placements.length,
                    scale: 1,
                    axis: NarrativeAxis.fromViewport(viewport),
                  );
                  setState(() {
                    _cameraProgressByChapter[_chapterId] =
                        _cameraController.progress;
                  });
                },
                onPanEnd: (_) => _cameraController.end(),
                onPanCancel: _cameraController.end,
                child: SceneCanvas(
                  chapter: chapter,
                  media: session.bundle!.media,
                  cameraProgress: progress,
                  sceneTheme: session.bundle!.document.theme,
                  onPlacementTap: widget.onPlacementTap,
                  onPlacementTransformStart: _startPlacementTransform,
                  onPlacementTransformUpdate:
                      (placementId, scaleDelta, delta) =>
                          _updatePlacementTransform(
                            placementId,
                            scaleDelta,
                            delta,
                            viewport,
                          ),
                  onPlacementTransformEnd: (placementId) {
                    unawaited(_endPlacementTransform(placementId));
                  },
                ),
              ),
            ),
            if (chapter.placements.length > 1)
              if (landscape)
                Positioned(
                  key: const Key('editor-horizontal-progress'),
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: SafeArea(
                    top: false,
                    child: _ProgressControl(
                      progress: progress,
                      onChanged: _setProgress,
                    ),
                  ),
                )
              else
                Positioned(
                  key: const Key('editor-vertical-progress'),
                  right: 8,
                  top: 76,
                  bottom: 12,
                  child: SafeArea(
                    left: false,
                    child: SizedBox(
                      width: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .62),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _ProgressText(progress: progress),
                            ),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Slider(
                                  key: const Key('editor-camera-slider'),
                                  value: progress,
                                  onChanged: _setProgress,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            Positioned(
              right: landscape ? 14 : 58,
              top: 14,
              child: FilledButton.icon(
                onPressed: session.importing ? null : session.importImages,
                icon: session.importing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(session.importing ? '导入中' : '导入图片'),
              ),
            ),
            if (session.error != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: MaterialBanner(
                  content: Text('${session.error}'),
                  actions: [
                    TextButton(
                      onPressed: session.clearError,
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressControl extends StatelessWidget {
  const _ProgressControl({required this.progress, required this.onChanged});

  final double progress;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.view_in_ar_outlined,
            size: 16,
            color: XulangColors.paper,
          ),
          Expanded(
            child: Slider(
              key: const Key('editor-camera-slider'),
              value: progress,
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 42, child: _ProgressText(progress: progress)),
        ],
      ),
    );
  }
}

class _ProgressText extends StatelessWidget {
  const _ProgressText({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Text(
      key: const Key('editor-camera-progress'),
      '${(progress * 100).round()}%',
      style: const TextStyle(color: XulangColors.paper, fontSize: 11),
    );
  }
}

class _Inspector extends StatefulWidget {
  const _Inspector({
    required this.session,
    required this.panelMode,
    required this.selectedPlacementId,
    required this.onFocusCanvas,
    required this.onFocusPlacement,
  });

  final EditorSession session;
  final _EditorPanelMode panelMode;
  final String? selectedPlacementId;
  final VoidCallback onFocusCanvas;
  final ValueChanged<String> onFocusPlacement;

  @override
  State<_Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<_Inspector> {
  EditorSession get session => widget.session;

  Widget _buildCanvasPanel(BuildContext context, GalleryChapter chapter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PopupMenuButton<GalleryTheme>(
              tooltip: '画布主题',
              initialValue: session.bundle!.document.theme,
              onSelected: session.updateTheme,
              icon: const Icon(Icons.palette_outlined, size: 19),
              itemBuilder: (context) => const [
                PopupMenuItem(value: GalleryTheme.ink, child: Text('墨色画布')),
                PopupMenuItem(value: GalleryTheme.paper, child: Text('纸张画布')),
                PopupMenuItem(
                  value: GalleryTheme.graphite,
                  child: Text('石墨画布'),
                ),
                PopupMenuItem(value: GalleryTheme.mist, child: Text('雾蓝画布')),
                PopupMenuItem(value: GalleryTheme.warm, child: Text('暖沙画布')),
              ],
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _editChapterText(context),
              icon: const Icon(Icons.short_text, size: 17),
              label: const Text('标题与短注释'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            for (final layout in GalleryLayout.values)
              ChoiceChip(
                selected: chapter.layout == layout,
                onSelected: (_) => session.updateChapter(layout: layout),
                label: Text(_layoutLabel(layout)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Text(
                '路径线条',
                style: TextStyle(color: XulangColors.muted, fontSize: 12),
              ),
            ),
            for (final style in StoryPathStyle.values)
              ChoiceChip(
                selected: chapter.pathStyle == style,
                onSelected: (_) => session.updateChapter(pathStyle: style),
                label: Text(_pathStyleLabel(style)),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          key: const Key('editor-show-chapter-title-playback'),
          contentPadding: EdgeInsets.zero,
          title: const Text('录屏时显示章节名'),
          value: session.bundle!.document.showChapterTitleInPlayback,
          onChanged: session.updateShowChapterTitleInPlayback,
        ),
        ListTile(
          key: const Key('editor-background-music'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.music_note_outlined),
          title: Text(
            session.bundle!.document.musicTitle ?? '未添加背景音乐',
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('播放和录屏模式可使用本地音乐'),
          trailing: Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => _pickBackgroundMusic(context),
                child: const Text('选择'),
              ),
              if (session.bundle!.document.musicPath != null)
                TextButton(
                  onPressed: session.clearBackgroundMusic,
                  child: const Text('清除'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementPanel(
    BuildContext context,
    GalleryChapter chapter,
    GalleryPlacement? placement,
  ) {
    if (placement == null) {
      return const Text(
        '点击一张图片后，这里会显示图片大小、画框、裁切和旋转。',
        style: TextStyle(color: XulangColors.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 54,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: chapter.placements.length,
            onReorder: (oldIndex, newIndex) async {
              final movedId = chapter.placements[oldIndex].id;
              await session.movePlacement(oldIndex, newIndex);
              widget.onFocusPlacement(movedId);
            },
            itemBuilder: (context, index) {
              final item = chapter.placements[index];
              final media = session.bundle!.media
                  .where((m) => m.id == item.mediaId)
                  .isEmpty
                  ? null
                  : session.bundle!.media
                        .where((m) => m.id == item.mediaId)
                        .first;
              final selected = item.id == placement.id;
              return Padding(
                key: ValueKey(item.id),
                padding: const EdgeInsets.only(right: 8),
                child: ReorderableDragStartListener(
                  index: index,
                  child: InkWell(
                    onTap: () => widget.onFocusPlacement(item.id),
                    child: Container(
                      width: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? XulangColors.accent : XulangColors.line,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: media == null
                          ? const Icon(Icons.broken_image_outlined)
                          : GalleryImage(path: media.thumbnailPath, cacheWidth: 160),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final size in GallerySize.values)
              ChoiceChip(
                selected: placement.size == size,
                onSelected: (_) => session.updatePlacement(placement.id, size: size),
                label: Text(_sizeLabel(size)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final frame in GalleryFrame.values)
              ChoiceChip(
                selected: placement.frame == frame,
                onSelected: (_) =>
                    session.updatePlacement(placement.id, frame: frame),
                label: Text(_frameLabel(frame)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _CropSlider(
          label: '水平焦点',
          value: placement.focalX,
          min: 0,
          max: 1,
          onChanged: (value) =>
              session.updatePlacement(placement.id, focalX: value),
        ),
        _CropSlider(
          label: '垂直焦点',
          value: placement.focalY,
          min: 0,
          max: 1,
          onChanged: (value) =>
              session.updatePlacement(placement.id, focalY: value),
        ),
        _CropSlider(
          label: '裁切缩放',
          value: placement.zoom,
          min: 1,
          max: 3,
          onChanged: (value) =>
              session.updatePlacement(placement.id, zoom: value),
        ),
        _CropSlider(
          label: '旋转角度',
          value: placement.rotation,
          min: -180,
          max: 180,
          onChanged: (value) =>
              session.updatePlacement(placement.id, rotation: value),
        ),
        TextFormField(
          initialValue: placement.caption,
          maxLength: 60,
          decoration: const InputDecoration(labelText: '单图短注释'),
          onChanged: (value) =>
              session.updatePlacement(placement.id, caption: value),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _editPlacement(context, placement),
            icon: const Icon(Icons.tune, size: 17),
            label: const Text('高级编辑'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickBackgroundMusic(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: '音频',
          extensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
          mimeTypes: ['audio/*'],
        ),
      ],
    );
    if (file == null) return;
    await session.importBackgroundMusic(file.path);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已添加背景音乐')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = session.selectedChapter!;
    final placement = widget.selectedPlacementId == null
        ? null
        : chapter.placements.cast<GalleryPlacement?>().firstWhere(
            (item) => item?.id == widget.selectedPlacementId,
            orElse: () => null,
          );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .52),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                key: const Key('editor-inspector-scroll'),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '悬浮操作板',
                            style: TextStyle(
                              color: XulangColors.paper,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ChoiceChip(
                          selected:
                              widget.panelMode == _EditorPanelMode.canvas,
                          onSelected: (_) => widget.onFocusCanvas(),
                          label: const Text('画布'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          selected:
                              widget.panelMode == _EditorPanelMode.placement &&
                              placement != null,
                          onSelected: (_) {
                            if (placement != null) {
                              widget.onFocusPlacement(placement.id);
                            }
                          },
                          label: const Text('图片'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.panelMode == _EditorPanelMode.canvas)
                      _buildCanvasPanel(context, chapter)
                    else
                      _buildPlacementPanel(context, chapter, placement),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editChapterText(BuildContext context) async {
    final chapter = session.selectedChapter!;
    var title = chapter.title;
    var caption = chapter.caption;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('章节文字'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: title,
              decoration: const InputDecoration(labelText: '章节标题'),
              onChanged: (value) => title = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: caption,
              maxLength: 80,
              decoration: const InputDecoration(labelText: '短注释'),
              onChanged: (value) => caption = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (save == true) {
      await session.updateChapter(title: title, caption: caption);
    }
  }

  Future<void> _editPlacement(
    BuildContext context,
    GalleryPlacement placement,
  ) async {
    var focalX = placement.focalX;
    var focalY = placement.focalY;
    var zoom = placement.zoom;
    var caption = placement.caption;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              18,
              22,
              18 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('裁切与图片叙事', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                _CropSlider(
                  label: '水平焦点',
                  value: focalX,
                  min: 0,
                  max: 1,
                  onChanged: (value) => setModalState(() => focalX = value),
                ),
                _CropSlider(
                  label: '垂直焦点',
                  value: focalY,
                  min: 0,
                  max: 1,
                  onChanged: (value) => setModalState(() => focalY = value),
                ),
                _CropSlider(
                  label: '裁切缩放',
                  value: zoom,
                  min: 1,
                  max: 3,
                  onChanged: (value) => setModalState(() => zoom = value),
                ),
                TextFormField(
                  initialValue: caption,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: '单图短注释'),
                  onChanged: (value) => caption = value,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (save == true) {
      await session.updatePlacement(
        placement.id,
        focalX: focalX,
        focalY: focalY,
        zoom: zoom,
        caption: caption.trim(),
      );
    }
  }
}

enum _EditorPanelMode { canvas, placement }

class _CropSlider extends StatelessWidget {
  const _CropSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(width: 34, child: Text(value.toStringAsFixed(1))),
      ],
    );
  }
}

String _layoutLabel(GalleryLayout layout) => switch (layout) {
  GalleryLayout.hero => '主视觉',
  GalleryLayout.filmstrip => '横向胶片',
  GalleryLayout.diptych => '双联画',
  GalleryLayout.collage => '叙事拼贴',
  GalleryLayout.storyPath => '故事路径',
  GalleryLayout.depthWall => '立体展墙',
};

String _sizeLabel(GallerySize size) => switch (size) {
  GallerySize.small => '小',
  GallerySize.medium => '中',
  GallerySize.large => '大',
};

String _pathStyleLabel(StoryPathStyle style) => switch (style) {
  StoryPathStyle.solid => '细线',
  StoryPathStyle.dashed => '虚线',
  StoryPathStyle.glow => '微光',
  StoryPathStyle.none => '隐藏',
};

String _frameLabel(GalleryFrame frame) => switch (frame) {
  GalleryFrame.none => '无',
  GalleryFrame.hairline => '细线',
  GalleryFrame.mat => '相纸',
  GalleryFrame.stamp => '邮票边',
  GalleryFrame.wood => '木制',
  GalleryFrame.darkWood => '深木',
  GalleryFrame.metal => '金属',
  GalleryFrame.vintage => '复古',
  GalleryFrame.film => '胶片孔',
};
