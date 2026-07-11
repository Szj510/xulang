import 'dart:convert';

import 'package:xulang/domain/gallery_document.dart';

class ExhibitionTemplateCodec {
  const ExhibitionTemplateCodec();

  static const maxTemplateBytes = 2 * 1024 * 1024;
  static const maxChapters = 100;
  static const maxPlacements = 2000;

  String encode(GalleryDocument document) {
    return const JsonEncoder.withIndent('  ').convert({
      'kind': 'xulang-template',
      'version': 2,
      'title': document.title,
      'theme': document.theme.name,
      'showChapterTitleInPlayback': document.showChapterTitleInPlayback,
      'playbackDelaySeconds': document.playbackDelaySeconds,
      'chapters': [
        for (final chapter in document.chapters)
          {
            'title': chapter.title,
            'caption': chapter.caption,
            'order': chapter.order,
            'layout': chapter.layout.name,
            'motion': chapter.motion.name,
            'pathStyle': chapter.pathStyle.name,
            'customPathAnchors': [
              for (final anchor
                  in chapter.customPathAnchors ?? const <CustomPathAnchor>[])
                anchor.toJson(),
            ],
            'customPathConnections': [
              for (final connection in chapter.customPathConnections)
                connection.toJson(),
            ],
            'stickers': [
              for (final sticker in chapter.stickers) sticker.toJson(),
            ],
            'placements': [
              for (final placement in chapter.placements)
                {
                  'id': placement.id,
                  'order': placement.order,
                  'size': placement.size.name,
                  'frame': placement.frame.name,
                  'focalX': placement.focalX,
                  'focalY': placement.focalY,
                  'zoom': placement.zoom,
                  'scale': placement.scale,
                  'offsetX': placement.offsetX,
                  'offsetY': placement.offsetY,
                  'rotation': placement.rotation,
                  'caption': placement.caption,
                },
            ],
          },
      ],
    });
  }

  TemplateSummary inspect(String templateJson) {
    final decoded = _decodeTemplate(templateJson);
    final chaptersJson = _chaptersJson(decoded);
    final title = (decoded['title'] as String?)?.trim();
    var slotCount = 0;
    final chapters = <TemplateChapterSummary>[];
    for (final chapterJson in chaptersJson) {
      final chapterSlotCount =
          (chapterJson['placements'] as List<Object?>? ?? const []).length;
      slotCount += chapterSlotCount;
      final chapterTitle = (chapterJson['title'] as String?)?.trim();
      chapters.add(
        TemplateChapterSummary(
          title: chapterTitle == null || chapterTitle.isEmpty
              ? 'Chapter ${chapters.length + 1}'
              : chapterTitle,
          slotCount: chapterSlotCount,
        ),
      );
    }
    final firstChapterTitle = chaptersJson.isEmpty
        ? null
        : (chaptersJson.first['title'] as String?)?.trim();
    return TemplateSummary(
      title: title == null || title.isEmpty ? 'Imported template' : title,
      firstChapterTitle: firstChapterTitle == null || firstChapterTitle.isEmpty
          ? 'Chapter 1'
          : firstChapterTitle,
      chapterCount: chaptersJson.length,
      placementCount: slotCount,
      chapters: chapters,
    );
  }

