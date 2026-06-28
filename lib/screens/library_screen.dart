import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/editor_screen.dart';
import 'package:xulang/screens/viewer_screen.dart';
import 'package:xulang/share/exhibition_exporter.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/gallery_image.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  ExhibitionSortMode _sortMode = ExhibitionSortMode.updatedDesc;

  @override
  Widget build(BuildContext context) {
    final exhibitions = ref.watch(exhibitionSummariesProvider);
    final categories = ref.watch(exhibitionCategoriesProvider);
    final selectedCategory = _selectedCategoryId == null
        ? null
        : categories.maybeWhen(
            data: (items) => items
                .where((item) => item.id == _selectedCategoryId)
                .firstOrNull,
            orElse: () => null,
          );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedCategoryId == null) ...[
                _LibraryHeader(
                  onCreate: () => _createExhibition(context),
                  onCreateCategory: () => _createCategory(context),
                  onImportTemplate: () => _importTemplate(context),
                  onInfo: () => _showLocalInfo(context),
                  onSettings: () => _showAppSettings(
                    context,
                    settings: ref
                        .read(appSettingsProvider)
                        .maybeWhen(
                          data: (value) => value,
                          orElse: () => const AppSettings(),
                        ),
                    onSaveSettings: (settings) => ref
                        .read(galleryRepositoryProvider)
                        .saveAppSettings(settings),
                    onImportTemplate: () => _importTemplate(context),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              Expanded(
                child: exhibitions.when(
                  data: (items) => categories.when(
                    data: (categoryItems) => _selectedCategoryId == null
                        ? _CategoryHome(
                            categories: _buildBuckets(categoryItems, items),
                            onOpenCategory: (id) =>
                                setState(() => _selectedCategoryId = id),
                            onCreate: () => _createExhibition(context),
                            onCreateCategory: () => _createCategory(context),
                            onImportTemplate: () => _importTemplate(context),
                          )
                        : _CategoryDetail(
                            title: selectedCategory?.title ?? AppStrings.of(context).uncategorized,
                            searchQuery: _searchQuery,
                            sortMode: _sortMode,
                            items: _filterAndSort(
                              _itemsForCategory(items, selectedCategory?.id),
                            ),
                            categories: categoryItems,
                            onBack: () => setState(() {
                              _selectedCategoryId = null;
                              _searchQuery = '';
                            }),
                            onSearchChanged: (value) =>
                                setState(() => _searchQuery = value),
                            onSortChanged: (value) =>
                                setState(() => _sortMode = value),
                            onCreate: () => _createExhibition(
                              context,
                              categoryId: selectedCategory?.id,
                            ),
                            onMoveCategory: _moveExhibition,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _LibraryError(error: error),
                  ),
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

  List<LibraryCategoryBucket> _buildBuckets(
    List<GalleryCategoryInfo> categories,
    List<ExhibitionSummary> exhibitions,
  ) {
    final buckets = <LibraryCategoryBucket>[
      for (final category in categories)
        LibraryCategoryBucket(
          category: category,
          exhibitions: _itemsForCategory(exhibitions, category.id),
        ),
    ];
    final uncategorized = _itemsForCategory(exhibitions, null);
    if (uncategorized.isNotEmpty || buckets.isEmpty) {
      buckets.add(
        LibraryCategoryBucket(category: null, exhibitions: uncategorized),
      );
    }
    return buckets;
  }

  List<ExhibitionSummary> _itemsForCategory(
    List<ExhibitionSummary> items,
    String? categoryId,
  ) {
    return items
        .where((item) => item.categoryId == categoryId)
        .toList(growable: false);
  }

  List<ExhibitionSummary> _filterAndSort(List<ExhibitionSummary> items) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? [...items]
        : items
              .where((item) => item.title.toLowerCase().contains(query))
              .toList();
    switch (_sortMode) {
      case ExhibitionSortMode.updatedDesc:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case ExhibitionSortMode.titleAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
    }
    return filtered;
  }

  Future<void> _createExhibition(
    BuildContext context, {
    String? categoryId,
  }) async {
    final title = await _textDialog(
      context,
      title: AppStrings.of(context).newExhibitionTitle,
      hint: AppStrings.of(context).exhibitionName,
      confirmText: AppStrings.of(context).create,
    );
    if (title == null || title.trim().isEmpty || !context.mounted) return;
    final repository = ref.read(galleryRepositoryProvider);
    final id = repository.createId();
    await repository.createExhibition(
      id: id,
      title: title.trim(),
      now: DateTime.now(),
      categoryId: categoryId,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(exhibitionId: id)),
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final title = await _textDialog(
      context,
      title: AppStrings.of(context).newCategory,
      hint: AppStrings.of(context).newCategory,
      confirmText: AppStrings.of(context).create,
    );
    if (title == null || title.trim().isEmpty) return;
    final repository = ref.read(galleryRepositoryProvider);
    final existing = ref
        .read(exhibitionCategoriesProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <GalleryCategoryInfo>[],
        );
    await repository.createCategory(
      id: repository.createId(),
      title: title.trim(),
      sortOrder: existing.length,
      now: DateTime.now(),
    );
  }

  Future<void> _moveExhibition(ExhibitionSummary summary, String? categoryId) {
    return ref
        .read(galleryRepositoryProvider)
        .moveExhibitionToCategory(
          exhibitionId: summary.id,
          categoryId: categoryId,
          now: DateTime.now(),
        );
  }

  Future<void> _importTemplate(BuildContext context) async {
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
        hint: AppStrings.of(context).exhibitionName,
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
      final settings = ref
          .read(appSettingsProvider)
          .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
      final importResult = await importer.importFiles(
        exhibitionId: id,
        sourcePaths: [for (final image in pickedImages) image.path],
        existingAssets: const [],
        importMode: settings.mediaImportMode,
      );
      if (importResult.selectionMediaIds.isEmpty) return;

      final base = GalleryDocument.create(
        id: id,
        title: exhibitionTitle.trim(),
        createdAt: now,
      ).copyWith(categoryId: _selectedCategoryId);
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
      ).showSnackBar(SnackBar(content: Text('导入模板失败：')));
    }
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.onCreate,
    required this.onCreateCategory,
    required this.onImportTemplate,
    required this.onInfo,
    required this.onSettings,
  });

  final VoidCallback onCreate;
  final VoidCallback onCreateCategory;
  final VoidCallback onImportTemplate;
  final VoidCallback onInfo;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style: const TextStyle(
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
              const SizedBox(height: 6),
              Text(
                l10n.localGallery,
                style: const TextStyle(
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
          tooltip: l10n.localStorageInfo,
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline, size: 20),
        ),
        const SizedBox(width: 4),
        _HeaderIconButton(
          tooltip: l10n.settingsAndGuide,
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
        const SizedBox(width: 4),
        _HeaderIconButton(
          tooltip: l10n.importTemplate,
          onPressed: onImportTemplate,
          icon: const Icon(Icons.file_open_outlined, size: 20),
        ),
        const SizedBox(width: 4),
        _HeaderIconButton(
          tooltip: l10n.newCategory,
          onPressed: onCreateCategory,
          icon: const Icon(Icons.create_new_folder_outlined, size: 20),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.newExhibition),
        ),
      ],
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
                style: const TextStyle(
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
                    child: Text(AppStrings.of(context).createFirstExhibition),
                  ),
                  OutlinedButton.icon(
                    onPressed: onImportTemplate,
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: Text(AppStrings.of(context).importTemplate),
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

class LibraryCategoryBucket {
  const LibraryCategoryBucket({
    required this.category,
    required this.exhibitions,
  });

  final GalleryCategoryInfo? category;
  final List<ExhibitionSummary> exhibitions;

  String get id => category?.id ?? uncategorizedId;
  String title(AppStrings l10n) => category?.title ?? l10n.uncategorized;
  bool get isUncategorized => category == null;

  static const uncategorizedId = '__uncategorized__';
}

class _CategoryHome extends StatelessWidget {
  const _CategoryHome({
    required this.categories,
    required this.onOpenCategory,
    required this.onCreate,
    required this.onCreateCategory,
    required this.onImportTemplate,
  });

  final List<LibraryCategoryBucket> categories;
  final ValueChanged<String> onOpenCategory;
  final VoidCallback onCreate;
  final VoidCallback onCreateCategory;
  final VoidCallback onImportTemplate;

  @override
  Widget build(BuildContext context) {
    final hasAnyExhibition = categories.any(
      (bucket) => bucket.exhibitions.isNotEmpty,
    );
    if (!hasAnyExhibition &&
        categories.length == 1 &&
        categories.single.isUncategorized) {
      return _EmptyLibrary(
        onCreate: onCreate,
        onImportTemplate: onImportTemplate,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 560
            ? 2
            : 1;
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: columns == 1 ? 1.85 : 1.22,
          ),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == categories.length) {
              return _NewCategoryCard(onTap: onCreateCategory);
            }
            return _CategoryBoxCard(
              bucket: categories[index],
              onTap: () => onOpenCategory(categories[index].id),
            );
          },
        );
      },
    );
  }
}

