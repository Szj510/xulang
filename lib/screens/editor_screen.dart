import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import 'package:xulang/share/exhibition_exporter.dart';
import 'package:xulang/share/export_file_service.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/atmospheric_sticker.dart';
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
  bool _showPanel = false; // 默认隐藏浮动面板
  double _panelOpacity = 0.34;
  _EditorInteractionMode _interactionMode = _EditorInteractionMode.canvas;
  GalleryStickerKind? _selectedStickerKind;
  String? _selectedPlacementId;
  Offset _floatingBallOffset = const Offset(16, 560);

  EditorSession get session => widget.session;

  void _setPanelOpacity(double value) {
    setState(() => _panelOpacity = value.clamp(0.10, 0.62));
  }

  void _focusCanvas() {
    setState(() {
      _interactionMode = _EditorInteractionMode.canvas;
      _selectedStickerKind = null;
      _selectedPlacementId = null;
      _showPanel = true;
    });
  }

  void _focusPlacement(String placementId) {
    setState(() {
      _interactionMode = _EditorInteractionMode.image;
      _selectedStickerKind = null;
      _selectedPlacementId = placementId;
      _showPanel = true;
    });
  }

  void _focusSticker() {
    setState(() {
      _interactionMode = _EditorInteractionMode.sticker;
      _showPanel = true;
    });
  }

  void _selectStickerKind(GalleryStickerKind kind) {
    setState(() {
      _interactionMode = _EditorInteractionMode.sticker;
      _selectedStickerKind = kind;
      _showPanel = true;
    });
  }

  Future<void> _placeSticker(CustomPathPoint point) async {
    final kind = _selectedStickerKind;
    if (kind == null) return;
    await session.addSticker(kind, x: point.x, y: point.y);
  }

  void _dismissPanel() {
    setState(() => _showPanel = false);
  }

  void _togglePanel() {
    setState(() => _showPanel = !_showPanel);
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
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              document.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Noto Serif SC',
                                fontFamilyFallback: [
                                  'Noto Sans SC',
                                  'PingFang SC',
                                  'Microsoft YaHei',
                                ],
                                fontSize: 17,
                                letterSpacing: 0.8,
                                color: XulangColors.paper,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: XulangColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    _EditorIconButton(
                      key: const Key('portrait-editor-undo'),
                      tooltip: '撤销',
                      onPressed: session.canUndo ? session.undo : null,
                      icon: Icons.undo,
                    ),
                    _EditorIconButton(
                      key: const Key('portrait-editor-redo'),
                      tooltip: '重做',
                      onPressed: session.canRedo ? session.redo : null,
                      icon: Icons.redo,
                    ),
                    _EditorIconButton(
                      key: const Key('portrait-editor-play'),
                      tooltip: '沉浸观看',
                      onPressed: chapter.placements.isEmpty
                          ? null
                          : () => _play(context),
                      icon: Icons.play_arrow_rounded,
                    ),
                    PopupMenuButton<_EditorExportAction>(
                      tooltip: '导出与分享',
                      onSelected: (action) =>
                          _handleExportAction(context, action),
                      icon: const Icon(Icons.share_outlined, size: 20),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _EditorExportAction.template,
                          child: Row(
                            children: [
                              Icon(Icons.ios_share_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('分享模板'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _EditorExportAction.recordAndShare,
                          child: Row(
                            children: [
                              Icon(Icons.video_camera_back_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('录制并分享视频'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _EditorExportAction.importTemplate,
                          child: Row(
                            children: [
                              Icon(Icons.file_open_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('导入模板'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (landscape) {
                return Stack(
                  children: [
                    // Full-screen preview
                    Positioned.fill(
                      child: _Preview(
                        session: session,
                        interactionMode: _interactionMode,
                        selectedStickerKind: _selectedStickerKind,
                        onStickerPlaced: _placeSticker,
                        onCanvasTap: () {
                          _dismissPanel();
                          _hideChapters();
                        },
                        onPlacementTap: _focusPlacement,
                      ),
                    ),
                    // Back button
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
                    // Toolbar
                    Positioned(
                      right: 8,
                      top: 0,
                      child: SafeArea(
                        child: Material(
                          key: const Key('landscape-editor-toolbar'),
                          color: XulangColors.ink.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: XulangColors.line,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _EditorIconButton(
                                  tooltip: '章节',
                                  onPressed: () => setState(
                                    () => _showChapters = !_showChapters,
                                  ),
                                  icon: Icons.view_carousel_outlined,
                                ),
                                _EditorIconButton(
                                  key: const Key('landscape-editor-undo'),
                                  tooltip: '撤销',
                                  onPressed: session.canUndo
                                      ? session.undo
                                      : null,
                                  icon: Icons.undo,
                                ),
                                _EditorIconButton(
                                  key: const Key('landscape-editor-redo'),
                                  tooltip: '重做',
                                  onPressed: session.canRedo
                                      ? session.redo
                                      : null,
                                  icon: Icons.redo,
                                ),
                                _EditorIconButton(
                                  key: const Key('landscape-editor-play'),
                                  tooltip: '沉浸观看',
                                  onPressed: chapter.placements.isEmpty
                                      ? null
                                      : () => _play(context),
                                  icon: Icons.play_arrow_rounded,
                                ),
                                PopupMenuButton<_EditorExportAction>(
                                  tooltip: '导出与分享',
                                  onSelected: (action) =>
                                      _handleExportAction(context, action),
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    size: 20,
                                  ),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: _EditorExportAction.template,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.ios_share_outlined,
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                          Text('分享模板'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _EditorExportAction.recordAndShare,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.video_camera_back_outlined,
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                          Text('录制并分享视频'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _EditorExportAction.importTemplate,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.file_open_outlined,
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                          Text('导入模板'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Chapter rail overlay
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
                                setState(() => _showChapters = false);
                              },
                              onRename: () => _rename(context),
                            ),
                          ),
                        ),
                      ),
                    // Floating panel overlay
                    if (_showPanel)
                      _FloatingPanel(
                        session: session,
                        interactionMode: _interactionMode,
                        selectedPlacementId: _selectedPlacementId,
                        selectedStickerKind: _selectedStickerKind,
                        panelOpacity: _panelOpacity,
                        onPanelOpacityChanged: _setPanelOpacity,
                        onFocusCanvas: _focusCanvas,
                        onFocusPlacement: _focusPlacement,

                        onFocusSticker: _focusSticker,
                        onSelectStickerKind: _selectStickerKind,
                        onDismiss: _dismissPanel,
                        landscape: true,
                      ),
                    // Floating ball
                    _FloatingBall(
                      offset: _floatingBallOffset,
                      isActive: _showPanel,
                      onTap: _togglePanel,
                      onOffsetChanged: (offset) {
                        setState(() => _floatingBallOffset = offset);
                      },
                    ),
                  ],
                );
              }
              // Portrait mode
              return Stack(
                children: [
                  Column(
                    children: [
                      _ChapterRail(
                        key: const Key('editor-chapter-rail'),
                        session: session,
                      ),
                      Expanded(
                        child: _Preview(
                          session: session,
                          interactionMode: _interactionMode,
                          selectedStickerKind: _selectedStickerKind,
                          onStickerPlaced: _placeSticker,
                          onCanvasTap: _dismissPanel,
                          onPlacementTap: _focusPlacement,
                        ),
                      ),
                    ],
                  ),
                  // Floating panel overlay
                  if (_showPanel)
                    _FloatingPanel(
                      session: session,
                      interactionMode: _interactionMode,
                      selectedPlacementId: _selectedPlacementId,
                      selectedStickerKind: _selectedStickerKind,
                      panelOpacity: _panelOpacity,
                      onPanelOpacityChanged: _setPanelOpacity,
                      onFocusCanvas: _focusCanvas,
                      onFocusPlacement: _focusPlacement,

                      onFocusSticker: _focusSticker,
                      onSelectStickerKind: _selectStickerKind,
                      onDismiss: _dismissPanel,
                      landscape: false,
                    ),
                  // Floating ball
                  _FloatingBall(
                    offset: _floatingBallOffset,
                    isActive: _showPanel,
                    onTap: _togglePanel,
                    onOffsetChanged: (offset) {
                      setState(() => _floatingBallOffset = offset);
                    },
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
        case _EditorExportAction.recordAndShare:
          if (!context.mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ViewerScreen(exhibitionId: bundle.document.id),
            ),
          );
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
          final templateJson = utf8.decode(await file.readAsBytes());
          if (!context.mounted) return;
          final summary = const ExhibitionTemplateCodec().inspect(templateJson);
          final exhibitionTitle = await _promptText(
            context,
            title: '命名新展览',
            initialValue: session.bundle?.document.title ?? summary.title,
            hint: '展览名称',
            confirmText: '下一步',
          );
          if (exhibitionTitle == null || exhibitionTitle.trim().isEmpty) return;
          if (!context.mounted) return;
          final chapterTitle = await _promptText(
            context,
            title: summary.chapterCount > 1 ? '命名章节前缀' : '命名章节',
            initialValue: summary.firstChapterTitle,
            hint: summary.chapterCount > 1 ? '例如：旅行片段' : '章节名称',
            confirmText: '选择图片',
          );
          if (chapterTitle == null || chapterTitle.trim().isEmpty) return;
          if (!context.mounted) return;
          final images = await openFiles(
            acceptedTypeGroups: const [
              XTypeGroup(
                label: '图片',
                extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
                mimeTypes: ['image/*'],
              ),
            ],
          );
          if (images.isEmpty) return;
          await session.applyTemplateJsonWithImages(
            templateJson,
            sourcePaths: [for (final image in images) image.path],
            titleOverride: exhibitionTitle,
            chapterTitleOverride: chapterTitle,
          );
          if (context.mounted) _showSnack(context, '已按模板生成新叙廊');
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

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hint,
    required String confirmText,
  }) async {
    var value = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onChanged: (next) => value = next,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value),
            child: Text(confirmText),
          ),
        ],
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

enum _EditorExportAction { template, recordAndShare, importTemplate }

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
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
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? XulangColors.muted.withValues(alpha: .4)
                  : XulangColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBall extends StatelessWidget {
  const _FloatingBall({
    required this.offset,
    required this.isActive,
    required this.onTap,
    required this.onOffsetChanged,
  });

  final Offset offset;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<Offset> onOffsetChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final minX = 8.0;
    final maxX = math.max(minX, size.width - 56);
    final minY = padding.top + 8;
    final maxY = math.max(minY, size.height - padding.bottom - 56);
    final absX = offset.dx.clamp(minX, maxX);
    final absY = offset.dy.clamp(minY, maxY);

    return Positioned(
      left: absX,
      top: absY,
      child: GestureDetector(
        key: const Key('editor-floating-ball'),
        onPanUpdate: (details) {
          final newX = (absX + details.delta.dx).clamp(minX, maxX);
          final newY = (absY + details.delta.dy).clamp(minY, maxY);
          onOffsetChanged(Offset(newX, newY));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      XulangColors.accent,
                      XulangColors.accent.withValues(alpha: .7),
                    ]
                  : [
                      Colors.black.withValues(alpha: .65),
                      Colors.black.withValues(alpha: .45),
                    ],
            ),
            border: Border.all(
              color: isActive
                  ? XulangColors.accent.withValues(alpha: .5)
                  : Colors.white.withValues(alpha: .12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Icon(
                isActive ? Icons.close : Icons.tune_rounded,
                size: 22,
                color: XulangColors.paper,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPanel extends StatefulWidget {
  const _FloatingPanel({
    required this.session,
    required this.interactionMode,
    required this.selectedPlacementId,
    required this.selectedStickerKind,
    required this.panelOpacity,
    required this.onPanelOpacityChanged,
    required this.onFocusCanvas,
    required this.onFocusPlacement,
    required this.onFocusSticker,
    required this.onSelectStickerKind,
    required this.onDismiss,
    required this.landscape,
  });

  final EditorSession session;
  final _EditorInteractionMode interactionMode;
  final String? selectedPlacementId;
  final GalleryStickerKind? selectedStickerKind;
  final double panelOpacity;
  final ValueChanged<double> onPanelOpacityChanged;
  final VoidCallback onFocusCanvas;
  final ValueChanged<String> onFocusPlacement;
  final VoidCallback onFocusSticker;
  final ValueChanged<GalleryStickerKind> onSelectStickerKind;
  final VoidCallback onDismiss;
  final bool landscape;

  @override
  State<_FloatingPanel> createState() => _FloatingPanelState();
}

class _FloatingPanelState extends State<_FloatingPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = widget.landscape
        ? (MediaQuery.sizeOf(context).width * 0.38).clamp(300.0, 380.0)
        : double.infinity;
    final maxHeight = widget.landscape
        ? MediaQuery.sizeOf(context).height * 0.85
        : MediaQuery.sizeOf(context).height * 0.55;

    return Positioned(
      right: widget.landscape ? 8 : 0,
      left: widget.landscape ? null : 0,
      bottom: widget.landscape ? 8 : 0,
      top: widget.landscape ? 56 : null,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: widget.landscape
                ? Offset(_slideAnimation.value * panelWidth, 0)
                : Offset(0, _slideAnimation.value * maxHeight),
            child: Opacity(opacity: _fadeAnimation.value, child: child),
          );
        },
        child: SafeArea(
          top: widget.landscape,
          child: SizedBox(
            width: widget.landscape ? panelWidth : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: widget.landscape
                    ? const EdgeInsets.all(0)
                    : const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: DecoratedBox(
                      key: const Key('editor-floating-panel-shell'),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: widget.panelOpacity,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _Inspector(
                        session: widget.session,
                        interactionMode: widget.interactionMode,
                        selectedPlacementId: widget.selectedPlacementId,
                        selectedStickerKind: widget.selectedStickerKind,
                        panelOpacity: widget.panelOpacity,
                        onPanelOpacityChanged: widget.onPanelOpacityChanged,
                        onFocusCanvas: widget.onFocusCanvas,
                        onFocusPlacement: widget.onFocusPlacement,

                        onFocusSticker: widget.onFocusSticker,
                        onSelectStickerKind: widget.onSelectStickerKind,
                      ),
                    ),
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
      height: 64,
      decoration: const BoxDecoration(
        color: XulangColors.surface,
        border: Border(
          bottom: BorderSide(color: XulangColors.line, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    label: Text(
                      '${index + 1}  ${chapters[index].title}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: selected
                            ? XulangColors.accent
                            : XulangColors.paper,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _EditorIconButton(
            tooltip: '添加章节',
            onPressed: session.addChapter,
            icon: Icons.add,
          ),
          if (onRename != null)
            _EditorIconButton(
              tooltip: '重命名展览',
              onPressed: onRename,
              icon: Icons.edit_outlined,
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
    required this.interactionMode,
    this.selectedStickerKind,
    this.onStickerPlaced,
    this.onCanvasTap,
    this.onPlacementTap,
  });

  final EditorSession session;
  final _EditorInteractionMode interactionMode;
  final GalleryStickerKind? selectedStickerKind;
  final Future<void> Function(CustomPathPoint point)? onStickerPlaced;
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
  final TransformationController _zoomController = TransformationController();
  GalleryPlacement? _gestureStartPlacement;
  int _previewPointerCount = 0;
  bool _cameraDragActive = false;
  bool _previewPointerMoved = false;

  double get _currentScale => _zoomController.value.getMaxScaleOnAxis();

  bool get _isZoomed => _currentScale > 1.05 || _currentScale < 0.95;

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
    setState(() {});
  }

  void _setPreviewScale(double targetScale, Size viewport) {
    final scale = targetScale.clamp(1.0, 3.0);
    final center = Offset(viewport.width / 2, viewport.height / 2);
    _zoomController.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setTranslationRaw(center.dx * (1 - scale), center.dy * (1 - scale), 0);
    setState(() {});
  }

  EditorSession get session => widget.session;
  bool get _isCanvasMode =>
      widget.interactionMode == _EditorInteractionMode.canvas;
  bool get _isImageMode =>
      widget.interactionMode == _EditorInteractionMode.image;
  bool get _isStickerMode =>
      widget.interactionMode == _EditorInteractionMode.sticker;
  String get _chapterId => session.selectedChapter!.id;
  double get _cameraProgress => _cameraProgressByChapter[_chapterId] ?? 0;

  @override
  void dispose() {
    _cameraController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _setProgress(double value) {
    final next = value.clamp(0.0, 1.0);
    _cameraController.setProgress(next);
    setState(() => _cameraProgressByChapter[_chapterId] = next);
  }

  void _beginCameraDragIfNeeded() {
    if (!_isCanvasMode) return;
    if (_previewPointerCount == 1 && !_isZoomed && !_cameraDragActive) {
      _cameraController.setProgress(_cameraProgress);
      _cameraController.begin(scale: 1);
      _cameraDragActive = true;
    }
  }

  void _endCameraDragIfNeeded() {
    if (!_cameraDragActive) return;
    _cameraController.end();
    _cameraDragActive = false;
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

  void _placeStickerAt(Offset localPosition, Size viewport) {
    if (widget.selectedStickerKind == null || widget.onStickerPlaced == null) {
      return;
    }
    final point = CustomPathPoint(
      x: localPosition.dx / viewport.width,
      y: localPosition.dy / viewport.height,
    );
    unawaited(widget.onStickerPlaced!(point));
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
        final placementEditingEnabled = _isImageMode;
        final canvasNavigationEnabled = _isCanvasMode || _isStickerMode;
        final canvasTap = _isCanvasMode ? widget.onCanvasTap : null;
        final placementTap = _isStickerMode ? null : widget.onPlacementTap;
        final worldSize = viewport;
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                key: const Key('editor-preview-zoom'),
                transformationController: _zoomController,
                minScale: 1.0,
                maxScale: 3.0,
                boundaryMargin: EdgeInsets.zero,
                constrained: true,
                alignment: Alignment.center,
                panEnabled: canvasNavigationEnabled,
                scaleEnabled: canvasNavigationEnabled,
                onInteractionEnd: (_) => setState(() {}),
                child: SizedBox(
                  key: const Key('editor-infinite-world'),
                  width: worldSize.width,
                  height: worldSize.height,
                  child: Listener(
                    onPointerDown: (_) {
                      _previewPointerCount += 1;
                      if (_previewPointerCount == 1) {
                        _previewPointerMoved = false;
                      }
                      if (_previewPointerCount > 1) {
                        _endCameraDragIfNeeded();
                      } else {
                        _beginCameraDragIfNeeded();
                      }
                    },
                    onPointerMove: (event) {
                      if (event.delta.distance > 2) {
                        _previewPointerMoved = true;
                      }
                      if (!_isCanvasMode ||
                          _previewPointerCount != 1 ||
                          _isZoomed) {
                        return;
                      }
                      _beginCameraDragIfNeeded();
                      _cameraController.update(
                        delta: event.delta,
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
                    onPointerUp: (_) {
                      final wasSingleTap =
                          _previewPointerCount == 1 && !_previewPointerMoved;
                      _previewPointerCount = math.max(
                        0,
                        _previewPointerCount - 1,
                      );
                      if (_previewPointerCount == 0) {
                        _endCameraDragIfNeeded();
                      }
                      if (wasSingleTap) {
                        canvasTap?.call();
                      }
                    },
                    onPointerCancel: (_) {
                      _previewPointerCount = math.max(
                        0,
                        _previewPointerCount - 1,
                      );
                      if (_previewPointerCount == 0) {
                        _endCameraDragIfNeeded();
                      }
                    },
                    child: GestureDetector(
                      key: const Key('editor-preview-gesture-surface'),
                      behavior: HitTestBehavior.opaque,
                      onTap: canvasTap,
                      child: SceneCanvas(
                        chapter: chapter,
                        media: session.bundle!.media,
                        cameraProgress: progress,
                        sceneTheme: session.bundle!.document.theme,
                        canvasBackgroundPath:
                            session.bundle!.document.canvasBackgroundPath,
                        canvasBackgroundOpacity:
                            session.bundle!.document.canvasBackgroundOpacity,
                        placementEditingEnabled: placementEditingEnabled,
                        stickerEditingEnabled: _isStickerMode,
                        selectedStickerKind: widget.selectedStickerKind,
                        onStickerPlaced: _placeStickerAt,
                        onStickerChanged: session.updateSticker,
                        onStickerDeleted: session.removeSticker,

                        onPlacementTap: placementTap,
                        onPlacementTransformStart: _startPlacementTransform,
                        onPlacementTransformUpdate:
                            (placementId, scaleDelta, delta) =>
                                _updatePlacementTransform(
                                  placementId,
                                  scaleDelta,
                                  delta,
                                  worldSize,
                                ),
                        onPlacementTransformEnd: (placementId) {
                          unawaited(_endPlacementTransform(placementId));
                        },
                      ),
                    ),
                  ),
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
                      child: _GlassPill(
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
              child: _GlassImportButton(
                importing: session.importing,
                onPressed: session.importing ? null : session.importImages,
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _GlassPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '缩小画布',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _setPreviewScale(_currentScale - 0.15, viewport),
                      icon: const Icon(
                        Icons.zoom_out,
                        size: 17,
                        color: XulangColors.paper,
                      ),
                    ),
                    IconButton(
                      tooltip: '重置缩放',
                      visualDensity: VisualDensity.compact,
                      onPressed: _resetZoom,
                      icon: const Icon(
                        Icons.fit_screen_outlined,
                        size: 17,
                        color: XulangColors.paper,
                      ),
                    ),
                    IconButton(
                      tooltip: '放大画布',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _setPreviewScale(_currentScale + 0.15, viewport),
                      icon: const Icon(
                        Icons.zoom_in,
                        size: 17,
                        color: XulangColors.paper,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (session.error != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: MaterialBanner(
                  backgroundColor: XulangColors.elevated,
                  content: Text(
                    '${session.error}',
                    style: const TextStyle(
                      color: XulangColors.paper,
                      fontSize: 13,
                    ),
                  ),
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

class _GlassImportButton extends StatelessWidget {
  const _GlassImportButton({required this.importing, required this.onPressed});

  final bool importing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: XulangColors.paper.withValues(alpha: .92),
        foregroundColor: XulangColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: importing
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: XulangColors.ink,
              ),
            )
          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
      label: Text(
        importing ? '导入中' : '导入图片',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ProgressControl extends StatelessWidget {
  const _ProgressControl({required this.progress, required this.onChanged});

  final double progress;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
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

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .55),
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
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
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: XulangColors.paper,
        fontSize: 11,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _Inspector extends StatefulWidget {
  const _Inspector({
    required this.session,
    required this.interactionMode,
    required this.selectedPlacementId,
    required this.selectedStickerKind,
    required this.panelOpacity,
    required this.onPanelOpacityChanged,
    required this.onFocusCanvas,
    required this.onFocusPlacement,
    required this.onFocusSticker,
    required this.onSelectStickerKind,
  });

  final EditorSession session;
  final _EditorInteractionMode interactionMode;
  final String? selectedPlacementId;
  final GalleryStickerKind? selectedStickerKind;
  final double panelOpacity;
  final ValueChanged<double> onPanelOpacityChanged;
  final VoidCallback onFocusCanvas;
  final ValueChanged<String> onFocusPlacement;
  final VoidCallback onFocusSticker;
  final ValueChanged<GalleryStickerKind> onSelectStickerKind;

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
        _InspectorSection(
          title: '画布与叙事',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PopupMenuButton<GalleryTheme>(
                    tooltip: '画布主题',
                    initialValue: session.bundle!.document.theme,
                    onSelected: session.updateTheme,
                    icon: const Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: XulangColors.muted,
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: GalleryTheme.ink,
                        child: Text('墨色画布'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.paper,
                        child: Text('纸张画布'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.graphite,
                        child: Text('石墨画布'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.mist,
                        child: Text('雾蓝画布'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.warm,
                        child: Text('暖沙画布'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.moonlight,
                        child: Text('月光暗房'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.botanical,
                        child: Text('植物标本'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.cyanotype,
                        child: Text('蓝晒纸'),
                      ),
                      PopupMenuItem(
                        value: GalleryTheme.terracotta,
                        child: Text('陶土壁龛'),
                      ),
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
              const SizedBox(height: 8),
              _CropSlider(
                key: const Key('editor-panel-opacity-slider'),
                label: '面板透明度',
                value: widget.panelOpacity,
                min: 0.10,
                max: 0.62,
                onChanged: widget.onPanelOpacityChanged,
              ),
              const SizedBox(height: 12),
              _CanvasBackgroundControl(
                path: session.bundle!.document.canvasBackgroundPath,
                opacity: session.bundle!.document.canvasBackgroundOpacity,
                onPick: () => _pickCanvasBackground(context),
                onClear: session.clearCanvasBackground,
                onOpacityChanged: session.updateCanvasBackgroundOpacity,
              ),
              const SizedBox(height: 12),
              _SectionLabel('布局'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final layout in GalleryLayout.values)
                    ChoiceChip(
                      selected: chapter.layout == layout,
                      onSelected: (_) => session.updateChapter(layout: layout),
                      label: Text(_layoutLabel(layout)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionLabel('路径线条'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in StoryPathStyle.values)
                    ChoiceChip(
                      selected: chapter.pathStyle == style,
                      onSelected: (_) =>
                          session.updateChapter(pathStyle: style),
                      label: Text(_pathStyleLabel(style)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _InspectorSection(
          title: '播放设置',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                key: const Key('editor-show-chapter-title-playback'),
                contentPadding: EdgeInsets.zero,
                title: const Text('录屏时显示章节名'),
                value: session.bundle!.document.showChapterTitleInPlayback,
                onChanged: session.updateShowChapterTitleInPlayback,
              ),
              const SizedBox(height: 4),
              _PlaybackDelayControl(
                seconds: session.bundle!.document.playbackDelaySeconds,
                onChanged: session.updatePlaybackDelaySeconds,
              ),
              const SizedBox(height: 4),
              ListTile(
                key: const Key('editor-background-music'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.music_note_outlined,
                  size: 20,
                  color: XulangColors.muted,
                ),
                title: Text(
                  session.bundle!.document.musicTitle ?? '未添加背景音乐',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  '播放和录屏模式可使用本地音乐',
                  style: TextStyle(fontSize: 11),
                ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            '点击一张图片后，这里会显示\n图片大小、画框、裁切和旋转。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: XulangColors.muted,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _InspectorSection(
          title: '图层顺序',
          child: SizedBox(
            height: 56,
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
                final media =
                    session.bundle!.media
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
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        width: 48,
                        decoration: BoxDecoration(
                          color: XulangColors.elevated,
                          border: Border.all(
                            color: selected
                                ? XulangColors.accent
                                : XulangColors.line,
                            width: selected ? 1.5 : 0.5,
                          ),
                        ),
                        child: media == null
                            ? const Icon(
                                Icons.broken_image_outlined,
                                size: 18,
                                color: XulangColors.muted,
                              )
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
        ),
        const SizedBox(height: 12),
        _InspectorSection(
          title: '画幅',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in GallerySize.values)
                ChoiceChip(
                  selected: placement.size == size,
                  onSelected: (_) =>
                      session.updatePlacement(placement.id, size: size),
                  label: Text(_sizeLabel(size)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InspectorSection(
          title: '画框',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
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
        ),
        const SizedBox(height: 12),
        _InspectorSection(
          title: '裁切与构图',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InspectorSection(
          title: '说明',
          child: TextFormField(
            key: ValueKey('placement-caption-${placement.id}'),
            initialValue: placement.caption,
            maxLength: 60,
            style: const TextStyle(fontSize: 13, color: XulangColors.paper),
            decoration: const InputDecoration(
              labelText: '单图短注释',
              labelStyle: TextStyle(fontSize: 12, color: XulangColors.muted),
              counterStyle: TextStyle(fontSize: 10, color: XulangColors.muted),
            ),
            onChanged: (value) =>
                session.updatePlacement(placement.id, caption: value),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCanvasBackground(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: '画布图片',
          extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
          mimeTypes: ['image/*'],
        ),
      ],
    );
    if (file == null) return;
    await session.importCanvasBackground(file.path);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已设置自定义画布')));
    }
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
    final fallbackPlacement = chapter.placements.isEmpty
        ? null
        : chapter.placements.first;
    final activePlacement = placement ?? fallbackPlacement;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: widget.panelOpacity),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .06),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                key: const Key('editor-inspector-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '操作面板',
                            style: TextStyle(
                              color: XulangColors.paper,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        _PanelToggleChip(
                          selected:
                              widget.interactionMode ==
                              _EditorInteractionMode.canvas,
                          onSelected: (_) => widget.onFocusCanvas(),
                          label: '画布',
                        ),
                        const SizedBox(width: 6),
                        _PanelToggleChip(
                          selected:
                              widget.interactionMode ==
                                  _EditorInteractionMode.image &&
                              activePlacement != null,
                          onSelected: (_) {
                            final target = activePlacement;
                            if (target != null) {
                              widget.onFocusPlacement(target.id);
                            }
                          },
                          label: '图片',
                        ),
                        const SizedBox(width: 6),
                        _PanelToggleChip(
                          key: const Key('editor-mode-sticker'),
                          selected:
                              widget.interactionMode ==
                              _EditorInteractionMode.sticker,
                          onSelected: (_) => widget.onFocusSticker(),
                          label: '贴画',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildModePanel(context, chapter, activePlacement),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModePanel(
    BuildContext context,
    GalleryChapter chapter,
    GalleryPlacement? placement,
  ) {
    switch (widget.interactionMode) {
      case _EditorInteractionMode.canvas:
        return _buildCanvasPanel(context, chapter);
      case _EditorInteractionMode.image:
        return _buildPlacementPanel(context, chapter, placement);
      case _EditorInteractionMode.sticker:
        return _buildStickerPanel(context, chapter);
    }
  }

  Widget _buildStickerPanel(BuildContext context, GalleryChapter chapter) {
    return _InspectorSection(
      title: '贴画',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '选择一个小物品后，点击画布放置；已放置的贴画可以拖动，点垃圾桶删除。',
            style: TextStyle(fontSize: 11, color: XulangColors.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in GalleryStickerKind.values)
                ChoiceChip(
                  key: Key('editor-sticker-kind-${kind.name}'),
                  selected: widget.selectedStickerKind == kind,
                  onSelected: (_) => widget.onSelectStickerKind(kind),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AtmosphericSticker(kind: kind, size: 22),
                      const SizedBox(width: 6),
                      Text(_stickerKindLabel(kind)),
                    ],
                  ),
                ),
            ],
          ),
          if (chapter.stickers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionLabel('已添加贴画'),
            const SizedBox(height: 6),
            for (final sticker in chapter.stickers)
              ListTile(
                key: Key('editor-sticker-item-${sticker.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: AtmosphericSticker(kind: sticker.kind, size: 28),
                title: Text(_stickerKindLabel(sticker.kind)),
                subtitle: const Text('在画布上点叉删除'),
              ),
          ],
        ],
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
}

class _CanvasBackgroundControl extends StatelessWidget {
  const _CanvasBackgroundControl({
    required this.path,
    required this.opacity,
    required this.onPick,
    required this.onClear,
    required this.onOpacityChanged,
  });

  final String? path;
  final double opacity;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    final hasCustom = path != null && path!.trim().isNotEmpty;
    return Container(
      key: const Key('editor-canvas-background-control'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wallpaper_outlined,
                size: 18,
                color: XulangColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCustom ? p.basename(path!) : '自定义画布图片',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: onPick,
                child: Text(hasCustom ? '更换' : '上传'),
              ),
              if (hasCustom)
                TextButton(onPressed: onClear, child: const Text('清除')),
            ],
          ),
          const SizedBox(height: 6),
          _CropSlider(
            key: const Key('editor-canvas-background-opacity-slider'),
            label: '画布透明度',
            value: opacity.clamp(0, 1).toDouble(),
            min: 0,
            max: 1,
            onChanged: onOpacityChanged,
          ),
          const Text(
            '上传的图片会叠在当前内置画布上，适合做纹理、纸张或氛围底图。',
            style: TextStyle(fontSize: 11, color: XulangColors.muted),
          ),
        ],
      ),
    );
  }
}

class _PlaybackDelayControl extends StatelessWidget {
  const _PlaybackDelayControl({required this.seconds, required this.onChanged});

  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = seconds.clamp(0, 30);
    return Container(
      key: const Key('editor-playback-delay-control'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: XulangColors.muted,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '录屏延迟播放',
                  style: TextStyle(fontSize: 13, color: XulangColors.paper),
                ),
              ),
              Text(
                '$value 秒',
                key: const Key('editor-playback-delay-value'),
                style: const TextStyle(
                  fontSize: 12,
                  color: XulangColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            key: const Key('editor-playback-delay-slider'),
            value: value.toDouble(),
            min: 0,
            max: 30,
            divisions: 30,
            label: '$value 秒',
            onChanged: (next) => onChanged(next.round()),
          ),
          const Text(
            '开始录屏后先等待这段时间，再自动播放。',
            style: TextStyle(fontSize: 11, color: XulangColors.muted),
          ),
        ],
      ),
    );
  }
}

class _PanelToggleChip extends StatelessWidget {
  const _PanelToggleChip({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  final bool selected;
  final ValueChanged<bool> onSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: onSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          color: selected ? XulangColors.accent : XulangColors.paper,
        ),
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [_SectionLabel(title), const SizedBox(height: 8), child],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: XulangColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
    );
  }
}

enum _EditorInteractionMode { canvas, image, sticker }

String _stickerKindLabel(GalleryStickerKind kind) => switch (kind) {
  GalleryStickerKind.star => '星芒标记',
  GalleryStickerKind.sparkle => '碎光',
  GalleryStickerKind.heart => '暖心印',
  GalleryStickerKind.leaf => '影叶',
  GalleryStickerKind.flower => '干花',
  GalleryStickerKind.crescentMoon => '月弧',
  GalleryStickerKind.firefly => '萤光',
  GalleryStickerKind.comet => '彗尾',
  GalleryStickerKind.pressedPetal => '压花瓣',
  GalleryStickerKind.paperTape => '纸胶带',
  GalleryStickerKind.fogRibbon => '雾绸',
  GalleryStickerKind.waxSeal => '蜡封',
};

class _CropSlider extends StatefulWidget {
  const _CropSlider({
    super.key,
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
  State<_CropSlider> createState() => _CropSliderState();
}

class _CropSliderState extends State<_CropSlider> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    _controller.text = widget.value.toStringAsFixed(1);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _commitEditing() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null) {
      widget.onChanged(parsed.clamp(widget.min, widget.max));
    }
    setState(() => _editing = false);
  }

  void _resetValue() {
    final mid = (widget.min + widget.max) / 2;
    widget.onChanged(mid);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 78,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 12, color: XulangColors.paper),
            ),
          ),
          Expanded(
            child: Slider(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              onChanged: widget.onChanged,
            ),
          ),
          GestureDetector(
            onTap: _editing ? null : _startEditing,
            onDoubleTap: _resetValue,
            child: Container(
              width: 54,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _editing
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: XulangColors.paper,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        border: UnderlineInputBorder(),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: XulangColors.accent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: XulangColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _commitEditing(),
                      onTapOutside: (_) => _commitEditing(),
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        widget.value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: XulangColors.paper,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
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