  GalleryDocument applyToDocument({
    required GalleryDocument base,
    required String templateJson,
    required String Function() createId,
    required DateTime now,
    List<String> mediaIds = const [],
    String? titleOverride,
    String? chapterTitleOverride,
  }) {
    final decoded = _decodeTemplate(templateJson);
    final existingMedia = mediaIds.isEmpty
        ? [
            for (final chapter in base.chapters)
              for (final placement in chapter.placements) placement.mediaId,
          ]
        : mediaIds;
    final chaptersJson = _chaptersJson(decoded);
    final chapters = <GalleryChapter>[];
    var mediaIndex = 0;

    for (
      var chapterIndex = 0;
      chapterIndex < chaptersJson.length;
      chapterIndex++
    ) {
      final chapterJson = chaptersJson[chapterIndex];
      final slots = chapterJson['placements'] as List<Object?>? ?? const [];
      final effectiveSlots =
          slots.isEmpty &&
              chapterIndex == 0 &&
              mediaIndex < existingMedia.length
          ? [
              for (
                var index = mediaIndex;
                index < existingMedia.length;
                index++
              )
                <String, Object?>{'order': index - mediaIndex},
            ]
          : slots;
      final chapterMediaIds = <String>[];
      for (var index = 0; index < effectiveSlots.length; index++) {
        if (mediaIndex >= existingMedia.length) break;
        chapterMediaIds.add(existingMedia[mediaIndex++]);
      }
      chapters.add(
        _buildChapter(
          chapterJson: chapterJson,
          chapterIndex: chapterIndex,
          chapterCount: chaptersJson.length,
          chapterMediaIds: chapterMediaIds,
          createId: createId,
          chapterTitleOverride: chapterTitleOverride,
          appendExtraMedia: false,
          forceDefaultSlots: effectiveSlots,
        ),
      );
    }

    return _documentFromTemplate(
      base: base,
      decoded: decoded,
      titleOverride: titleOverride,
      mediaIds: mediaIds,
      chapters: chapters,
      now: now,
    );
  }

  GalleryDocument applyToDocumentByChapterMedia({
    required GalleryDocument base,
    required String templateJson,
    required String Function() createId,
    required DateTime now,
    required List<List<String>> mediaIdsByChapter,
    String? titleOverride,
    String? chapterTitleOverride,
    bool appendExtraMedia = false,
  }) {
    final decoded = _decodeTemplate(templateJson);
    final chaptersJson = _chaptersJson(decoded);
    final chapters = <GalleryChapter>[];
    for (
      var chapterIndex = 0;
      chapterIndex < chaptersJson.length;
      chapterIndex++
    ) {
      chapters.add(
        _buildChapter(
          chapterJson: chaptersJson[chapterIndex],
          chapterIndex: chapterIndex,
          chapterCount: chaptersJson.length,
          chapterMediaIds: chapterIndex < mediaIdsByChapter.length
              ? mediaIdsByChapter[chapterIndex]
              : const <String>[],
          createId: createId,
          chapterTitleOverride: chapterTitleOverride,
          appendExtraMedia: appendExtraMedia,
        ),
      );
    }
    return _documentFromTemplate(
      base: base,
      decoded: decoded,
      titleOverride: titleOverride,
      mediaIds: [
        for (final chapterMediaIds in mediaIdsByChapter)
          for (final mediaId in chapterMediaIds) mediaId,
      ],
      chapters: chapters,
      now: now,
    );
  }
}

class TemplateSummary {
  const TemplateSummary({
    required this.title,
    required this.firstChapterTitle,
    required this.chapterCount,
    required this.placementCount,
    required this.chapters,
  });

  final String title;
  final String firstChapterTitle;
  final int chapterCount;
  final int placementCount;
  final List<TemplateChapterSummary> chapters;
}

class TemplateChapterSummary {
  const TemplateChapterSummary({required this.title, required this.slotCount});

  final String title;
  final int slotCount;
}

GalleryDocument _documentFromTemplate({
  required GalleryDocument base,
  required Map<String, Object?> decoded,
  required String? titleOverride,
  required List<String> mediaIds,
  required List<GalleryChapter> chapters,
  required DateTime now,
}) {
  if (chapters.isEmpty) {
    throw const FormatException('Template has no chapters');
  }
  final title = titleOverride?.trim();
  return base.copyWith(
    title: title == null || title.isEmpty
        ? (decoded['title'] as String? ?? base.title)
        : title,
    coverMediaId: mediaIds.isEmpty ? base.coverMediaId : mediaIds.first,
    theme: _byName(GalleryTheme.values, decoded['theme'], base.theme),
    showChapterTitleInPlayback:
        decoded['showChapterTitleInPlayback'] as bool? ??
        base.showChapterTitleInPlayback,
    playbackDelaySeconds:
        ((decoded['playbackDelaySeconds'] as num?)?.round() ??
                base.playbackDelaySeconds)
            .clamp(0, 30),
    chapters: chapters,
    updatedAt: now,
  );
}

