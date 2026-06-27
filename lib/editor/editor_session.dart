import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/data/image_selection_service.dart';
import 'package:xulang/data/media_import_service.dart';
import 'package:xulang/domain/editor_history.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/exhibition_exporter.dart';

class EditorSession extends ChangeNotifier {
  EditorSession({
    required this.exhibitionId,
    required this.repository,
    required this.importer,
    required this.imageSelection,
  }) {
    unawaited(load());
  }

  final String exhibitionId;
  final GalleryRepository repository;
  final MediaImportService importer;
  final ImageSelectionService imageSelection;

  GalleryBundle? bundle;
  Object? error;
  bool loading = true;
  bool importing = false;
  int selectedChapterIndex = 0;
  EditorHistory<GalleryBundle>? _history;
  bool _disposed = false;

  bool get canUndo => _history?.canUndo ?? false;
  bool get canRedo => _history?.canRedo ?? false;
  GalleryChapter? get selectedChapter {
    final document = bundle?.document;
    if (document == null || document.chapters.isEmpty) return null;
    return document.chapters[selectedChapterIndex.clamp(
      0,
      document.chapters.length - 1,
    )];
  }

  Future<void> load() async {
    try {
      bundle = await repository.load(exhibitionId);
      if (bundle == null) throw StateError('找不到展览');
      _history = EditorHistory(initialValue: bundle!, limit: 20);
    } catch (caught) {
      error = caught;
    } finally {
      loading = false;
      _notify();
    }
  }

  void selectChapter(int index) {
    final chapters = bundle?.document.chapters;
    if (chapters == null || chapters.isEmpty) return;
    selectedChapterIndex = index.clamp(0, chapters.length - 1);
    _notify();
  }

