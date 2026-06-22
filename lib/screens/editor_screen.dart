import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/editor/editor_session.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/viewer_screen.dart';
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

class _EditorBody extends StatelessWidget {
  const _EditorBody({required this.session});

  final EditorSession session;

  @override
  Widget build(BuildContext context) {
    final bundle = session.bundle!;
    final document = bundle.document;
    final chapter = session.selectedChapter!;
    return Scaffold(
      appBar: AppBar(
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
                  style: const TextStyle(fontFamily: 'serif', letterSpacing: 1),
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
                      builder: (_) => ViewerScreen(exhibitionId: document.id),
                    ),
                  ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          if (landscape) {
            final inspectorWidth = (constraints.maxWidth * .36).clamp(
              280.0,
              340.0,
            );
            return Column(
              children: [
                _ChapterRail(session: session),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 7, child: _Preview(session: session)),
                      SizedBox(
                        width: inspectorWidth,
                        child: _Inspector(session: session),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _ChapterRail(session: session),
              Expanded(child: _Preview(session: session)),
              SizedBox(height: 214, child: _Inspector(session: session)),
            ],
          );
        },
      ),
    );
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

class _ChapterRail extends StatelessWidget {
  const _ChapterRail({required this.session});

  final EditorSession session;

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
                    onSelected: (_) => session.selectChapter(index),
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
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Preview extends StatefulWidget {
  const _Preview({required this.session});

  final EditorSession session;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  double cameraProgress = 0;

  EditorSession get session => widget.session;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SceneCanvas(
            chapter: session.selectedChapter!,
            media: session.bundle!.media,
            cameraProgress: cameraProgress,
            sceneTheme: session.bundle!.document.theme,
          ),
        ),
        if (session.selectedChapter!.placements.length > 1)
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: DecoratedBox(
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
                        value: cameraProgress,
                        onChanged: (value) =>
                            setState(() => cameraProgress = value),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${(cameraProgress * 100).round()}%',
                        style: const TextStyle(
                          color: XulangColors.paper,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 14,
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
  }
}

class _Inspector extends StatefulWidget {
  const _Inspector({required this.session});

  final EditorSession session;

  @override
  State<_Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<_Inspector> {
  int selectedPlacement = 0;

  EditorSession get session => widget.session;

  @override
  Widget build(BuildContext context) {
    final chapter = session.selectedChapter!;
    final placement = chapter.placements.isEmpty
        ? null
        : chapter.placements[selectedPlacement.clamp(
            0,
            chapter.placements.length - 1,
          )];
    return ColoredBox(
      color: XulangColors.surface,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const Key('editor-inspector-scroll'),
          padding: EdgeInsets.fromLTRB(
            16,
            13,
            16,
            20 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '章节版式',
                    style: TextStyle(color: XulangColors.muted, fontSize: 12),
                  ),
                  const Spacer(),
                  PopupMenuButton<GalleryTheme>(
                    tooltip: '画布主题',
                    initialValue: session.bundle!.document.theme,
                    onSelected: session.updateTheme,
                    icon: const Icon(Icons.palette_outlined, size: 19),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: GalleryTheme.ink,
                        child: Text('墨色画布'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.paper,
                        child: Text('纸张画布'),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _editChapterText(context),
                    icon: const Icon(Icons.short_text, size: 17),
                    label: const Text('标题与短注释'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Text(
                      '转场',
                      style: TextStyle(color: XulangColors.muted, fontSize: 12),
                    ),
                  ),
                  for (final motion in GalleryMotion.values)
                    ChoiceChip(
                      selected: chapter.motion == motion,
                      onSelected: (_) => session.updateChapter(motion: motion),
                      label: Text(_motionLabel(motion)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: chapter.placements.isEmpty ? 0 : 56,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: chapter.placements.length,
                  onReorder: (oldIndex, newIndex) async {
                    final destination = oldIndex < newIndex
                        ? newIndex - 1
                        : newIndex;
                    setState(() {
                      if (selectedPlacement == oldIndex) {
                        selectedPlacement = destination;
                      } else if (oldIndex < selectedPlacement &&
                          destination >= selectedPlacement) {
                        selectedPlacement -= 1;
                      } else if (oldIndex > selectedPlacement &&
                          destination <= selectedPlacement) {
                        selectedPlacement += 1;
                      }
                    });
                    await session.movePlacement(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = chapter.placements[index];
                    final media = session.bundle!.media
                        .where((m) => m.id == item.mediaId)
                        .firstOrNull;
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(right: 8),
                      child: ReorderableDragStartListener(
                        index: index,
                        child: InkWell(
                          onTap: () =>
                              setState(() => selectedPlacement = index),
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: index == selectedPlacement
                                    ? XulangColors.accent
                                    : XulangColors.line,
                                width: index == selectedPlacement ? 2 : 1,
                              ),
                            ),
                            child: media == null
                                ? const Icon(Icons.broken_image_outlined)
                                : GalleryImage(
                                    path: media.thumbnailPath,
                                    cacheWidth: 160,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (placement != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '画面大小',
                      style: TextStyle(color: XulangColors.muted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    for (final size in GallerySize.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: placement.size == size,
                          onSelected: (_) =>
                              session.updatePlacement(placement.id, size: size),
                          label: Text(_sizeLabel(size)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text(
                        '画框',
                        style: TextStyle(
                          color: XulangColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
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
                TextButton.icon(
                  onPressed: () => _editPlacement(context, placement),
                  icon: const Icon(Icons.crop_free, size: 17),
                  label: const Text('裁切焦点与短注释'),
                ),
              ],
            ],
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
};

String _sizeLabel(GallerySize size) => switch (size) {
  GallerySize.small => '小',
  GallerySize.medium => '中',
  GallerySize.large => '大',
};

String _motionLabel(GalleryMotion motion) => switch (motion) {
  GalleryMotion.pan => '平移',
  GalleryMotion.push => '推进',
  GalleryMotion.focus => '聚焦',
  GalleryMotion.unfold => '层叠展开',
};

String _frameLabel(GalleryFrame frame) => switch (frame) {
  GalleryFrame.none => '无',
  GalleryFrame.hairline => '细线',
  GalleryFrame.mat => '相纸',
  GalleryFrame.stamp => '邮票边',
};
