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

  test('template summary includes per chapter slot counts', () {
    final template = ExhibitionTemplateCodec().encode(
      GalleryDocument(
        id: 'template',
        title: 'Trip',
        createdAt: DateTime(2026, 6, 29),
        updatedAt: DateTime(2026, 6, 29),
        chapters: const [
          GalleryChapter(
            id: 'chapter-1',
            title: 'Start',
            order: 0,
            layout: GalleryLayout.hero,
            motion: GalleryMotion.push,
            placements: [
              GalleryPlacement(id: 'slot-1', mediaId: 'm1', order: 0),
            ],
          ),
          GalleryChapter(
            id: 'chapter-2',
            title: 'Road',
            order: 1,
            layout: GalleryLayout.filmstrip,
            motion: GalleryMotion.pan,
            placements: [
              GalleryPlacement(id: 'slot-2', mediaId: 'm2', order: 0),
              GalleryPlacement(id: 'slot-3', mediaId: 'm3', order: 1),
            ],
          ),
        ],
      ),
    );

    final summary = const ExhibitionTemplateCodec().inspect(template);

    expect(summary.chapterCount, 2);
    expect(summary.placementCount, 3);
    expect(summary.chapters.map((chapter) => chapter.slotCount), [1, 2]);
  });

  test('rejects oversized template json before decoding', () {
    final padding = 'x' * ExhibitionTemplateCodec.maxTemplateBytes;
    final oversized =
        '{"kind":"xulang-template","chapters":[],"padding":"$padding"}';

    expect(
      () => const ExhibitionTemplateCodec().inspect(oversized),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'applies template with chapter media and appends extra images plainly',
    () {
      final codec = const ExhibitionTemplateCodec();
      final template = codec.encode(
        GalleryDocument(
          id: 'template',
          title: 'Template',
          createdAt: DateTime(2026, 6, 29),
          updatedAt: DateTime(2026, 6, 29),
          chapters: const [
            GalleryChapter(
              id: 'chapter-1',
              title: 'One',
              order: 0,
              layout: GalleryLayout.hero,
              motion: GalleryMotion.push,
              placements: [
                GalleryPlacement(
                  id: 'slot-1',
                  mediaId: 'template-media-1',
                  order: 0,
                  frame: GalleryFrame.wood,
                  size: GallerySize.large,
                ),
                GalleryPlacement(
                  id: 'slot-2',
                  mediaId: 'template-media-2',
                  order: 1,
                  frame: GalleryFrame.stamp,
                  size: GallerySize.small,
                ),
              ],
            ),
          ],
        ),
      );
      var id = 0;
      final applied = codec.applyToDocumentByChapterMedia(
        base: GalleryDocument.create(
          id: 'new',
          title: 'New',
          createdAt: DateTime(2026, 6, 29),
        ),
        templateJson: template,
        createId: () => 'generated-${++id}',
        now: DateTime(2026, 6, 29, 12),
        mediaIdsByChapter: const [
          ['media-1', 'media-2', 'media-extra'],
        ],
        titleOverride: 'Imported',
        appendExtraMedia: true,
      );

      final placements = applied.chapters.single.placements;
      expect(placements, hasLength(3));
      expect(placements[0].mediaId, 'media-1');
      expect(placements[0].frame, GalleryFrame.wood);
      expect(placements[1].mediaId, 'media-2');
      expect(placements[1].frame, GalleryFrame.stamp);
      expect(placements[2].mediaId, 'media-extra');
      expect(placements[2].frame, GalleryFrame.none);
      expect(placements[2].size, GallerySize.medium);
    },
  );

  test('template application caps every chapter at the gallery limit', () {
    final codec = const ExhibitionTemplateCodec();
    final template = codec.encode(
      GalleryDocument(
        id: 'template-limit',
        title: 'Limit',
        createdAt: DateTime(2026, 7, 10),
        updatedAt: DateTime(2026, 7, 10),
        chapters: const [
          GalleryChapter(
            id: 'chapter',
            title: 'Chapter',
            order: 0,
            layout: GalleryLayout.orbit,
            motion: GalleryMotion.push,
            placements: [
              GalleryPlacement(id: 'slot', mediaId: 'slot-media', order: 0),
            ],
          ),
        ],
      ),
    );
    final mediaIds = List.generate(24, (index) => 'media-$index');

    final applied = codec.applyToDocumentByChapterMedia(
      base: GalleryDocument.create(
        id: 'new-limit',
        title: 'New',
        createdAt: DateTime(2026, 7, 10),
      ),
      templateJson: template,
      createId: () => 'generated',
      now: DateTime(2026, 7, 10),
      mediaIdsByChapter: [mediaIds],
      appendExtraMedia: true,
    );

    expect(
      applied.chapters.single.placements,
      hasLength(maxGalleryPlacementsPerChapter),
    );
  });
}