class _CategoryBoxCard extends StatelessWidget {
  const _CategoryBoxCard({required this.bucket, required this.onTap});

  final LibraryCategoryBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previews = bucket.exhibitions.take(4).toList(growable: false);
    return Material(
      color: XulangColors.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-.45, -.55),
                    radius: 1.4,
                    colors: [
                      XulangColors.paper.withValues(alpha: .10),
                      XulangColors.elevated,
                      XulangColors.ink,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              top: 20,
              bottom: 64,
              child: _StackedEnvelopePreview(previews: previews),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bucket.title(AppStrings.of(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: XulangColors.paper,
                            fontFamily: 'Noto Serif SC',
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          AppStrings.of(context).exhibitionCount(bucket.exhibitions.length),
                          style: const TextStyle(
                            color: XulangColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: XulangColors.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedEnvelopePreview extends StatelessWidget {
  const _StackedEnvelopePreview({required this.previews});

  final List<ExhibitionSummary> previews;

  @override
  Widget build(BuildContext context) {
    if (previews.isEmpty) {
      return const _EmptyCategoryBox();
    }
    final rotations = [-.12, .08, -.04, .13];
    final offsets = [
      const Offset(-26, 14),
      const Offset(18, 4),
      const Offset(-4, -4),
      const Offset(34, 18),
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var index = previews.length - 1; index >= 0; index--)
          Transform.translate(
            offset: offsets[index % offsets.length],
            child: Transform.rotate(
              angle: rotations[index % rotations.length],
              child: _EnvelopeThumbnail(summary: previews[index]),
            ),
          ),
      ],
    );
  }
}

class _EnvelopeThumbnail extends ConsumerWidget {
  const _EnvelopeThumbnail({required this.summary});

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
        return Container(
          width: 112,
          height: 144,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8DFCE),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .38),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: cover == null
                ? const ColoredBox(
                    color: XulangColors.elevated,
                    child: Icon(
                      Icons.photo_outlined,
                      color: XulangColors.muted,
                    ),
                  )
                : GalleryImage(path: cover.thumbnailPath, cacheWidth: 400),
          ),
        );
      },
    );
  }
}

