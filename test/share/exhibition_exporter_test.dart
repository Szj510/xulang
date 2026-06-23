import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/exhibition_exporter.dart';

void main() {
  test('html export escapes text and embeds local image data', () async {
    final temp = await Directory.systemTemp.createTemp('xulang-export-test-');
    addTearDown(() => temp.delete(recursive: true));
    final image = File('${temp.path}/photo.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);
    final bundle = GalleryBundle(
      document: GalleryDocument(
        id: 'exhibition',
        title: '海风 <script>',
        createdAt: DateTime(2026, 6, 23),
        updatedAt: DateTime(2026, 6, 23),
        chapters: const [
          GalleryChapter(
            id: 'chapter',
            title: '夏日 & 散步',
            caption: '风 < 慢下来',
            order: 0,
            layout: GalleryLayout.storyPath,
            motion: GalleryMotion.unfold,
            placements: [
              GalleryPlacement(
                id: 'placement',
                mediaId: 'media',
                order: 0,
                frame: GalleryFrame.stamp,
                caption: '巷遇',
              ),
            ],
          ),
        ],
      ),
      media: [
        GalleryMedia(
          id: 'media',
          originalPath: image.path,
          thumbnailPath: image.path,
          width: 20,
          height: 10,
          contentHash: 'hash',
        ),
      ],
    );

    final html = await ExhibitionHtmlExporter().buildHtml(bundle);

    expect(html, contains('海风 &lt;script&gt;'));
    expect(html, contains('夏日 &amp; 散步'));
    expect(html, contains('data:image/jpeg;base64,AQIDBA=='));
    expect(html, isNot(contains('<script>')));
  });

  test('template export omits media identities and can apply styles', () {
    final document = GalleryDocument(
      id: 'exhibition',
      title: '山海',
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
          placements: [
            GalleryPlacement(
              id: 'p1',
              mediaId: 'secret-media',
              order: 0,
              size: GallerySize.large,
              frame: GalleryFrame.wood,
              focalX: .25,
              focalY: .75,
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
    expect(placements.map((item) => item.mediaId), ['m1', 'm2']);
    expect(placements.first.frame, GalleryFrame.wood);
    expect(placements.first.size, GallerySize.large);
    expect(placements.first.focalX, .25);
  });
}
