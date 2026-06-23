import 'dart:convert';
import 'dart:io';

import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';

class ExhibitionHtmlExporter {
  const ExhibitionHtmlExporter();

  Future<String> buildHtml(GalleryBundle bundle) async {
    final mediaById = {for (final media in bundle.media) media.id: media};
    final imageData = <String, String>{};
    for (final media in bundle.media) {
      imageData[media.id] = await _dataUri(media.originalPath);
    }
    final document = bundle.document;
    final buffer = StringBuffer()
      ..writeln('<!doctype html>')
      ..writeln('<html lang="zh-CN">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln(
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
      )
      ..writeln('<title>${htmlEscape.convert(document.title)}</title>')
      ..writeln('<style>${_css()}</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<main class="exhibition">')
      ..writeln('<h1>${htmlEscape.convert(document.title)}</h1>');
    for (final chapter in document.chapters) {
      buffer
        ..writeln('<section class="chapter ${chapter.layout.name}">')
        ..writeln('<p class="chapter-kicker">第 ${chapter.order + 1} 幕</p>')
        ..writeln('<h2>${htmlEscape.convert(chapter.title)}</h2>');
      if (chapter.caption.isNotEmpty) {
        buffer.writeln(
          '<p class="caption">${htmlEscape.convert(chapter.caption)}</p>',
        );
      }
      buffer.writeln('<div class="photos">');
      for (final placement in chapter.placements) {
        final media = mediaById[placement.mediaId];
        final source = imageData[placement.mediaId] ?? '';
        buffer
          ..writeln('<figure class="photo ${placement.frame.name}">')
          ..writeln(
            '<img src="$source" alt="${htmlEscape.convert(placement.caption.isEmpty ? media?.contentHash ?? 'photo' : placement.caption)}">',
          );
        if (placement.caption.isNotEmpty) {
          buffer.writeln(
            '<figcaption>${htmlEscape.convert(placement.caption)}</figcaption>',
          );
        }
        buffer.writeln('</figure>');
      }
      buffer
        ..writeln('</div>')
        ..writeln('</section>');
    }
    final data = jsonEncode(_documentToJson(document, includeMediaIds: false));
    buffer
      ..writeln('<script type="application/json" id="xulang-data">')
      ..writeln(htmlEscape.convert(data))
      ..writeln('</script>')
      ..writeln('</main>')
      ..writeln('</body>')
      ..writeln('</html>');
    return buffer.toString();
  }

  Future<String> _dataUri(String path) async {
    if (path.startsWith('asset://')) return '';
    final file = File(path);
    if (!await file.exists()) return '';
    final ext = path.toLowerCase().split('.').last;
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
    return 'data:$mime;base64,${base64Encode(await file.readAsBytes())}';
  }

  String _css() => '''
:root{color-scheme:dark;background:#171a19;color:#eee0cd;font-family:system-ui,-apple-system,BlinkMacSystemFont,"Noto Sans SC",sans-serif}
body{margin:0;background:radial-gradient(circle at top,#252725,#111312);padding:32px}
.exhibition{max-width:980px;margin:0 auto}
h1,h2{font-family:serif;font-weight:500;letter-spacing:.12em;text-align:center}
h1{font-size:36px;margin:18px 0 40px}
.chapter{margin:0 0 72px}
.chapter-kicker,.caption{color:#aaa096;text-align:center}
.photos{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:28px;align-items:center}
.photo{margin:0;background:#eee0cd;color:#3a342c;padding:10px;box-shadow:0 18px 48px #0009;transform:rotate(var(--r,0deg))}
.photo:nth-child(2n){--r:1.4deg}.photo:nth-child(3n){--r:-1.8deg}
.photo img{display:block;width:100%;height:320px;object-fit:cover}
.stamp{border:8px dotted #171a19}.mat{padding:16px 16px 34px}.wood{border:14px solid #7a5030}.darkWood{border:14px solid #2c1b12}.metal{border:5px solid #aaa7a0}.vintage{border:18px double #8a724e}.film{border-top:16px dashed #171a19;border-bottom:16px dashed #171a19}
figcaption{font-size:13px;text-align:center;margin-top:8px}
''';
}

class ExhibitionTemplateCodec {
  const ExhibitionTemplateCodec();

  String encode(GalleryDocument document) {
    return const JsonEncoder.withIndent('  ').convert({
      'kind': 'xulang-template',
      'version': 1,
      'title': document.title,
      'theme': document.theme.name,
      'chapters': [
        for (final chapter in document.chapters)
          {
            'title': chapter.title,
            'caption': chapter.caption,
            'order': chapter.order,
            'layout': chapter.layout.name,
            'motion': chapter.motion.name,
            'placements': [
              for (final placement in chapter.placements)
                {
                  'order': placement.order,
                  'size': placement.size.name,
                  'frame': placement.frame.name,
                  'focalX': placement.focalX,
                  'focalY': placement.focalY,
                  'zoom': placement.zoom,
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
          layout: _byName(
            GalleryLayout.values,
            chapterJson['layout'],
            GalleryLayout.hero,
          ),
          motion: _byName(
            GalleryMotion.values,
            chapterJson['motion'],
            GalleryMotion.push,
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
      chapters: chapters,
      updatedAt: now,
    );
  }
}

Map<String, Object?> _documentToJson(
  GalleryDocument document, {
  required bool includeMediaIds,
}) {
  return {
    'title': document.title,
    'theme': document.theme.name,
    'chapters': [
      for (final chapter in document.chapters)
        {
          'title': chapter.title,
          'caption': chapter.caption,
          'layout': chapter.layout.name,
          'motion': chapter.motion.name,
          'placements': [
            for (final placement in chapter.placements)
              {
                if (includeMediaIds) 'mediaId': placement.mediaId,
                'order': placement.order,
                'size': placement.size.name,
                'frame': placement.frame.name,
                'caption': placement.caption,
              },
          ],
        },
    ],
  };
}

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