class _EmptyCategoryBox extends StatelessWidget {
  const _EmptyCategoryBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: XulangColors.paper.withValues(alpha: .10)),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: XulangColors.muted,
          size: 36,
        ),
      ),
    );
  }
}

class _NewCategoryCard extends StatelessWidget {
  const _NewCategoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        side: BorderSide(color: XulangColors.paper.withValues(alpha: .16)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.create_new_folder_outlined, size: 30),
          SizedBox(height: 10),
          Text(AppStrings.of(context).newCategory),
        ],
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.title,
    required this.searchQuery,
    required this.sortMode,
    required this.items,
    required this.categories,
    required this.onBack,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onCreate,
    required this.onMoveCategory,
  });

  final String title;
  final String searchQuery;
  final ExhibitionSortMode sortMode;
  final List<ExhibitionSummary> items;
  final List<GalleryCategoryInfo> categories;
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ExhibitionSortMode> onSortChanged;
  final VoidCallback onCreate;
  final Future<void> Function(ExhibitionSummary summary, String? categoryId)
  onMoveCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: AppStrings.of(context).backToCategories,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: XulangColors.paper,
                  fontFamily: 'Noto Serif SC',
                  fontSize: 24,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 17),
              label: Text(AppStrings.of(context).newExhibition),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: AppStrings.of(context).searchExhibitions,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<ExhibitionSortMode>(
              value: sortMode,
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
              items: const [
                DropdownMenuItem(
                  value: ExhibitionSortMode.updatedDesc,
                  child: Text(AppStrings.of(context).sortByTime),
                ),
                DropdownMenuItem(
                  value: ExhibitionSortMode.titleAsc,
                  child: Text(AppStrings.of(context).sortByName),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    AppStrings.of(context).emptyCategory,
                    style: TextStyle(color: XulangColors.muted),
                  ),
                )
              : _ExhibitionGrid(
                  items: items,
                  categories: categories,
                  onMoveCategory: onMoveCategory,
                ),
        ),
      ],
    );
  }
}

