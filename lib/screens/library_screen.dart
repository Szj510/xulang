import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/data/document_access_service.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/editor_screen.dart';
import 'package:xulang/screens/music_library_screen.dart';
import 'package:xulang/screens/recording_library_screen.dart';
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
    return PopScope(
      canPop: _selectedCategoryId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _selectedCategoryId == null) return;
        setState(() {
          _selectedCategoryId = null;
          _searchQuery = '';
        });
      },
      child: Scaffold(
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
                    onImportTemplate: () => _importTemplateV2(context),
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
                      onImportTemplate: () => _importTemplateV2(context),
                      onManageRecordings: () => _openRecordingLibrary(context),
                      onManageMusic: () => _openMusicLibrary(context),
                      onCleanupUnusedMedia: () => _cleanupUnusedMedia(context),
                    ),
                    onManageRecordings: () => _openRecordingLibrary(context),
                    onManageMusic: () => _openMusicLibrary(context),
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
                              onRenameCategory: (category) =>
                                  _renameCategory(context, category),
                              onDeleteCategory: (category) =>
                                  _deleteCategory(context, category),
                              onCreate: () => _createExhibition(context),
                              onCreateCategory: () => _createCategory(context),
                              onImportTemplate: () =>
                                  _importTemplateV2(context),
                            )
                          : _CategoryDetail(
                              title:
                                  selectedCategory?.title ??
                                  AppStrings.of(context).uncategorized,
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
      ),
    );
  }

  Future<void> _openRecordingLibrary(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RecordingLibraryScreen()),
    );
  }

  Future<void> _openMusicLibrary(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MusicLibraryScreen()));
  }

  Future<void> _cleanupUnusedMedia(BuildContext context) async {
    final l10n = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cleanupUnusedMedia),
        content: Text(l10n.cleanupUnusedMediaConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(galleryRepositoryProvider)
        .cleanupUnusedAppPrivateMedia();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.cleanupUnusedMediaResult(
            result.deletedFileCount,
            _formatBytes(result.deletedBytes),
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

  Future<void> _renameCategory(
    BuildContext context,
    GalleryCategoryInfo category,
  ) async {
    final title = await _textDialog(
      context,
      title: AppStrings.of(context).renameCategory,
      hint: AppStrings.of(context).newCategory,
      initialValue: category.title,
      confirmText: AppStrings.of(context).save,
    );
    if (title == null || title.trim().isEmpty) return;
    await ref
        .read(galleryRepositoryProvider)
        .renameCategory(
          category: category,
          title: title.trim(),
          now: DateTime.now(),
        );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    GalleryCategoryInfo category,
  ) async {
    final l10n = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle),
        content: Text(l10n.deleteCategoryBody(category.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: XulangColors.danger,
              foregroundColor: XulangColors.paper,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(galleryRepositoryProvider).deleteCategory(category.id);
    if (_selectedCategoryId == category.id && mounted) {
      setState(() => _selectedCategoryId = null);
    }
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

  // ignore: unused_element
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

  Future<void> _importTemplateV2(BuildContext context) async {
    try {
      final picked = await _pickTemplateFile(context);
      if (picked == null || !context.mounted) return;
      final codec = const ExhibitionTemplateCodec();
      final access = ref.read(documentAccessServiceProvider);
      final templateJson = await access.readTemplateText(picked);
      final summary = codec.inspect(templateJson);
      if (!context.mounted) return;
      final l10n = AppStrings.of(context);
      final exhibitionTitle = await _textDialog(
        context,
        title: l10n.newExhibitionTitle,
        hint: l10n.exhibitionName,
        initialValue: summary.title,
        confirmText: l10n.chooseImagesByChapter,
      );
      if (exhibitionTitle == null || exhibitionTitle.trim().isEmpty) return;
      if (!context.mounted) return;
      final categories = ref
          .read(exhibitionCategoriesProvider)
          .maybeWhen(
            data: (value) => value,
            orElse: () => const <GalleryCategoryInfo>[],
          );
      final pickedCategoryId = await _pickCategoryForExhibition(
        context,
        categories,
        _selectedCategoryId,
      );
      if (pickedCategoryId == null ||
          pickedCategoryId == _categoryDialogCancelled ||
          !context.mounted) {
        return;
      }
      final targetCategoryId =
          pickedCategoryId == LibraryCategoryBucket.uncategorizedId
          ? null
          : pickedCategoryId;

      final sourcePathsByChapter = <List<String>>[];
      var missingSlots = 0;
      var extraImages = 0;
      for (var index = 0; index < summary.chapters.length; index++) {
        final chapter = summary.chapters[index];
        if (!mounted || !context.mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '${index + 1}/${summary.chapters.length} ${chapter.title}',
            ),
            content: Text(
              AppStrings.of(
                context,
              ).chapterNeedsImages(chapter.title, chapter.slotCount),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.of(context).choose),
              ),
            ],
          ),
        );
        if (proceed != true || !context.mounted) return;
        final paths = await ref
            .read(imageSelectionServiceProvider)
            .selectImages();
        if (!context.mounted) return;
        final shouldContinue = await _confirmTemplateImageCount(
          context,
          chapter: chapter,
          selectedCount: paths.length,
        );
        if (shouldContinue != true || !context.mounted) return;
        if (paths.length < chapter.slotCount) {
          missingSlots += chapter.slotCount - paths.length;
        } else if (paths.length > chapter.slotCount) {
          extraImages += paths.length - chapter.slotCount;
        }
        sourcePathsByChapter.add(paths);
      }

      final allSourcePaths = [
        for (final chapterPaths in sourcePathsByChapter)
          for (final path in chapterPaths) path,
      ];
      if (allSourcePaths.isEmpty || !context.mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.of(context).noImagesSelected)),
          );
        }
        return;
      }

      final repository = ref.read(galleryRepositoryProvider);
      final importer = ref.read(mediaImportServiceProvider);
      final id = repository.createId();
      final now = DateTime.now();
      final settings = ref
          .read(appSettingsProvider)
          .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
      final importResult = await importer.importFiles(
        exhibitionId: id,
        sourcePaths: allSourcePaths,
        existingAssets: const [],
        importMode: settings.mediaImportMode,
      );
      if (importResult.selectionMediaIds.isEmpty) return;

      var cursor = 0;
      final mediaIdsByChapter = <List<String>>[];
      for (final chapterPaths in sourcePathsByChapter) {
        final count = chapterPaths.length;
        mediaIdsByChapter.add(
          importResult.selectionMediaIds.sublist(cursor, cursor + count),
        );
        cursor += count;
      }

      final base = GalleryDocument.create(
        id: id,
        title: exhibitionTitle.trim(),
        createdAt: now,
      ).copyWith(categoryId: targetCategoryId);
      final document = codec.applyToDocumentByChapterMedia(
        base: base,
        templateJson: templateJson,
        createId: repository.createId,
        now: now,
        mediaIdsByChapter: mediaIdsByChapter,
        titleOverride: exhibitionTitle,
        appendExtraMedia: true,
      );
      await repository.save(
        GalleryBundle(document: document, media: importResult.assets),
      );
      if (context.mounted && (missingSlots > 0 || extraImages > 0)) {
        final messages = <String>[
          if (missingSlots > 0)
            AppStrings.of(context).missingImagesHint(missingSlots),
          if (extraImages > 0)
            AppStrings.of(context).extraImagesHint(extraImages),
        ];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(messages.join('\n'))));
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => EditorScreen(exhibitionId: id)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.of(context).importTemplate}: $error'),
        ),
      );
    }
  }

  Future<bool?> _confirmTemplateImageCount(
    BuildContext context, {
    required TemplateChapterSummary chapter,
    required int selectedCount,
  }) {
    final slotCount = chapter.slotCount;
    if (selectedCount == slotCount) return Future.value(true);
    final l10n = AppStrings.of(context);
    final message = selectedCount > slotCount
        ? l10n.extraImagesHint(selectedCount - slotCount)
        : l10n.missingImagesHint(slotCount - selectedCount);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chapterImageCountMismatch),
        content: Text(
          '${l10n.chapterNeedsImages(chapter.title, slotCount)}\n\n'
          '${l10n.selectedImagesCount(selectedCount)}\n\n'
          '$message',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.continueImport),
          ),
        ],
      ),
    );
  }

  Future<TemplateFileCandidate?> _pickTemplateFile(BuildContext context) async {
    final settings = ref
        .read(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
    return showModalBottomSheet<TemplateFileCandidate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TemplateFilePickerSheet(initialSettings: settings),
    );
  }

  // Kept as a fallback reference for the original direct-scan picker flow.
  // ignore: unused_element
  Future<TemplateFileCandidate?> _pickTemplateFileLegacy(
    BuildContext context,
  ) async {
    final settings = ref
        .read(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
    final access = ref.read(documentAccessServiceProvider);
    final candidates = await access.scanTemplates(
      authorizedDirectories: settings.authorizedFolderPaths,
    );
    if (!context.mounted) return null;
    return showModalBottomSheet<TemplateFileCandidate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppStrings.of(sheetContext).templateLibrary),
                subtitle: Text(
                  AppStrings.of(sheetContext).importTemplateSubtitle,
                ),
                trailing: TextButton.icon(
                  onPressed: () async {
                    final path = await access.requestDirectory();
                    if (path == null || path.trim().isEmpty) return;
                    final next = settings.copyWith(
                      authorizedFolderPaths: [
                        ...settings.authorizedFolderPaths,
                        if (!settings.authorizedFolderPaths.contains(path))
                          path,
                      ],
                    );
                    await ref
                        .read(galleryRepositoryProvider)
                        .saveAppSettings(next);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(AppStrings.of(sheetContext).authorizeFolder),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: candidates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            AppStrings.of(sheetContext).importTemplateSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: XulangColors.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: candidates.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final candidate = candidates[index];
                          return ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(candidate.summary.title),
                            subtitle: Text(
                              '${candidate.summary.chapterCount} chapters · '
                              '${candidate.summary.placementCount} images\n'
                              '${candidate.path}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.pop(context, candidate),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateFilePickerSheet extends ConsumerStatefulWidget {
  const _TemplateFilePickerSheet({required this.initialSettings});

  final AppSettings initialSettings;

  @override
  ConsumerState<_TemplateFilePickerSheet> createState() =>
      _TemplateFilePickerSheetState();
}

class _TemplateFilePickerSheetState
    extends ConsumerState<_TemplateFilePickerSheet> {
  late List<String> _authorizedDirectories;
  List<TemplateFileCandidate>? _candidates;
  bool _loadingCache = true;
  bool _refreshing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _authorizedDirectories = [...widget.initialSettings.authorizedFolderPaths];
    _loadCachedThenRefresh();
  }

  Future<void> _loadCachedThenRefresh() async {
    final access = ref.read(documentAccessServiceProvider);
    setState(() {
      _loadingCache = true;
      _error = null;
    });
    final cached = await access.readCachedTemplates();
    if (!mounted) return;
    setState(() {
      _candidates = cached;
      _loadingCache = false;
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final candidates = await ref
          .read(documentAccessServiceProvider)
          .scanTemplates(authorizedDirectories: _authorizedDirectories);
      if (!mounted) return;
      setState(() => _candidates = candidates);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      if ((_candidates ?? const <TemplateFileCandidate>[]).isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.of(context).templateLibrary}: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _authorizeFolder() async {
    final access = ref.read(documentAccessServiceProvider);
    final path = await access.requestDirectory();
    if (path == null || path.trim().isEmpty) return;
    final normalized = path.trim();
    if (!_authorizedDirectories.contains(normalized)) {
      _authorizedDirectories = [..._authorizedDirectories, normalized];
    }
    final settings = ref
        .read(appSettingsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => widget.initialSettings,
        );
    final next = settings.copyWith(
      authorizedFolderPaths: [
        ...settings.authorizedFolderPaths,
        if (!settings.authorizedFolderPaths.contains(normalized)) normalized,
      ],
    );
    await ref.read(galleryRepositoryProvider).saveAppSettings(next);
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    final candidates = _candidates ?? const <TemplateFileCandidate>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.templateLibrary),
              subtitle: Text(
                _refreshing
                    ? l10n.refreshingLocalFiles
                    : l10n.importTemplateSubtitle,
              ),
              trailing: TextButton.icon(
                onPressed: _authorizeFolder,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(l10n.authorizeFolder),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(l10n, candidates)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings l10n, List<TemplateFileCandidate> candidates) {
    if (_loadingCache && candidates.isEmpty) {
      return _InlineLoadingMessage(message: l10n.scanningTemplates);
    }
    if (_error != null && candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${l10n.templateLibrary}\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: XulangColors.muted),
          ),
        ),
      );
    }
    if (candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _refreshing ? l10n.scanningTemplates : l10n.importTemplateSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: XulangColors.muted),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: candidates.length + (_refreshing ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (_refreshing && index == 0) {
          return ListTile(
            leading: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(l10n.refreshingLocalFiles),
          );
        }
        final candidate = candidates[_refreshing ? index - 1 : index];
        return ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(candidate.summary.title),
          subtitle: Text(
            '${candidate.summary.chapterCount} chapters · '
            '${candidate.summary.placementCount} images · '
            '${_formatBytes(candidate.bytes)}\n'
            '${candidate.path}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.pop(context, candidate),
        );
      },
    );
  }
}

