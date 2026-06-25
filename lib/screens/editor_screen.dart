import 'dart:async';
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
  bool _showPanel = false; // 默认隐藏浮动面板
  double _panelOpacity = 0.48;
  _EditorInteractionMode _interactionMode = _EditorInteractionMode.canvas;
  _PendingPathConnection? _pendingPathConnection;
  String? _selectedPlacementId;
  Offset _floatingBallOffset = const Offset(16, 560);

  EditorSession get session => widget.session;

  void _setPanelOpacity(double value) {
    setState(() => _panelOpacity = value.clamp(0.18, 0.82));
  }

  void _focusCanvas() {
    setState(() {
      _interactionMode = _EditorInteractionMode.canvas;
      _pendingPathConnection = null;
      _selectedPlacementId = null;
      _showPanel = true;
    });
  }

  void _focusPlacement(String placementId) {
    setState(() {
      _interactionMode = _EditorInteractionMode.image;
      _pendingPathConnection = null;
      _selectedPlacementId = placementId;
      _showPanel = true;
    });
  }

  void _focusPath() {
    setState(() {
      _interactionMode = _EditorInteractionMode.path;
      _showPanel = true;
    });
  }

  void _startPathConnection(_PendingPathConnection connection) {
    setState(() {
      _interactionMode = _EditorInteractionMode.path;
      _pendingPathConnection = connection;
      _showPanel = false;
    });
  }

  void _cancelPathConnection() {
    setState(() {
      _pendingPathConnection = null;
      _showPanel = true;
    });
  }

  Future<void> _finishPathDrawing(List<CustomPathPoint> points) async {
    final draft = _pendingPathConnection;
    if (draft == null) return;
    if (points.length < 2) {
      setState(() => _showPanel = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('路径太短，请重新画一条曲线')),
        );
      }
      return;
    }
    final midpoint = points[points.length ~/ 2];
    await session.addCustomPathConnection(
      CustomPathConnection(
        id: 'path-${DateTime.now().microsecondsSinceEpoch}',
        fromPlacementId: draft.fromPlacementId,
        toPlacementId: draft.toPlacementId,
        points: points,
        noteX: midpoint.x,
        noteY: midpoint.y,
      ),
    );
    if (!mounted) return;
    setState(() {
      _pendingPathConnection = null;
      _showPanel = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存手绘路径')),
    );
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
                        pendingPathConnection: _pendingPathConnection,
                        onPathDrawingCompleted: _finishPathDrawing,
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
                        pendingPathConnection: _pendingPathConnection,
                        panelOpacity: _panelOpacity,
                        onPanelOpacityChanged: _setPanelOpacity,
                        onFocusCanvas: _focusCanvas,
                        onFocusPlacement: _focusPlacement,
                        onFocusPath: _focusPath,
                        onStartPathConnection: _startPathConnection,
                        onCancelPathConnection: _cancelPathConnection,
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
                          pendingPathConnection: _pendingPathConnection,
                          onPathDrawingCompleted: _finishPathDrawing,
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
                      pendingPathConnection: _pendingPathConnection,
                      panelOpacity: _panelOpacity,
                      onPanelOpacityChanged: _setPanelOpacity,
                      onFocusCanvas: _focusCanvas,
                      onFocusPlacement: _focusPlacement,
                      onFocusPath: _focusPath,
                      onStartPathConnection: _startPathConnection,
                      onCancelPathConnection: _cancelPathConnection,
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
    required this.pendingPathConnection,
    required this.panelOpacity,
    required this.onPanelOpacityChanged,
    required this.onFocusCanvas,
    required this.onFocusPlacement,
    required this.onFocusPath,
    required this.onStartPathConnection,
    required this.onCancelPathConnection,
    required this.onDismiss,
    required this.landscape,
  });

  final EditorSession session;
  final _EditorInteractionMode interactionMode;
  final String? selectedPlacementId;
  final _PendingPathConnection? pendingPathConnection;
  final double panelOpacity;
  final ValueChanged<double> onPanelOpacityChanged;
  final VoidCallback onFocusCanvas;
  final ValueChanged<String> onFocusPlacement;
  final VoidCallback onFocusPath;
  final ValueChanged<_PendingPathConnection> onStartPathConnection;
  final VoidCallback onCancelPathConnection;
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
                        pendingPathConnection: widget.pendingPathConnection,
                        panelOpacity: widget.panelOpacity,
                        onPanelOpacityChanged: widget.onPanelOpacityChanged,
                        onFocusCanvas: widget.onFocusCanvas,
                        onFocusPlacement: widget.onFocusPlacement,
                        onFocusPath: widget.onFocusPath,
                        onStartPathConnection: widget.onStartPathConnection,
                        onCancelPathConnection: widget.onCancelPathConnection,
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
    this.pendingPathConnection,
    this.onPathDrawingCompleted,
    this.onCanvasTap,
    this.onPlacementTap,
  });

  final EditorSession session;
  final _EditorInteractionMode interactionMode;
  final _PendingPathConnection? pendingPathConnection;
  final Future<void> Function(List<CustomPathPoint> points)?
  onPathDrawingCompleted;
  final VoidCallback? onCanvasTap;
  final ValueChanged<String>? onPlacementTap;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final Map<String, double> _cameraProgressByChapter = {};
  final Map<String, GalleryPlacement> _placementDrafts = {};
  final List<CustomPathPoint> _activePathPoints = [];
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
    final scale = targetScale.clamp(0.35, 3.0);
    final center = Offset(viewport.width / 2, viewport.height / 2);
    _zoomController.value = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(scale)
      ..translate(-center.dx, -center.dy);
    setState(() {});
  }

  EditorSession get session => widget.session;
  bool get _isCanvasMode =>
      widget.interactionMode == _EditorInteractionMode.canvas;
  bool get _isImageMode =>
      widget.interactionMode == _EditorInteractionMode.image;
  bool get _isPathMode => widget.interactionMode == _EditorInteractionMode.path;
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

  void _startPathDrawing(CustomPathPoint point) {
    if (!_isPathMode || widget.pendingPathConnection == null) return;
    setState(() {
      _activePathPoints
        ..clear()
        ..add(point);
    });
  }

  void _updatePathDrawing(CustomPathPoint point) {
    if (!_isPathMode || widget.pendingPathConnection == null) return;
    if (_activePathPoints.isNotEmpty) {
      final last = _activePathPoints.last;
      final dx = point.x - last.x;
      final dy = point.y - last.y;
      if (math.sqrt(dx * dx + dy * dy) < 0.006) return;
    }
    setState(() => _activePathPoints.add(point));
  }

  void _endPathDrawing() {
    if (_activePathPoints.isEmpty) return;
    final points = List<CustomPathPoint>.unmodifiable(_activePathPoints);
    setState(_activePathPoints.clear);
    final onCompleted = widget.onPathDrawingCompleted;
    if (onCompleted != null) {
      unawaited(onCompleted(points));
    }
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
        final canvasTap = _isCanvasMode ? widget.onCanvasTap : null;
        final placementTap = _isPathMode ? null : widget.onPlacementTap;
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                key: const Key('editor-preview-zoom'),
                transformationController: _zoomController,
                minScale: 0.35,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(240),
                constrained: false,
                panEnabled: _isCanvasMode,
                scaleEnabled: _isCanvasMode,
                onInteractionEnd: (_) => setState(() {}),
                child: SizedBox(
                  width: viewport.width,
                  height: viewport.height,
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
                      if (!_isCanvasMode || _previewPointerCount != 1 || _isZoomed) {
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
                        placementEditingEnabled: placementEditingEnabled,
                        pathEditingEnabled: _isPathMode,
                        activePathPoints: _activePathPoints,
                        onPathDrawStart: widget.pendingPathConnection == null
                            ? null
                            : _startPathDrawing,
                        onPathDrawUpdate: widget.pendingPathConnection == null
                            ? null
                            : _updatePathDrawing,
                        onPathDrawEnd: widget.pendingPathConnection == null
                            ? null
                            : _endPathDrawing,
                        onPathConnectionChanged:
                            session.updateCustomPathConnection,
                        onPlacementTap: placementTap,
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
    required this.pendingPathConnection,
    required this.panelOpacity,
    required this.onPanelOpacityChanged,
    required this.onFocusCanvas,
    required this.onFocusPlacement,
    required this.onFocusPath,
    required this.onStartPathConnection,
    required this.onCancelPathConnection,
  });

  final EditorSession session;
  final _EditorInteractionMode interactionMode;
  final String? selectedPlacementId;
  final _PendingPathConnection? pendingPathConnection;
  final double panelOpacity;
  final ValueChanged<double> onPanelOpacityChanged;
  final VoidCallback onFocusCanvas;
  final ValueChanged<String> onFocusPlacement;
  final VoidCallback onFocusPath;
  final ValueChanged<_PendingPathConnection> onStartPathConnection;
  final VoidCallback onCancelPathConnection;

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
                min: 0.18,
                max: 0.82,
                onChanged: widget.onPanelOpacityChanged,
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              if (chapter.layout == GalleryLayout.storyPath)
                _buildPathEditor(context, chapter),
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

  Widget _buildPathPanel(BuildContext context, GalleryChapter chapter) {
    final pending = widget.pendingPathConnection;
    return _InspectorSection(
      title: '路径编辑',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '路径模式下，画布缩放和图片拖动会暂时关闭，只处理路径相关操作。',
            style: TextStyle(fontSize: 11, color: XulangColors.muted),
          ),
          const SizedBox(height: 10),
          if (chapter.layout != GalleryLayout.storyPath)
            FilledButton.tonal(
              key: const Key('editor-enable-story-path-layout'),
              onPressed: () => session.updateChapter(
                layout: GalleryLayout.storyPath,
              ),
              child: const Text('切换到故事路径布局'),
            )
          else ...[
            if (pending == null)
              FilledButton.icon(
                key: const Key('editor-create-path-connection'),
                onPressed: chapter.placements.length < 2
                    ? null
                    : () => _selectPathConnection(context, chapter),
                icon: const Icon(Icons.gesture, size: 17),
                label: const Text('新建路径'),
              )
            else
              _PathDraftNotice(
                fromLabel: _placementLabel(chapter, pending.fromPlacementId),
                toLabel: _placementLabel(chapter, pending.toPlacementId),
                onCancel: widget.onCancelPathConnection,
              ),
            if (chapter.customPathConnections.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionLabel('已连接路径'),
              const SizedBox(height: 6),
              for (final connection in chapter.customPathConnections)
                _PathConnectionSummary(
                  connection: connection,
                  fromLabel: _placementLabel(chapter, connection.fromPlacementId),
                  toLabel: _placementLabel(chapter, connection.toPlacementId),
                  onNoteChanged: (note) => session.updateCustomPathConnection(
                    connection.copyWith(note: note),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _SectionLabel('旧版锚点编辑'),
            const SizedBox(height: 6),
            _buildPathEditor(context, chapter),
          ],
        ],
      ),
    );
  }

  Future<void> _selectPathConnection(
    BuildContext context,
    GalleryChapter chapter,
  ) async {
    var fromId = chapter.placements.first.id;
    var toId = chapter.placements.length > 1
        ? chapter.placements[1].id
        : chapter.placements.first.id;
    final draft = await showDialog<_PendingPathConnection>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('选择路径连接'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('editor-path-from-dropdown'),
                  value: fromId,
                  decoration: const InputDecoration(labelText: '起点图片'),
                  items: [
                    for (final placement in chapter.placements)
                      DropdownMenuItem(
                        value: placement.id,
                        child: Text(_placementLabel(chapter, placement.id)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => fromId = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('editor-path-to-dropdown'),
                  value: toId,
                  decoration: const InputDecoration(labelText: '终点图片'),
                  items: [
                    for (final placement in chapter.placements)
                      DropdownMenuItem(
                        value: placement.id,
                        child: Text(_placementLabel(chapter, placement.id)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => toId = value);
                  },
                ),
                if (fromId == toId) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '起点和终点不能是同一张图。',
                    style: TextStyle(color: XulangColors.accent, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                key: const Key('editor-start-path-drawing'),
                onPressed: fromId == toId
                    ? null
                    : () => Navigator.pop(
                        context,
                        _PendingPathConnection(
                          fromPlacementId: fromId,
                          toPlacementId: toId,
                        ),
                      ),
                child: const Text('开始手绘'),
              ),
            ],
          );
        },
      ),
    );
    if (draft != null) {
      widget.onStartPathConnection(draft);
    }
  }

  String _placementLabel(GalleryChapter chapter, String placementId) {
    final index = chapter.placements.indexWhere((item) => item.id == placementId);
    if (index < 0) return placementId;
    final placement = chapter.placements[index];
    final caption = placement.caption.trim();
    return caption.isEmpty ? '图 ${index + 1}' : '图 ${index + 1} · $caption';
  }

  Widget _buildPathEditor(BuildContext context, GalleryChapter chapter) {
    final anchors = chapter.customPathAnchors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => anchors == null
                    ? _startPathDrawing(context)
                    : _addPathAnchor(chapter),
                child: Text(anchors == null ? '绘制路径' : '添加锚点'),
              ),
            ),
            const SizedBox(width: 8),
            if (anchors != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => session.clearCustomPath(),
                  child: const Text('重置'),
                ),
              ),
          ],
        ),
        if (anchors != null) ...[
          const SizedBox(height: 8),
          Text(
            '已自定义 ${anchors.length} 个锚点，可编辑位置与文字',
            style: const TextStyle(fontSize: 11, color: XulangColors.muted),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < anchors.length; index++)
            _PathAnchorEditor(
              key: ValueKey('path-anchor-${chapter.id}-$index'),
              index: index,
              anchor: anchors[index],
              canDelete: anchors.length > 2,
              onChanged: (anchor) => _replacePathAnchor(chapter, index, anchor),
              onDelete: () => _removePathAnchor(chapter, index),
            ),
        ],
      ],
    );
  }

  Future<void> _replacePathAnchor(
    GalleryChapter chapter,
    int index,
    CustomPathAnchor anchor,
  ) async {
    final anchors = chapter.customPathAnchors;
    if (anchors == null || index < 0 || index >= anchors.length) return;
    final next = List<CustomPathAnchor>.of(anchors);
    next[index] = anchor;
    await session.updateChapterPath(next);
  }

  Future<void> _addPathAnchor(GalleryChapter chapter) async {
    final anchors = List<CustomPathAnchor>.of(
      chapter.customPathAnchors ?? const <CustomPathAnchor>[],
    );
    if (anchors.isEmpty) {
      await _startPathDrawing(context);
      return;
    }
    final previous = anchors.last;
    anchors.add(
      CustomPathAnchor(
        x: (previous.x + 0.12).clamp(0.08, 0.92),
        y: previous.y.clamp(0.08, 0.92),
        label: '点 ${anchors.length + 1}',
      ),
    );
    await session.updateChapterPath(anchors);
  }

  Future<void> _removePathAnchor(GalleryChapter chapter, int index) async {
    final anchors = chapter.customPathAnchors;
    if (anchors == null || anchors.length <= 2) return;
    final next = List<CustomPathAnchor>.of(anchors)..removeAt(index);
    await session.updateChapterPath(next);
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
                          selected: widget.interactionMode ==
                              _EditorInteractionMode.canvas,
                          onSelected: (_) => widget.onFocusCanvas(),
                          label: '画布',
                        ),
                        const SizedBox(width: 6),
                        _PanelToggleChip(
                          selected: widget.interactionMode ==
                                  _EditorInteractionMode.image &&
                              placement != null,
                          onSelected: (_) {
                            if (placement != null) {
                              widget.onFocusPlacement(placement.id);
                            }
                          },
                          label: '图片',
                        ),
                        const SizedBox(width: 6),
                        _PanelToggleChip(
                          key: const Key('editor-mode-path'),
                          selected: widget.interactionMode ==
                              _EditorInteractionMode.path,
                          onSelected: (_) => widget.onFocusPath(),
                          label: '路径',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildModePanel(context, chapter, placement),
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
      case _EditorInteractionMode.path:
        return _buildPathPanel(context, chapter);
    }
  }

  Future<void> _startPathDrawing(BuildContext context) async {
    final chapter = session.selectedChapter!;
    if (chapter.placements.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加图片')));
      return;
    }

    // 创建初始锚点（每张图片一个）
    final anchors = chapter.placements.asMap().entries.map((e) {
      final idx = e.key;
      final x = 0.1 + (idx * 0.8 / (chapter.placements.length - 1));
      return CustomPathAnchor(x: x, y: 0.5, label: '点 ${idx + 1}');
    }).toList();

    await session.updateChapterPath(anchors);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已创建 ${anchors.length} 个锚点，可在画布上编辑'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

class _PathDraftNotice extends StatelessWidget {
  const _PathDraftNotice({
    required this.fromLabel,
    required this.toLabel,
    required this.onCancel,
  });

  final String fromLabel;
  final String toLabel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('editor-path-draft-notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: XulangColors.accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: XulangColors.accent.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '在画布上用手指描绘曲线',
            style: TextStyle(
              color: XulangColors.paper,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$fromLabel → $toLabel',
            style: const TextStyle(fontSize: 12, color: XulangColors.muted),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('editor-cancel-path-draft'),
              onPressed: onCancel,
              child: const Text('取消绘制'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathConnectionSummary extends StatelessWidget {
  const _PathConnectionSummary({
    required this.connection,
    required this.fromLabel,
    required this.toLabel,
    required this.onNoteChanged,
  });

  final CustomPathConnection connection;
  final String fromLabel;
  final String toLabel;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('editor-path-connection-${connection.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 17, color: XulangColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$fromLabel → $toLabel · ${connection.points.length} 点',
                  style: const TextStyle(
                    fontSize: 12,
                    color: XulangColors.paper,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: Key('editor-path-note-${connection.id}'),
            initialValue: connection.note,
            maxLength: 48,
            style: const TextStyle(fontSize: 12, color: XulangColors.paper),
            decoration: const InputDecoration(
              labelText: '曲线注释',
              hintText: '写一句路径旁的说明',
              counterText: '',
              isDense: true,
            ),
            onChanged: onNoteChanged,
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

class _PathAnchorEditor extends StatelessWidget {
  const _PathAnchorEditor({
    super.key,
    required this.index,
    required this.anchor,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final CustomPathAnchor anchor;
  final bool canDelete;
  final ValueChanged<CustomPathAnchor> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '锚点 ${index + 1}',
                style: const TextStyle(
                  color: XulangColors.paper,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '删除锚点',
                visualDensity: VisualDensity.compact,
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.remove_circle_outline, size: 18),
              ),
            ],
          ),
          TextFormField(
            key: Key('path-anchor-label-$index'),
            initialValue: anchor.label,
            style: const TextStyle(color: XulangColors.paper, fontSize: 12),
            decoration: const InputDecoration(labelText: '线条文字', isDense: true),
            onFieldSubmitted: (value) =>
                onChanged(anchor.copyWith(label: value.trim())),
          ),
          const SizedBox(height: 10),
          _AnchorSlider(
            label: '横向',
            value: anchor.x,
            onChanged: (value) => onChanged(anchor.copyWith(x: value)),
          ),
          _AnchorSlider(
            label: '纵向',
            value: anchor.y,
            onChanged: (value) => onChanged(anchor.copyWith(y: value)),
          ),
        ],
      ),
    );
  }
}

class _AnchorSlider extends StatelessWidget {
  const _AnchorSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(color: XulangColors.muted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0.04, 0.96),
            min: 0.04,
            max: 0.96,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(color: XulangColors.muted, fontSize: 10),
          ),
        ),
      ],
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

enum _EditorInteractionMode { canvas, image, path }

class _PendingPathConnection {
  const _PendingPathConnection({
    required this.fromPlacementId,
    required this.toPlacementId,
  });

  final String fromPlacementId;
  final String toPlacementId;
}

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
          SizedBox(
            width: 72,
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 12, color: XulangColors.muted),
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
            child: SizedBox(
              width: 48,
              height: 28,
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