  Future<void> rename(String title) async {
    final current = bundle;
    if (current == null || title.trim().isEmpty) return;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          title: title.trim(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updateTheme(GalleryTheme theme) async {
    final current = bundle;
    if (current == null || current.document.theme == theme) return;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          theme: theme,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updateShowChapterTitleInPlayback(bool value) async {
    final current = bundle;
    if (current == null) return;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          showChapterTitleInPlayback: value,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updatePlaybackDelaySeconds(int seconds) async {
    final current = bundle;
    if (current == null) return;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          playbackDelaySeconds: seconds.clamp(0, 30),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> importBackgroundMusic(String sourcePath) async {
    final current = bundle;
    if (current == null) return;
    final source = File(sourcePath);
    if (!await source.exists()) return;
    final directory = Directory(
      p.join(repository.mediaRoot.path, exhibitionId, 'music'),
    );
    await directory.create(recursive: true);
    final extension = p.extension(sourcePath);
    final fileName = '${repository.createId()}$extension';
    final copied = await source.copy(p.join(directory.path, fileName));
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          musicPath: copied.path,
          musicTitle: p.basename(sourcePath),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> clearBackgroundMusic() async {
    final current = bundle;
    if (current == null) return;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          musicPath: null,
          musicTitle: null,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> applyTemplateJson(
    String templateJson, {
    List<String> mediaIds = const [],
    String? titleOverride,
    String? chapterTitleOverride,
  }) async {
    final current = bundle;
    if (current == null) return;
    final document = const ExhibitionTemplateCodec().applyToDocument(
      base: current.document,
      templateJson: templateJson,
      createId: repository.createId,
      now: DateTime.now(),
      mediaIds: mediaIds,
      titleOverride: titleOverride,
      chapterTitleOverride: chapterTitleOverride,
    );
    selectedChapterIndex = 0;
    await _commit(current.copyWith(document: document));
  }

  Future<void> applyTemplateJsonWithImages(
    String templateJson, {
    required List<String> sourcePaths,
    String? titleOverride,
    String? chapterTitleOverride,
  }) async {
    final current = bundle;
    if (current == null || sourcePaths.isEmpty) return;
    importing = true;
    _notify();
    try {
      final result = await importer.importFiles(
        exhibitionId: exhibitionId,
        sourcePaths: sourcePaths,
        existingAssets: current.media,
      );
      final mediaById = {for (final media in current.media) media.id: media};
      for (final media in result.assets) {
        mediaById[media.id] = media;
      }
      final document = const ExhibitionTemplateCodec().applyToDocument(
        base: current.document,
        templateJson: templateJson,
        createId: repository.createId,
        now: DateTime.now(),
        mediaIds: result.selectionMediaIds,
        titleOverride: titleOverride,
        chapterTitleOverride: chapterTitleOverride,
      );
      selectedChapterIndex = 0;
      await _commit(
        GalleryBundle(
          document: document,
          media: mediaById.values.toList(growable: false),
        ),
      );
    } catch (caught) {
      error = caught;
      _notify();
      rethrow;
    } finally {
      importing = false;
      _notify();
    }
  }

  Future<void> addChapter() async {
    final current = bundle;
    if (current == null) return;
    final chapters = List<GalleryChapter>.of(current.document.chapters);
    chapters.add(
      GalleryChapter(
        id: repository.createId(),
        title: '第${chapters.length + 1}章',
        order: chapters.length,
        layout: GalleryLayout.hero,
        motion: GalleryMotion.push,
        placements: const [],
      ),
    );
    selectedChapterIndex = chapters.length - 1;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          chapters: chapters,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> moveChapter(int oldIndex, int newIndex) async {
    final current = bundle;
    if (current == null) return;
    final chapters = List<GalleryChapter>.of(current.document.chapters);
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = chapters.removeAt(oldIndex);
    chapters.insert(newIndex, moved);
    final normalized = [
      for (var index = 0; index < chapters.length; index++)
        chapters[index].copyWith(order: index),
    ];
    selectedChapterIndex = newIndex;
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          chapters: normalized,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updateChapter({
    String? title,
    String? caption,
    GalleryLayout? layout,
    GalleryMotion? motion,
    StoryPathStyle? pathStyle,
    Object? customPathAnchors = _editorUnchanged,
    List<CustomPathConnection>? customPathConnections,
    List<GallerySticker>? stickers,
  }) async {
    final current = bundle;
    if (current == null) return;
    final chapters = List<GalleryChapter>.of(current.document.chapters);
    final chapter = chapters[selectedChapterIndex];
    chapters[selectedChapterIndex] = chapter.copyWith(
      title: title,
      caption: caption,
      layout: layout,
      motion: motion,
      pathStyle: pathStyle,
      customPathAnchors: identical(customPathAnchors, _editorUnchanged)
          ? chapter.customPathAnchors
          : customPathAnchors as List<CustomPathAnchor>?,
      customPathConnections:
          customPathConnections ?? chapter.customPathConnections,
      stickers: stickers ?? chapter.stickers,
    );
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          chapters: chapters,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updateChapterPath(List<CustomPathAnchor> anchors) async {
    await updateChapter(customPathAnchors: anchors);
  }

  Future<void> clearCustomPath() async {
    await updateChapter(customPathAnchors: null);
  }

  Future<void> addCustomPathConnection(CustomPathConnection connection) async {
    final chapter = selectedChapter;
    if (chapter == null) return;
    await updateChapter(
      customPathConnections: [...chapter.customPathConnections, connection],
    );
  }

  Future<void> updateCustomPathConnection(
    CustomPathConnection connection,
  ) async {
    final chapter = selectedChapter;
    if (chapter == null) return;
    await updateChapter(
      customPathConnections: [
        for (final item in chapter.customPathConnections)
          if (item.id == connection.id) connection else item,
      ],
    );
  }

  Future<void> removeCustomPathConnection(String connectionId) async {
    final chapter = selectedChapter;
    if (chapter == null) return;
    await updateChapter(
      customPathConnections: [
        for (final item in chapter.customPathConnections)
          if (item.id != connectionId) item,
      ],
    );
  }

  Future<void> clearCustomPathConnections() async {
    await updateChapter(customPathConnections: const []);
  }

  Future<void> addSticker(
    GalleryStickerKind kind, {
    double x = 0.5,
    double y = 0.5,
  }) async {
    final chapter = selectedChapter;
    if (chapter == null) return;
    await updateChapter(
      stickers: [
        ...chapter.stickers,
        GallerySticker(id: repository.createId(), kind: kind, x: x, y: y),
      ],
    );
  }

  Future<void> updateSticker(GallerySticker sticker) async {
    final chapter = selectedChapter;
    if (chapter == null) return;
    await updateChapter(
      stickers: [
        for (final item in chapter.stickers)
          if (item.id == sticker.id) sticker else item,
      ],
    );
  }

  Future<void> removeSticker(String stickerId) async {
    final chapter = selectedChapter;
    if (chapter == null) return;
    await updateChapter(
      stickers: [
        for (final item in chapter.stickers)
          if (item.id != stickerId) item,
      ],
    );
  }

  Future<void> updatePlacement(
    String placementId, {
    GallerySize? size,
    GalleryFrame? frame,
    double? focalX,
    double? focalY,
    double? zoom,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    String? caption,
  }) async {
    final current = bundle;
    if (current == null) return;
    final chapters = List<GalleryChapter>.of(current.document.chapters);
    final chapter = chapters[selectedChapterIndex];
    chapters[selectedChapterIndex] = chapter.copyWith(
      placements: [
        for (final placement in chapter.placements)
          if (placement.id == placementId)
            placement.copyWith(
              size: size,
              frame: frame,
              focalX: focalX?.clamp(0, 1),
              focalY: focalY?.clamp(0, 1),
              zoom: zoom?.clamp(1, 3),
              scale: scale?.clamp(.45, 1.9),
              offsetX: offsetX?.clamp(-.45, .45),
              offsetY: offsetY?.clamp(-.45, .45),
              rotation: rotation,
              caption: caption,
            )
          else
            placement,
      ],
    );
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          chapters: chapters,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> movePlacement(int oldIndex, int newIndex) async {
    final current = bundle;
    if (current == null) return;
    final chapters = List<GalleryChapter>.of(current.document.chapters);
    chapters[selectedChapterIndex] = chapters[selectedChapterIndex]
        .movePlacement(oldIndex, newIndex);
    await _commit(
      current.copyWith(
        document: current.document.copyWith(
          chapters: chapters,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> importImages() async {
    if (importing || bundle == null) return;
    final paths = await imageSelection.selectImages();
    if (paths.isEmpty) return;
    importing = true;
    _notify();
    try {
      final current = bundle!;
      final result = await importer.importFiles(
        exhibitionId: exhibitionId,
        sourcePaths: paths,
        existingAssets: current.media,
      );
      final mediaById = {for (final media in current.media) media.id: media};
      for (final media in result.assets) {
        mediaById[media.id] = media;
      }
      final chapters = List<GalleryChapter>.of(current.document.chapters);
      final chapter = chapters[selectedChapterIndex];
      final placements = List<GalleryPlacement>.of(chapter.placements);
      for (final mediaId in result.selectionMediaIds) {
        placements.add(
          GalleryPlacement(
            id: repository.createId(),
            mediaId: mediaId,
            order: placements.length,
          ),
        );
      }
      chapters[selectedChapterIndex] = chapter.copyWith(placements: placements);
      await _commit(
        GalleryBundle(
          document: current.document.copyWith(
            coverMediaId:
                current.document.coverMediaId ?? result.selectionMediaIds.first,
            chapters: chapters,
            updatedAt: DateTime.now(),
          ),
          media: mediaById.values.toList(growable: false),
        ),
      );
    } catch (caught) {
      error = caught;
      _notify();
    } finally {
      importing = false;
      _notify();
    }
  }

  Future<void> undo() async {
    final history = _history;
    if (history == null || !history.canUndo) return;
    bundle = history.undo();
    await repository.save(bundle!);
    _notify();
  }

  Future<void> redo() async {
    final history = _history;
    if (history == null || !history.canRedo) return;
    bundle = history.redo();
    await repository.save(bundle!);
    _notify();
  }

  void clearError() {
    if (error == null) return;
    error = null;
    _notify();
  }

  Future<void> _commit(GalleryBundle next) async {
    _history?.push(next);
    bundle = next;
    _notify();
    await repository.save(next);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

const Object _editorUnchanged = Object();