GalleryChapter _buildChapter({
  required Map<String, Object?> chapterJson,
  required int chapterIndex,
  required int chapterCount,
  required List<String> chapterMediaIds,
  required String Function() createId,
  required String? chapterTitleOverride,
  required bool appendExtraMedia,
  List<Object?>? forceDefaultSlots,
}) {
  final slots =
      forceDefaultSlots ??
      (chapterJson['placements'] as List<Object?>? ?? const []);
  var mediaIndex = 0;
  final placementIds = <String>[];
  final templatePlacementIds = <String, String>{};
  final placements = <GalleryPlacement>[];
  for (
    var slotIndex = 0;
    slotIndex < slots.length &&
        placements.length < maxGalleryPlacementsPerChapter;
    slotIndex++
  ) {
    if (mediaIndex >= chapterMediaIds.length) break;
    final slot = slots[slotIndex] as Map<String, Object?>;
    final placementId = createId();
    placementIds.add(placementId);
    templatePlacementIds[slot['id'] as String? ?? '$slotIndex'] = placementId;
    placements.add(
      _placementFromSlot(
        id: placementId,
        mediaId: chapterMediaIds[mediaIndex++],
        order: placements.length,
        slot: slot,
      ),
    );
  }
  if (appendExtraMedia) {
    while (mediaIndex < chapterMediaIds.length &&
        placements.length < maxGalleryPlacementsPerChapter) {
      placements.add(
        GalleryPlacement(
          id: createId(),
          mediaId: chapterMediaIds[mediaIndex++],
          order: placements.length,
        ),
      );
    }
  }
  return GalleryChapter(
    id: createId(),
    title: _resolveChapterTitle(
      chapterJson: chapterJson,
      chapterIndex: chapterIndex,
      chapterCount: chapterCount,
      override: chapterTitleOverride,
    ),
    caption: chapterJson['caption'] as String? ?? '',
    order: chapterIndex,
    layout: _decodeLayout(chapterJson['layout']),
    motion: _byName(
      GalleryMotion.values,
      chapterJson['motion'],
      GalleryMotion.push,
    ),
    pathStyle: _byName(
      StoryPathStyle.values,
      chapterJson['pathStyle'],
      StoryPathStyle.solid,
    ),
    placements: placements,
    customPathAnchors: _decodeCustomPathAnchors(
      chapterJson['customPathAnchors'],
    ),
    customPathConnections: _decodeCustomPathConnections(
      chapterJson['customPathConnections'],
      templatePlacementIds,
      placementIds,
    ),
    stickers: _decodeStickers(chapterJson['stickers']),
  );
}

GalleryPlacement _placementFromSlot({
  required String id,
  required String mediaId,
  required int order,
  required Map<String, Object?> slot,
}) {
  return GalleryPlacement(
    id: id,
    mediaId: mediaId,
    order: order,
    size: _byName(GallerySize.values, slot['size'], GallerySize.medium),
    frame: _byName(GalleryFrame.values, slot['frame'], GalleryFrame.none),
    focalX: (slot['focalX'] as num?)?.toDouble() ?? .5,
    focalY: (slot['focalY'] as num?)?.toDouble() ?? .5,
    zoom: (slot['zoom'] as num?)?.toDouble() ?? 1,
    scale: (slot['scale'] as num?)?.toDouble() ?? 1,
    offsetX: (slot['offsetX'] as num?)?.toDouble() ?? 0,
    offsetY: (slot['offsetY'] as num?)?.toDouble() ?? 0,
    rotation: (slot['rotation'] as num?)?.toDouble() ?? 0,
    caption: slot['caption'] as String? ?? '',
  );
}

Map<String, Object?> _decodeTemplate(String templateJson) {
  if (utf8.encode(templateJson).length >
      ExhibitionTemplateCodec.maxTemplateBytes) {
    throw const FormatException('Template file is too large');
  }
  final raw = jsonDecode(templateJson);
  if (raw is! Map) {
    throw const FormatException('Template root must be an object');
  }
  final decoded = Map<String, Object?>.from(raw);
  if (decoded['kind'] != 'xulang-template') {
    throw const FormatException('Not a Xulang template file');
  }
  return decoded;
}

