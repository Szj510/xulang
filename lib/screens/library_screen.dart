import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/editor_screen.dart';
import 'package:xulang/screens/viewer_screen.dart';
import 'package:xulang/share/exhibition_exporter.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/gallery_image.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exhibitions = ref.watch(exhibitionSummariesProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LibraryHeader(
                onCreate: () => _createExhibition(context, ref),
                onImportTemplate: () => _importTemplate(context, ref),
                onInfo: () => _showLocalInfo(context),
                onSettings: () => _showAppSettings(
                  context,
                  onImportTemplate: () => _importTemplate(context, ref),
                ),
              ),
              const SizedBox(height: 14),
              const _OfficialSampleNotice(),
              const SizedBox(height: 22),
              Expanded(
                child: exhibitions.when(
                  data: (items) => items.isEmpty
                      ? _EmptyLibrary(
                          onCreate: () => _createExhibition(context, ref),
                          onImportTemplate: () => _importTemplate(context, ref),
                        )
                      : _ExhibitionGrid(items: items),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _LibraryError(error: error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createExhibition(BuildContext context, WidgetRef ref) async {
    final title = await _textDialog(
      context,
      title: '新建展览',
      hint: '给这段故事起个名字',
      confirmText: '创建',
    );
    if (title == null || title.trim().isEmpty || !context.mounted) return;
    final repository = ref.read(galleryRepositoryProvider);
    final id = repository.createId();
    await repository.createExhibition(
      id: id,
      title: title.trim(),
      now: DateTime.now(),
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(exhibitionId: id)),
    );
  }

  Future<void> _importTemplate(BuildContext context, WidgetRef ref) async {
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: '叙廊模板',
            extensions: ['json'],
            mimeTypes: ['application/json'],
          ),
        ],
      );
      if (picked == null || !context.mounted) return;

      final codec = const ExhibitionTemplateCodec();
      final templateJson = utf8.decode(await picked.readAsBytes());
      if (!context.mounted) return;
      final summary = codec.inspect(templateJson);
      final exhibitionTitle = await _textDialog(
        context,
        title: '命名新展览',
        hint: '展览名称',
        initialValue: summary.title,
        confirmText: '下一步',
      );
      if (exhibitionTitle == null || exhibitionTitle.trim().isEmpty) return;
      if (!context.mounted) return;

      final chapterTitle = await _textDialog(
        context,
        title: summary.chapterCount > 1 ? '命名章节前缀' : '命名章节',
        hint: summary.chapterCount > 1 ? '例如：旅行片段' : '章节名称',
        initialValue: summary.firstChapterTitle,
        confirmText: '选择图片',
      );
      if (chapterTitle == null || chapterTitle.trim().isEmpty) return;
      if (!context.mounted) return;

      final pickedImages = await openFiles(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: '图片',
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
            mimeTypes: ['image/*'],
          ),
        ],
      );
      if (pickedImages.isEmpty || !context.mounted) return;

      final repository = ref.read(galleryRepositoryProvider);
      final importer = ref.read(mediaImportServiceProvider);
      final id = repository.createId();
      final now = DateTime.now();
      final importResult = await importer.importFiles(
        exhibitionId: id,
        sourcePaths: [for (final image in pickedImages) image.path],
        existingAssets: const [],
      );
      if (importResult.selectionMediaIds.isEmpty) return;

      final base = GalleryDocument.create(
        id: id,
        title: exhibitionTitle.trim(),
        createdAt: now,
      );
      final document = codec.applyToDocument(
        base: base,
        templateJson: templateJson,
        createId: repository.createId,
        now: now,
        mediaIds: importResult.selectionMediaIds,
        titleOverride: exhibitionTitle,
        chapterTitleOverride: chapterTitle,
      );
      await repository.save(
        GalleryBundle(document: document, media: importResult.assets),
      );
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => EditorScreen(exhibitionId: id)),
      );
    } catch (caught) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入模板失败：$caught')));
    }
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.onCreate,
    required this.onImportTemplate,
    required this.onInfo,
    required this.onSettings,
  });

  final VoidCallback onCreate;
  final VoidCallback onImportTemplate;
  final VoidCallback onInfo;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '叙廊',
                style: TextStyle(
                  color: XulangColors.paper,
                  fontFamily: 'Noto Serif SC',
                  fontFamilyFallback: [
                    'Noto Sans SC',
                    'PingFang SC',
                    'Microsoft YaHei',
                  ],
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 5,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '你的本地展览',
                style: TextStyle(
                  color: XulangColors.muted,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          tooltip: '本地存储说明',
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline, size: 20),
        ),
        const SizedBox(width: 4),
        _HeaderIconButton(
          tooltip: '设置与使用说明',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
        const SizedBox(width: 4),
        _HeaderIconButton(
          tooltip: '导入模板',
          onPressed: onImportTemplate,
          icon: const Icon(Icons.file_open_outlined, size: 20),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('新建'),
        ),
      ],
    );
  }
}

