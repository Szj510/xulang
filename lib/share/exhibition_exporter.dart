import 'dart:convert';

import 'package:xulang/domain/gallery_document.dart';

class ExhibitionTemplateCodec {
  const ExhibitionTemplateCodec();

  String encode(GalleryDocument document) {
    return const JsonEncoder.withIndent('  ').convert({
      'kind': 'xulang-template',
      'version': 1,
      'title': document.title,
      'theme': document.theme.name,
      'showChapterTitleInPlayback': document.showChapterTitleInPlayback,
      'chapters': [
        for (final chapter in document.chapters)
          {
            'title': chapter.title,
            'caption': chapter.caption,
            'order': chapter.order,
            'layout': chapter.layout.name,
            'motion': chapter.motion.name,
            'pathStyle': chapter.pathStyle.name,
            'placements': [
              for (final placement in chapter.placements)
                {
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

  GalleryDocument applyToDocument({
    required GalleryDocument base,
    required String templateJson,
    required String Function() createId,
    required DateTime now,
  }) {
    final decoded = jsonDecode(templateJson) as Map<String, Object?>;
    if (decoded['kind'] != 'xulang-template') {
      throw FormatException('不是叙廊模板文件');
    }
    final existingMedia = [
      for (final chapter in base.chapters)
        for (final placement in chapter.placements) placement.mediaId,
    ];
    var mediaIndex = 0;
    final chaptersJson = decoded['chapters'] as List<Object?>? ?? const [];
    final chapters = <GalleryChapter>[];
    for (
      var chapterIndex = 0;
      chapterIndex < chaptersJson.length;
      chapterIndex++
    ) {
      final chapterJson = chaptersJson[chapterIndex] as Map<String, Object?>;
      final slots = chapterJson['placements'] as List<Object?>? ?? const [];
      final placements = <GalleryPlacement>[];
      for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
        if (mediaIndex >= existingMedia.length) break;
        final slot = slots[slotIndex] as Map<String, Object?>;
        placements.add(
          GalleryPlacement(
            id: createId(),
            mediaId: existingMedia[mediaIndex++],
            order: slotIndex,
            size: _byName(GallerySize.values, slot['size'], GallerySize.medium),
            frame: _byName(
              GalleryFrame.values,
              slot['frame'],
              GalleryFrame.none,
            ),
            focalX: (slot['focalX'] as num?)?.toDouble() ?? .5,
            focalY: (slot['focalY'] as num?)?.toDouble() ?? .5,
            zoom: (slot['zoom'] as num?)?.toDouble() ?? 1,
            scale: (slot['scale'] as num?)?.toDouble() ?? 1,
            offsetX: (slot['offsetX'] as num?)?.toDouble() ?? 0,
            offsetY: (slot['offsetY'] as num?)?.toDouble() ?? 0,
            rotation: (slot['rotation'] as num?)?.toDouble() ?? 0,
            caption: slot['caption'] as String? ?? '',
          ),
        );
      }
      chapters.add(
        GalleryChapter(
          id: createId(),
          title: chapterJson['title'] as String? ?? '第${chapterIndex + 1}章',
          caption: chapterJson['caption'] as String? ?? '',
          order: chapterIndex,
          layout: _decodeLayout(chapterJson['layout']),
          motion: GalleryMotion.push,
          pathStyle: _byName(
            StoryPathStyle.values,
            chapterJson['pathStyle'],
            StoryPathStyle.solid,
          ),
          placements: placements,
        ),
      );
    }
    if (chapters.isEmpty) {
      throw FormatException('模板没有章节');
    }
    return base.copyWith(
      theme: _byName(GalleryTheme.values, decoded['theme'], base.theme),
      showChapterTitleInPlayback:
          decoded['showChapterTitleInPlayback'] as bool? ??
          base.showChapterTitleInPlayback,
      chapters: chapters,
      updatedAt: now,
    );
  }
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