List<Map<String, Object?>> _chaptersJson(Map<String, Object?> decoded) {
  final rawChapters = decoded['chapters'] as List<Object?>? ?? const [];
  if (rawChapters.length > ExhibitionTemplateCodec.maxChapters) {
    throw const FormatException('Template has too many chapters');
  }
  final chapters = [
    for (final item in decoded['chapters'] as List<Object?>? ?? const [])
      if (item is Map) Map<String, Object?>.from(item),
  ];
  final placementCount = chapters.fold<int>(
    0,
    (count, chapter) =>
        count + (chapter['placements'] as List<Object?>? ?? const []).length,
  );
  if (placementCount > ExhibitionTemplateCodec.maxPlacements) {
    throw const FormatException('Template has too many image placements');
  }
  return chapters;
}

String _resolveChapterTitle({
  required Map<String, Object?> chapterJson,
  required int chapterIndex,
  required int chapterCount,
  required String? override,
}) {
  final trimmed = override?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return chapterCount == 1 ? trimmed : '$trimmed ${chapterIndex + 1}';
  }
  return chapterJson['title'] as String? ?? 'Chapter ${chapterIndex + 1}';
}

List<CustomPathAnchor>? _decodeCustomPathAnchors(Object? data) {
  final anchors = [
    for (final item in data as List<Object?>? ?? const [])
      if (item is Map)
        CustomPathAnchor.fromJson(Map<String, dynamic>.from(item)),
  ];
  return anchors.isEmpty ? null : anchors;
}

List<CustomPathConnection> _decodeCustomPathConnections(
  Object? data,
  Map<String, String> templatePlacementIds,
  List<String> placementIds,
) {
  final connections = <CustomPathConnection>[];
  for (final item in data as List<Object?>? ?? const []) {
    if (item is! Map) continue;
    final json = Map<String, dynamic>.from(item);
    final from = _remapPlacementId(
      json['fromPlacementId'] as String?,
      templatePlacementIds,
      placementIds,
    );
    final to = _remapPlacementId(
      json['toPlacementId'] as String?,
      templatePlacementIds,
      placementIds,
    );
    if (from == null || to == null) continue;
    connections.add(
      CustomPathConnection.fromJson({
        ...json,
        'fromPlacementId': from,
        'toPlacementId': to,
      }),
    );
  }
  return connections;
}

String? _remapPlacementId(
  String? templateId,
  Map<String, String> templatePlacementIds,
  List<String> placementIds,
) {
  if (templateId == null || placementIds.isEmpty) return null;
  final direct = templatePlacementIds[templateId];
  if (direct != null) return direct;
  final maybeIndex = int.tryParse(templateId);
  if (maybeIndex != null &&
      maybeIndex >= 0 &&
      maybeIndex < placementIds.length) {
    return placementIds[maybeIndex];
  }
  final trailingDigits = _trailingDigits(templateId);
  if (trailingDigits != null) {
    final oneBased = int.tryParse(trailingDigits);
    if (oneBased != null && oneBased > 0 && oneBased <= placementIds.length) {
      return placementIds[oneBased - 1];
    }
  }
  return placementIds.length == 1 ? placementIds.first : null;
}

String? _trailingDigits(String value) {
  var start = value.length;
  while (start > 0) {
    final code = value.codeUnitAt(start - 1);
    if (code < 48 || code > 57) break;
    start -= 1;
  }
  if (start == value.length) return null;
  return value.substring(start);
}

List<GallerySticker> _decodeStickers(Object? data) {
  return [
    for (final item in data as List<Object?>? ?? const [])
      if (item is Map) GallerySticker.fromJson(Map<String, dynamic>.from(item)),
  ];
}

GalleryLayout _decodeLayout(Object? name) {
  if (name == 'depthWall') return GalleryLayout.collage;
  return _byName(GalleryLayout.values, name, GalleryLayout.hero);
}

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
