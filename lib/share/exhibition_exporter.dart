import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:image/image.dart' as img;
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/narrative_track_resolver.dart';

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

class ExhibitionGifExporter {
  const ExhibitionGifExporter({
    this.width = 540,
    this.height = 960,
    this.maxFrames = 12,
    this.frameDurationCentiseconds = 70,
  });

  final int width;
  final int height;
  final int maxFrames;
  final int frameDurationCentiseconds;

  Future<Uint8List> buildGif(
    GalleryBundle bundle, {
    int chapterIndex = 0,
  }) async {
    final encoder = img.GifEncoder(
      repeat: 0,
      delay: frameDurationCentiseconds,
      samplingFactor: 20,
    );
    final mediaById = {for (final media in bundle.media) media.id: media};
    final chapters = bundle.document.chapters
        .where((chapter) => chapter.placements.isNotEmpty)
        .toList(growable: false);
    if (chapters.isEmpty) {
      encoder.addFrame(_emptyFrame(), duration: frameDurationCentiseconds);
      return encoder.finish()!;
    }
    final chapter = chapters[chapterIndex.clamp(0, chapters.length - 1)];
    final decoded = <String, img.Image>{};
    for (final placement in chapter.placements) {
      final media = mediaById[placement.mediaId];
      if (media == null) continue;
      final source = await _decodeBestAvailable(media);
      if (source != null) decoded[placement.mediaId] = source;
    }
    if (decoded.isEmpty) {
      encoder.addFrame(_emptyFrame(), duration: frameDurationCentiseconds);
      return encoder.finish()!;
    }
    for (var index = 0; index < maxFrames; index++) {
      final progress = maxFrames == 1 ? 0.0 : index / (maxFrames - 1);
      encoder.addFrame(
        _composeSceneFrame(
          chapter: chapter,
          mediaById: decoded,
          progress: progress,
          itemIndex: index,
        ),
        duration: frameDurationCentiseconds,
      );
    }
    return encoder.finish()!;
  }