class _InlineLoadingMessage extends StatelessWidget {
  const _InlineLoadingMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: XulangColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.onCreate,
    required this.onCreateCategory,
    required this.onImportTemplate,
    required this.onInfo,
    required this.onSettings,
    required this.onManageRecordings,
    required this.onManageMusic,
  });

  final VoidCallback onCreate;
  final VoidCallback onCreateCategory;
  final VoidCallback onImportTemplate;
  final VoidCallback onInfo;
  final VoidCallback onSettings;
  final VoidCallback onManageRecordings;
  final VoidCallback onManageMusic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.appTitle,
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
            fontSize: 34,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.localGallery,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: XulangColors.muted,
            fontSize: 12,
            letterSpacing: 0.8,
            height: 1.4,
          ),
        ),
      ],
    );

    final actionButtons = <Widget>[
      _HeaderIconButton(
        tooltip: l10n.localStorageInfo,
        onPressed: onInfo,
        icon: const Icon(Icons.info_outline, size: 20),
      ),
      _HeaderIconButton(
        tooltip: l10n.settingsAndGuide,
        onPressed: onSettings,
        icon: const Icon(Icons.settings_outlined, size: 20),
      ),
      _HeaderIconButton(
        tooltip: l10n.manageVideos,
        onPressed: onManageRecordings,
        icon: const Icon(Icons.video_library_outlined, size: 20),
      ),
      _HeaderIconButton(
        tooltip: l10n.manageMusic,
        onPressed: onManageMusic,
        icon: const Icon(Icons.music_note_outlined, size: 20),
      ),
      _HeaderIconButton(
        tooltip: l10n.importTemplate,
        onPressed: onImportTemplate,
        icon: const Icon(Icons.file_open_outlined, size: 20),
      ),
      _HeaderIconButton(
        tooltip: l10n.newCategory,
        onPressed: onCreateCategory,
        icon: const Icon(Icons.create_new_folder_outlined, size: 20),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.newExhibition),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 8, children: actionButtons),
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
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.onCreate,
    required this.onCreateCategory,
    required this.onImportTemplate,
  });

  final List<LibraryCategoryBucket> categories;
  final ValueChanged<String> onOpenCategory;
  final ValueChanged<GalleryCategoryInfo> onRenameCategory;
  final ValueChanged<GalleryCategoryInfo> onDeleteCategory;
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
              onRename: onRenameCategory,
              onDelete: onDeleteCategory,
            );
          },
        );
      },
    );
  }
}