class _ExhibitionGrid extends ConsumerWidget {
  const _ExhibitionGrid({
    required this.items,
    required this.categories,
    required this.onMoveCategory,
  });

  final List<ExhibitionSummary> items;
  final List<GalleryCategoryInfo> categories;
  final Future<void> Function(ExhibitionSummary summary, String? categoryId)
  onMoveCategory;

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
          itemBuilder: (context, index) => _ExhibitionCard(
            summary: items[index],
            categories: categories,
            onMoveCategory: onMoveCategory,
          ),
        );
      },
    );
  }
}

class _ExhibitionCard extends ConsumerWidget {
  const _ExhibitionCard({
    required this.summary,
    required this.categories,
    required this.onMoveCategory,
  });

  final ExhibitionSummary summary;
  final List<GalleryCategoryInfo> categories;
  final Future<void> Function(ExhibitionSummary summary, String? categoryId)
  onMoveCategory;

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
          title: _displayExhibitionTitle(summary),
          meta: '${AppStrings.of(context).photoCount(imageCount)} · ${_formatDate(context, summary.updatedAt)}',
          actions: [
            if (imageCount > 0)
              _CardIconButton(
                tooltip: AppStrings.of(context).immersiveView,
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
          title: AppStrings.of(context).renameExhibition,
          initialValue: summary.title,
          hint: AppStrings.of(context).exhibitionName,
          confirmText: AppStrings.of(context).save,
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
      case _CardAction.move:
        final nextCategoryId = await _pickCategoryForExhibition(
          context,
          categories,
          summary.categoryId,
        );
        if (nextCategoryId != _categoryDialogCancelled) {
          await onMoveCategory(
            summary,
            nextCategoryId == LibraryCategoryBucket.uncategorizedId
                ? null
                : nextCategoryId,
          );
        }
      case _CardAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppStrings.of(context).deleteExhibitionTitle),
            content: Text(
              '“${_displayExhibitionTitle(summary)}”及复制到应用中的图片会被永久删除。',
              style: Theme.of(context).dialogTheme.contentTextStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.of(context).cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: XulangColors.danger,
                  foregroundColor: XulangColors.paper,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.of(context).delete),
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
      tooltip: AppStrings.of(context).moreActions,
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert, size: 18, color: XulangColors.muted),
      itemBuilder: (context) {
        final l10n = AppStrings.of(context);
        return [
        PopupMenuItem(
          value: _CardAction.rename,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text(l10n.rename),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CardAction.duplicate,
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 18),
              SizedBox(width: 12),
              Text(l10n.duplicateExhibition),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CardAction.move,
          child: Row(
            children: [
              Icon(Icons.drive_file_move_outlined, size: 18),
              SizedBox(width: 12),
              Text(l10n.moveCategory),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CardAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: XulangColors.danger),
              SizedBox(width: 12),
              Text(l10n.delete, style: const TextStyle(color: XulangColors.danger)),
            ],
          ),
        ),
      ];
      },
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
            Text(AppStrings.of(context).cannotReadExhibitions, style: Theme.of(context).textTheme.headlineSmall),
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

