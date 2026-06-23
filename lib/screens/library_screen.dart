import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LibraryHeader(
                onCreate: () => _createExhibition(context, ref),
                onImportTemplate: () => _importTemplate(context, ref),
                onInfo: () => _showLocalInfo(context),
              ),
              const SizedBox(height: 26),
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
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      final path = picked?.files.single.path;
      if (path == null || !context.mounted) return;
      final repository = ref.read(galleryRepositoryProvider);
      final id = repository.createId();
      final now = DateTime.now();
      final base = GalleryDocument.create(
        id: id,
        title: '导入的模板',
        createdAt: now,
      );
      final document = const ExhibitionTemplateCodec().applyToDocument(
        base: base,
        templateJson: await File(path).readAsString(),
        createId: repository.createId,
        now: now,
      );
      await repository.save(GalleryBundle(document: document, media: const []));
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
  });

  final VoidCallback onCreate;
  final VoidCallback onImportTemplate;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '叙廊',
                style: TextStyle(
                  color: XulangColors.paper,
                  fontFamily: 'serif',
                  fontSize: 30,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '你的本地展览',
                style: TextStyle(color: XulangColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '本地存储说明',
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline),
        ),
        IconButton(
          tooltip: '导入模板',
          onPressed: onImportTemplate,
          icon: const Icon(Icons.file_open_outlined),
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 19),
          label: const Text('新建'),
        ),
      ],
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
          padding: const EdgeInsets.only(bottom: 42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 132,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: XulangColors.paper.withValues(alpha: .35),
                  ),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  size: 38,
                  color: XulangColors.paper,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '让照片沿着故事展开',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: XulangColors.paper,
                  fontSize: 23,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '用章节、方向和远近组织记忆。\n所有图片只保存在这台设备。',
                textAlign: TextAlign.center,
                style: TextStyle(color: XulangColors.muted, height: 1.7),
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
              const SizedBox(height: 18),
              const Text(
                '卸载应用会删除全部展览，请谨慎操作。',
                style: TextStyle(color: XulangColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
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
        final columns = constraints.maxWidth > 760
            ? 3
            : constraints.maxWidth > 500
            ? 2
            : 1;
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: columns == 1 ? 1.42 : .82,
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
        return Material(
          color: XulangColors.surface,
          borderRadius: BorderRadius.circular(2),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EditorScreen(exhibitionId: summary.id),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: cover == null
                      ? const _CoverFallback()
                      : GalleryImage(
                          path: cover.thumbnailPath,
                          cacheWidth: 900,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                color: XulangColors.paper,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$imageCount 张照片 · ${_formatDate(summary.updatedAt)}',
                              style: const TextStyle(
                                color: XulangColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (imageCount > 0)
                        IconButton(
                          tooltip: '沉浸观看',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ViewerScreen(exhibitionId: summary.id),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                        ),
                      PopupMenuButton<_CardAction>(
                        tooltip: '更多操作',
                        onSelected: (action) =>
                            _handleAction(context, ref, action),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _CardAction.rename,
                            child: Text('重命名'),
                          ),
                          PopupMenuItem(
                            value: _CardAction.duplicate,
                            child: Text('复制展览'),
                          ),
                          PopupMenuItem(
                            value: _CardAction.delete,
                            child: Text('删除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            content: Text('“${summary.title}”及复制到应用中的图片会被永久删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
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

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: XulangColors.elevated,
      child: Center(
        child: Icon(Icons.photo_size_select_actual_outlined, size: 34),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('无法读取展览\n$error', textAlign: TextAlign.center));
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

void _showLocalInfo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('只属于这台设备', style: TextStyle(fontFamily: 'serif', fontSize: 22)),
          SizedBox(height: 12),
          Text('叙廊不上传图片，也不申请网络权限。导入内容会复制到应用私有空间；卸载应用会永久删除这些展览。'),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime date) => '${date.month}月${date.day}日';