  Future<img.Image?> _decodeBestAvailable(GalleryMedia media) async {
    for (final path in [media.thumbnailPath, media.originalPath]) {
      if (path.startsWith('asset://')) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        return img.decodeImage(await file.readAsBytes());
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  img.Image _composeSceneFrame({
    required GalleryChapter chapter,
    required Map<String, img.Image> mediaById,
    required double progress,
    required int itemIndex,
  }) {
    final canvas = _emptyFrame();
    final track = NarrativeTrackResolver.resolve(
      chapter: chapter,
      viewport: Size(width.toDouble(), height.toDouble()),
    );
    final frame = track.resolve(progress);
    final placementsById = {
      for (final placement in chapter.placements) placement.id: placement,
    };
    final nodes = [...frame.nodes]..sort((a, b) => a.depth.compareTo(b.depth));
    for (final node in nodes) {
      final placement = placementsById[node.placementId];
      if (placement == null || node.opacity < .06) continue;
      final source = mediaById[placement.mediaId];
      if (source == null) continue;
      final rect = node.rect;
      final photoWidth = math.max(20, rect.width.round());
      final photoHeight = math.max(20, rect.height.round());
      final resized = _cover(source, photoWidth, photoHeight);
      final framePad = (8 + node.depth * 14).round();
      final x = rect.left.round();
      final y = rect.top.round();
      _drawSoftShadow(canvas, x, y, photoWidth, photoHeight, node.depth);
      _drawGifFrame(
        canvas,
        RectInt(
          x - framePad,
          y - framePad,
          photoWidth + framePad * 2,
          photoHeight + framePad * 2,
        ),
        placement.frame,
      );
      img.compositeImage(canvas, resized, dstX: x, dstY: y);
      img.drawRect(
        canvas,
        x1: x,
        y1: y,
        x2: x + photoWidth,
        y2: y + photoHeight,
        color: img.ColorRgb8(24, 24, 22),
        thickness: 2,
      );
    }
    _drawProgressDots(canvas, itemIndex);
    return canvas;
  }

  void _drawSoftShadow(
    img.Image canvas,
    int x,
    int y,
    int photoWidth,
    int photoHeight,
    double depth,
  ) {
    final pad = (10 + depth * 18).round();
    img.drawRect(
      canvas,
      x1: x - pad,
      y1: y + pad,
      x2: x + photoWidth + pad,
      y2: y + photoHeight + pad * 2,
      color: img.ColorRgba8(0, 0, 0, (32 + depth * 70).round()),
      radius: 6,
    );
  }

  img.Image _emptyFrame() {
    final canvas = img.Image(width: width, height: height);
    img.fill(canvas, color: img.ColorRgb8(22, 24, 23));
    for (var y = 0; y < height; y += 3) {
      final shade = 22 + (y * 10 ~/ height);
      img.drawLine(
        canvas,
        x1: 0,
        y1: y,
        x2: width,
        y2: y,
        color: img.ColorRgb8(shade, shade + 2, shade + 1),
      );
    }
    return canvas;
  }

  img.Image _cover(img.Image source, int targetWidth, int targetHeight) {
    final sourceRatio = source.width / source.height;
    final targetRatio = targetWidth / targetHeight;
    late final img.Image cropped;
    if (sourceRatio > targetRatio) {
      final cropWidth = (source.height * targetRatio).round();
      cropped = img.copyCrop(
        source,
        x: ((source.width - cropWidth) / 2).round(),
        y: 0,
        width: cropWidth,
        height: source.height,
      );
    } else {
      final cropHeight = (source.width / targetRatio).round();
      cropped = img.copyCrop(
        source,
        x: 0,
        y: ((source.height - cropHeight) / 2).round(),
        width: source.width,
        height: cropHeight,
      );
    }
    return img.copyResize(cropped, width: targetWidth, height: targetHeight);
  }

  void _drawGifFrame(img.Image canvas, RectInt rect, GalleryFrame frame) {
    final base = switch (frame) {
      GalleryFrame.wood => img.ColorRgb8(132, 82, 43),
      GalleryFrame.darkWood => img.ColorRgb8(45, 28, 18),
      GalleryFrame.metal => img.ColorRgb8(184, 181, 172),
      GalleryFrame.vintage => img.ColorRgb8(214, 188, 136),
      GalleryFrame.film => img.ColorRgb8(9, 9, 8),
      GalleryFrame.stamp || GalleryFrame.mat => img.ColorRgb8(236, 225, 202),
      _ => img.ColorRgb8(238, 226, 205),
    };
    img.drawRect(
      canvas,
      x1: rect.x,
      y1: rect.y,
      x2: rect.x + rect.width,
      y2: rect.y + rect.height,
      color: base,
      thickness: math.max(10, rect.width ~/ 24),
    );
    for (var i = 0; i < 18; i++) {
      final offset = ((i * 17) % math.max(1, rect.width)).toInt();
      final color = frame == GalleryFrame.metal
          ? img.ColorRgb8(230, 227, 218)
          : img.ColorRgb8(
              math.min(255, base.r.toInt() + 18),
              math.min(255, base.g.toInt() + 12),
              math.min(255, base.b.toInt() + 8),
            );
      img.drawLine(
        canvas,
        x1: rect.x + offset,
        y1: rect.y,
        x2: rect.x + ((offset + rect.width ~/ 3) % rect.width).toInt(),
        y2: rect.y + rect.height,
        color: color,
      );
    }
  }

  void _drawProgressDots(img.Image canvas, int active) {
    final start = width ~/ 2 - 42;
    for (var i = 0; i < 6; i++) {
      final color = i == active % 6
          ? img.ColorRgb8(235, 214, 174)
          : img.ColorRgb8(96, 96, 92);
      img.fillCircle(
        canvas,
        x: start + i * 17,
        y: height - 66,
        radius: 4,
        color: color,
      );
    }
  }
}

class RectInt {
  const RectInt(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;
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
                  'scale': placement.scale,
                  'offsetX': placement.offsetX,
                  'offsetY': placement.offsetY,
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
                'scale': placement.scale,
                'offsetX': placement.offsetX,
                'offsetY': placement.offsetY,
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