class _CategoryBoxCard extends StatelessWidget {
  const _CategoryBoxCard({
    required this.bucket,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final LibraryCategoryBucket bucket;
  final VoidCallback onTap;
  final ValueChanged<GalleryCategoryInfo> onRename;
  final ValueChanged<GalleryCategoryInfo> onDelete;

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
            if (!bucket.isUncategorized && bucket.category != null)
              Positioned(
                right: 8,
                top: 8,
                child: PopupMenuButton<_CategoryAction>(
                  tooltip: AppStrings.of(context).moreActions,
                  icon: const Icon(
                    Icons.more_horiz,
                    color: XulangColors.paper,
                    size: 20,
                  ),
                  onSelected: (action) {
                    final category = bucket.category!;
                    switch (action) {
                      case _CategoryAction.rename:
                        onRename(category);
                      case _CategoryAction.delete:
                        onDelete(category);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _CategoryAction.rename,
                      child: Text(AppStrings.of(context).rename),
                    ),
                    PopupMenuItem(
                      value: _CategoryAction.delete,
                      child: Text(AppStrings.of(context).delete),
                    ),
                  ],
                ),
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
                          AppStrings.of(
                            context,
                          ).exhibitionCount(bucket.exhibitions.length),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.create_new_folder_outlined, size: 30),
          const SizedBox(height: 10),
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
                decoration: InputDecoration(
                  hintText: AppStrings.of(context).searchExhibitions,
                  prefixIcon: const Icon(Icons.search),
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
              items: [
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
              ? Center(
                  child: Text(
                    AppStrings.of(context).emptyCategory,
                    style: const TextStyle(color: XulangColors.muted),
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
          meta:
              '${AppStrings.of(context).photoCount(imageCount)} · ${_formatDate(context, summary.updatedAt)}',
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
                Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: XulangColors.danger,
                ),
                SizedBox(width: 12),
                Text(
                  l10n.delete,
                  style: const TextStyle(color: XulangColors.danger),
                ),
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
            Text(
              AppStrings.of(context).cannotReadExhibitions,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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

enum _CategoryAction { rename, delete }

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

String _recordingQualityLabel(AppStrings l10n, RecordingQuality quality) =>
    switch (quality) {
      RecordingQuality.standard => l10n.standardQuality,
      RecordingQuality.high => l10n.highQuality,
      RecordingQuality.ultra => l10n.ultraQuality,
    };

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(1)} GB';
}

void _showAppSettings(
  BuildContext context, {
  required AppSettings settings,
  required Future<void> Function(AppSettings settings) onSaveSettings,
  required VoidCallback onImportTemplate,
  required VoidCallback onManageRecordings,
  required VoidCallback onManageMusic,
  required VoidCallback onCleanupUnusedMedia,
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
                    leading: const Icon(Icons.high_quality_outlined),
                    title: Text(l10n.recordingQuality),
                    subtitle: Text(l10n.recordingQualityHint),
                    trailing: DropdownButton<RecordingQuality>(
                      value: draft.recordingQuality,
                      onChanged: (value) async {
                        if (value == null) return;
                        draft = draft.copyWith(recordingQuality: value);
                        setSheetState(() {});
                        await onSaveSettings(draft);
                      },
                      items: [
                        for (final quality in RecordingQuality.values)
                          DropdownMenuItem(
                            value: quality,
                            child: Text(_recordingQualityLabel(l10n, quality)),
                          ),
                      ],
                    ),
                  ),
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
                      min: 0.1,
                      max: 12,
                      divisions: 119,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      '${l10n.buttonTooltipHint}\n${l10n.doubleTapPlaybackHint}',
                      style: const TextStyle(
                        color: XulangColors.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSectionTitle(l10n.commonEntrances),
                  _SettingsTile(
                    icon: Icons.video_library_outlined,
                    title: l10n.manageVideos,
                    subtitle: l10n.deleteVideoBody,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onManageRecordings();
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.music_note_outlined,
                    title: l10n.manageMusic,
                    subtitle: l10n.localPath,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onManageMusic();
                    },
                  ),
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
                  _SettingsTile(
                    icon: Icons.cleaning_services_outlined,
                    title: l10n.cleanupUnusedMedia,
                    subtitle: l10n.cleanupUnusedMediaSubtitle,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onCleanupUnusedMedia();
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

String _formatDate(BuildContext context, DateTime date) =>
    AppStrings.of(context).monthDay(date);