class _OfficialSampleNotice extends StatelessWidget {
  const _OfficialSampleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: XulangColors.accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: XulangColors.accent.withValues(alpha: .22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined, size: 18, color: XulangColors.accent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '首页内置样例为官方示例，仅用于展示效果；你的新建展览和导入图片仍只保存在本机。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: XulangColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

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
            child: IconTheme(
              data: const IconThemeData(color: XulangColors.muted, size: 20),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onCreate, required this.onImportTemplate});

  final VoidCallback onCreate;
  final VoidCallback onImportTemplate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyGalleryFrame(
                child: const Icon(
                  Icons.auto_stories_outlined,
                  size: 36,
                  color: XulangColors.paper,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '让照片沿着故事展开',
                style: TextStyle(
                  fontFamily: 'Noto Serif SC',
                  fontFamilyFallback: [
                    'Noto Sans SC',
                    'PingFang SC',
                    'Microsoft YaHei',
                  ],
                  color: XulangColors.paper,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '用章节、方向和远近组织记忆。\n所有图片只保存在这台设备。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: XulangColors.muted,
                  fontSize: 13,
                  height: 1.75,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: onCreate,
                    child: const Text('创建第一个展览'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onImportTemplate,
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: const Text('导入模板'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '卸载应用会删除全部展览，请谨慎操作。',
                style: TextStyle(
                  color: XulangColors.muted,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGalleryFrame extends StatelessWidget {
  const _EmptyGalleryFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 140,
      decoration: BoxDecoration(
        color: XulangColors.surface,
        border: Border.all(
          color: XulangColors.paper.withValues(alpha: .20),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: XulangColors.paper.withValues(alpha: .08),
                  width: 0.5,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ExhibitionGrid extends ConsumerWidget {
  const _ExhibitionGrid({required this.items});

  final List<ExhibitionSummary> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 820
            ? 3
            : constraints.maxWidth > 520
            ? 2
            : 1;
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: columns == 1 ? 1.45 : .86,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _ExhibitionCard(summary: items[index]),
        );
      },
    );
  }
}

class _ExhibitionCard extends ConsumerWidget {
  const _ExhibitionCard({required this.summary});

  final ExhibitionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(galleryRepositoryProvider);
    return FutureBuilder<GalleryBundle?>(
      future: repository.load(summary.id),
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        final cover = bundle == null || summary.coverMediaId == null
            ? null
            : bundle.media
                  .where((item) => item.id == summary.coverMediaId)
                  .firstOrNull;
        final imageCount =
            bundle?.document.chapters.fold<int>(
              0,
              (count, chapter) => count + chapter.placements.length,
            ) ??
            0;
        return _MountedCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditorScreen(exhibitionId: summary.id),
            ),
          ),
          cover: cover == null
              ? const _CoverFallback()
              : GalleryImage(path: cover.thumbnailPath, cacheWidth: 900),
          title: summary.title,
          meta: '$imageCount 张照片 · ${_formatDate(summary.updatedAt)}',
          actions: [
            if (imageCount > 0)
              _CardIconButton(
                tooltip: '沉浸观看',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ViewerScreen(exhibitionId: summary.id),
                  ),
                ),
                icon: Icons.play_arrow_rounded,
              ),
            _CardMenuButton(
              onSelected: (action) => _handleAction(context, ref, action),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _CardAction action,
  ) async {
    final repository = ref.read(galleryRepositoryProvider);
    switch (action) {
      case _CardAction.rename:
        final title = await _textDialog(
          context,
          title: '重命名展览',
          initialValue: summary.title,
          hint: '展览名称',
          confirmText: '保存',
        );
        if (title != null && title.trim().isNotEmpty) {
          await repository.renameExhibition(
            summary.id,
            title.trim(),
            DateTime.now(),
          );
        }
      case _CardAction.duplicate:
        await repository.duplicateExhibition(
          sourceId: summary.id,
          newId: repository.createId(),
          now: DateTime.now(),
        );
      case _CardAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除展览？'),
            content: Text(
              '“${summary.title}”及复制到应用中的图片会被永久删除。',
              style: Theme.of(context).dialogTheme.contentTextStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: XulangColors.danger,
                  foregroundColor: XulangColors.paper,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (confirmed == true) await repository.deleteExhibition(summary.id);
    }
  }
}

/// The signature "mounted print" aesthetic.
class _MountedCard extends StatelessWidget {
  const _MountedCard({
    required this.onTap,
    required this.cover,
    required this.title,
    required this.meta,
    required this.actions,
  });

  final VoidCallback onTap;
  final Widget cover;
  final String title;
  final String meta;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: XulangColors.surface,
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: XulangColors.accent.withValues(alpha: .08),
        highlightColor: XulangColors.paper.withValues(alpha: .04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _PrintMount(child: cover),
              ),
            ),
            Container(height: 0.5, color: XulangColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Noto Serif SC',
                            fontFamilyFallback: [
                              'Noto Sans SC',
                              'PingFang SC',
                              'Microsoft YaHei',
                            ],
                            color: XulangColors.paper,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.6,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          style: const TextStyle(
                            color: XulangColors.muted,
                            fontSize: 11,
                            letterSpacing: 0.2,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintMount extends StatelessWidget {
  const _PrintMount({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: XulangColors.elevated,
        border: Border.all(
          color: XulangColors.paper.withValues(alpha: .12),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: XulangColors.paper.withValues(alpha: .06),
              width: 0.5,
            ),
          ),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: XulangColors.elevated,
      child: Center(
        child: Icon(
          Icons.photo_size_select_actual_outlined,
          size: 32,
          color: XulangColors.muted,
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: XulangColors.muted),
          ),
        ),
      ),
    );
  }
}

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton({required this.onSelected});

  final ValueChanged<_CardAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CardAction>(
      tooltip: '更多操作',
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert, size: 18, color: XulangColors.muted),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _CardAction.rename,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text('重命名'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CardAction.duplicate,
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 18),
              SizedBox(width: 12),
              Text('复制展览'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CardAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: XulangColors.danger),
              SizedBox(width: 12),
              Text('删除', style: TextStyle(color: XulangColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 32,
              color: XulangColors.muted,
            ),
            const SizedBox(height: 16),
            Text('无法读取展览', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum _CardAction { rename, duplicate, delete }

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmText,
  String initialValue = '',
}) async {
  var value = initialValue;
  final result = await showDialog<String>(
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
  return result;
}

void _showAppSettings(
  BuildContext context, {
  required VoidCallback onImportTemplate,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置与使用说明',
              style: TextStyle(
                fontFamily: 'Noto Serif SC',
                fontFamilyFallback: [
                  'Noto Sans SC',
                  'PingFang SC',
                  'Microsoft YaHei',
                ],
                fontSize: 22,
                letterSpacing: 1.5,
                color: XulangColors.paper,
              ),
            ),
            const SizedBox(height: 16),
            const _SettingsSectionTitle('怎么使用'),
            const SizedBox(height: 8),
            const _UsageStep(
              icon: Icons.add_photo_alternate_outlined,
              title: '1. 新建展览并导入图片',
              body: '每个展览都可以分章节组织图片，先把素材放进本地故事库。',
            ),
            const _UsageStep(
              icon: Icons.auto_awesome_motion_outlined,
              title: '2. 调整画布、布局、相框和贴画',
              body: '在编辑页右侧操作面板中切换画布、图片、贴画，拖动画面即可微调位置。',
            ),
            const _UsageStep(
              icon: Icons.play_circle_outline,
              title: '3. 进入播放或导出模板',
              body: '播放页用来预览完整叙事节奏，模板可复用当前布局。',
            ),
            const SizedBox(height: 16),
            const _SettingsSectionTitle('常见设置'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.file_open_outlined,
              title: '导入展览模板',
              subtitle: '从本地 JSON 模板快速生成一个新展览。',
              onTap: () {
                Navigator.pop(sheetContext);
                onImportTemplate();
              },
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: '本地存储与隐私',
              subtitle: '图片不会上传，卸载应用会删除应用私有空间中的展览。',
              onTap: () {
                Navigator.pop(sheetContext);
                _showLocalInfo(context);
              },
            ),
            const _SettingsTile(
              icon: Icons.tune_outlined,
              title: '编辑器常用入口',
              subtitle: '画布主题、用户画布图片、贴画、音乐和播放延迟都在作品编辑页设置。',
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        color: XulangColors.accent,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _UsageStep extends StatelessWidget {
  const _UsageStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: XulangColors.muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: XulangColors.muted,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

void _showLocalInfo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '只属于这台设备',
            style: TextStyle(
              fontFamily: 'Noto Serif SC',
              fontFamilyFallback: [
                'Noto Sans SC',
                'PingFang SC',
                'Microsoft YaHei',
              ],
              fontSize: 22,
              letterSpacing: 1.5,
              color: XulangColors.paper,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '叙廊不上传图片，也不申请网络权限。导入内容会复制到应用私有空间；卸载应用会永久删除这些展览。',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: XulangColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime date) => '${date.month}月${date.day}日';
