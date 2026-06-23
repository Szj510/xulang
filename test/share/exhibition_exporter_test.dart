import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/exhibition_exporter.dart';

void main() {
  test('template export omits media identities and can apply styles', () {
    final document = GalleryDocument(
      id: 'exhibition',
      title: '山海',
      showChapterTitleInPlayback: false,
      createdAt: DateTime(2026, 6, 23),
      updatedAt: DateTime(2026, 6, 23),
      chapters: const [
        GalleryChapter(
          id: 'chapter',
          title: '模板章',
          caption: '模板说明',
          order: 0,
          layout: GalleryLayout.filmstrip,
          motion: GalleryMotion.pan,
          pathStyle: StoryPathStyle.glow,
          placements: [
            GalleryPlacement(
              id: 'p1',
              mediaId: 'secret-media',
              order: 0,
              size: GallerySize.large,
              frame: GalleryFrame.wood,
              focalX: .25,
              focalY: .75,
              scale: 1.2,
              offsetX: .1,
              caption: '第一张',
            ),
            GalleryPlacement(
              id: 'p2',
              mediaId: 'secret-media-2',
              order: 1,
              frame: GalleryFrame.metal,
            ),
          ],
        ),
      ],
    );

    final jsonText = ExhibitionTemplateCodec().encode(document);
    final decoded = jsonDecode(jsonText) as Map<String, Object?>;

    expect(jsonText, isNot(contains('secret-media')));
    expect(jsonText, isNot(contains('originalPath')));
    expect(decoded['kind'], 'xulang-template');

    var id = 0;
    final applied = ExhibitionTemplateCodec().applyToDocument(
      base: document.copyWith(
        showChapterTitleInPlayback: true,
        chapters: [
          document.chapters.single.copyWith(
            placements: const [
              GalleryPlacement(id: 'a', mediaId: 'm1', order: 0),
              GalleryPlacement(id: 'b', mediaId: 'm2', order: 1),
            ],
          ),
        ],
      ),
      templateJson: jsonText,
      createId: () => 'new-${id++}',
      now: DateTime(2026, 6, 24),
    );

    final placements = applied.chapters.single.placements;
    expect(applied.chapters.single.layout, GalleryLayout.filmstrip);
    expect(applied.chapters.single.pathStyle, StoryPathStyle.glow);
    expect(applied.showChapterTitleInPlayback, isFalse);
    expect(placements.map((item) => item.mediaId), ['m1', 'm2']);
    expect(placements.first.frame, GalleryFrame.wood);
    expect(placements.first.size, GallerySize.large);
    expect(placements.first.focalX, .25);
    expect(placements.first.scale, 1.2);
    expect(placements.first.offsetX, .1);
  });
}