enum _CardAction { rename, duplicate, move, delete }

const _categoryDialogCancelled = '__category_dialog_cancelled__';

Future<String?> _pickCategoryForExhibition(
  BuildContext context,
  List<GalleryCategoryInfo> categories,
  String? currentCategoryId,
) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(AppStrings.of(context).moveToCategory),
      children: [
        _CategoryChoiceOption(
          id: LibraryCategoryBucket.uncategorizedId,
          title: AppStrings.of(context).uncategorized,
          currentId: currentCategoryId ?? LibraryCategoryBucket.uncategorizedId,
        ),
        for (final category in categories)
          _CategoryChoiceOption(
            id: category.id,
            title: category.title,
            currentId:
                currentCategoryId ?? LibraryCategoryBucket.uncategorizedId,
          ),
        const Divider(),
        TextButton(
          onPressed: () => Navigator.pop(context, _categoryDialogCancelled),
          child: Text(AppStrings.of(context).cancel),
        ),
      ],
    ),
  );
}

class _CategoryChoiceOption extends StatelessWidget {
  const _CategoryChoiceOption({
    required this.id,
    required this.title,
    required this.currentId,
  });

  final String id;
  final String title;
  final String currentId;

  @override
  Widget build(BuildContext context) {
    final selected = id == currentId;
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, id),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: selected ? XulangColors.accent : XulangColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}

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
          child: Text(AppStrings.of(context).cancel),
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

String _displayExhibitionTitle(ExhibitionSummary summary) {
  if (summary.id == 'sample-exhibition' && !summary.title.contains('官方示例')) {
    return '${summary.title}（官方示例）';
  }
  return summary.title;
}

String _mediaImportModeLabel(AppStrings l10n, MediaImportMode mode) =>
    switch (mode) {
      MediaImportMode.copyIntoApp => l10n.copiedIntoApp,
      MediaImportMode.referenceOriginal => l10n.referenceOriginal,
    };

String _mediaImportModeDescription(AppStrings l10n, MediaImportMode mode) =>
    switch (mode) {
      MediaImportMode.copyIntoApp => l10n.copiedIntoAppDescription,
      MediaImportMode.referenceOriginal => l10n.referenceOriginalDescription,
    };

String _recordingChapterModeLabel(AppStrings l10n, RecordingChapterMode mode) =>
    switch (mode) {
      RecordingChapterMode.current => l10n.currentChapter,
      RecordingChapterMode.fromCurrentToEnd => l10n.fromCurrentToEnd,
      RecordingChapterMode.all => l10n.allChapters,
    };

String _appLanguageLabel(AppStrings l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => l10n.followSystem,
      AppLanguage.chinese => l10n.simplifiedChinese,
      AppLanguage.english => l10n.english,
    };

void _showAppSettings(
  BuildContext context, {
  required AppSettings settings,
  required Future<void> Function(AppSettings settings) onSaveSettings,
  required VoidCallback onImportTemplate,
}) {
  var draft = settings;
  var l10n = AppStrings.from(draft, Localizations.maybeLocaleOf(context));
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Builder(
          builder: (context) {
            l10n = AppStrings.from(draft, Localizations.maybeLocaleOf(context));
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsAndGuide,
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
                  _SettingsSectionTitle(l10n.recordingPlayback),
                  const SizedBox(height: 8),
                  _SettingsSectionTitle(l10n.languageSetting),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final language in AppLanguage.values)
                        ChoiceChip(
                          selected: draft.language == language,
                          onSelected: (_) async {
                            draft = draft.copyWith(language: language);
                            setSheetState(() {});
                            await onSaveSettings(draft);
                          },
                          label: Text(_appLanguageLabel(l10n, language)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSectionTitle(l10n.recordingPlayback),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.showChapterTitleRecording),
                    subtitle: Text(l10n.showChapterTitleRecordingSubtitle),
                    value: draft.recordingShowChapterTitle,
                    onChanged: (value) async {
                      draft = draft.copyWith(recordingShowChapterTitle: value);
                      setSheetState(() {});
                      await onSaveSettings(draft);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsSectionTitle(l10n.mediaImportMode),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final mode in MediaImportMode.values)
                        ChoiceChip(
                          selected: draft.mediaImportMode == mode,
                          onSelected: (_) async {
                            draft = draft.copyWith(mediaImportMode: mode);
                            setSheetState(() {});
                            await onSaveSettings(draft);
                          },
                          label: Text(_mediaImportModeLabel(l10n, mode)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mediaImportModeDescription(l10n, draft.mediaImportMode),
                    style: const TextStyle(
                      color: XulangColors.muted,
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSectionTitle(l10n.recordingDefaults),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.video_camera_back_outlined),
                    title: Text(l10n.defaultRecordingChapters),
                    trailing: DropdownButton<RecordingChapterMode>(
                      value: draft.recordingChapterMode,
                      onChanged: (value) async {
                        if (value == null) return;
                        draft = draft.copyWith(recordingChapterMode: value);
                        setSheetState(() {});
                        await onSaveSettings(draft);
                      },
                      items: [
                        for (final mode in RecordingChapterMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(_recordingChapterModeLabel(l10n, mode)),
                          ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.useMusicByDefault),
                    subtitle: Text(l10n.canChangeBeforeRecording),
                    value: draft.recordingUseMusic,
                    onChanged: (value) async {
                      draft = draft.copyWith(recordingUseMusic: value);
                      setSheetState(() {});
                      await onSaveSettings(draft);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.speed_outlined),
                    title: Text(
                      l10n.speedSecondsPerChapter(draft.recordingSpeed),
                    ),
                    subtitle: Slider(
                      value: draft.recordingSpeed,
                      min: 1,
                      max: 12,
                      divisions: 22,
                      label: l10n.speedLabel(draft.recordingSpeed),
                      onChanged: (value) async {
                        draft = draft.copyWith(recordingSpeed: value);
                        setSheetState(() {});
                        await onSaveSettings(draft);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSectionTitle(l10n.howToUse),
                  const SizedBox(height: 8),
                  _UsageStep(
                    icon: Icons.category_outlined,
                    title: l10n.usageStepTitle(1),
                    body: l10n.usageStepBody(1),
                  ),
                  _UsageStep(
                    icon: Icons.add_photo_alternate_outlined,
                    title: l10n.usageStepTitle(2),
                    body: l10n.usageStepBody(2),
                  ),
                  _UsageStep(
                    icon: Icons.auto_awesome_motion_outlined,
                    title: l10n.usageStepTitle(3),
                    body: l10n.usageStepBody(3),
                  ),
                  _UsageStep(
                    icon: Icons.play_circle_outline,
                    title: l10n.usageStepTitle(4),
                    body: l10n.usageStepBody(4),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSectionTitle(l10n.commonEntrances),
                  _SettingsTile(
                    icon: Icons.file_open_outlined,
                    title: l10n.importTemplate,
                    subtitle: l10n.importTemplateSubtitle,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onImportTemplate();
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyLocalStorage,
                    subtitle: l10n.privacyLocalStorageSubtitle,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showLocalInfo(context);
                    },
                  ),
                ],
              ),
            );
          },
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

String _formatDate(BuildContext context, DateTime date) => AppStrings.of(context).monthDay(date);
