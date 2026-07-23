import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/share/exhibition_exporter.dart';

void main() {
  test('templates preserve independent layout states without media ids', () {
    final now = DateTime.utc(2026, 7, 23);
    final hero = const GalleryChapter(
      id: 'chapter',
      title: 'Template layouts',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [
        GalleryPlacement(
          id: 'slot',
          mediaId: 'secret-media-id',
          order: 0,
          size: GallerySize.large,
          frame: GalleryFrame.wood,
          rotation: 9,
        ),
      ],
      stickers: [
        GallerySticker(
          id: 'hero-decoration',
          kind: GalleryStickerKind.leaf,
          x: .2,
          y: .8,
        ),
      ],
    ).recordCurrentLayoutState();
    final filmstrip = hero
        .switchLayout(GalleryLayout.filmstrip)
        .copyWith(
          placements: const [
            GalleryPlacement(
              id: 'slot',
              mediaId: 'secret-media-id',
              order: 0,
              size: GallerySize.small,
              frame: GalleryFrame.film,
              rotation: -6,
            ),
          ],
          stickers: const [
            GallerySticker(
              id: 'film-decoration',
              kind: GalleryStickerKind.star,
              x: .7,
              y: .3,
            ),
          ],
        )
        .recordCurrentLayoutState();
    final source = GalleryDocument(
      id: 'source',
      title: 'Template',
      createdAt: now,
      updatedAt: now,
      chapters: [filmstrip],
    );
    const codec = ExhibitionTemplateCodec();

    final encoded = codec.encode(source);

    expect(encoded, isNot(contains('secret-media-id')));
    var nextId = 0;
    final applied = codec.applyToDocument(
      base: GalleryDocument(
        id: 'target',
        title: 'Target',
        createdAt: now,
        updatedAt: now,
        chapters: const [
          GalleryChapter(
            id: 'target-chapter',
            title: 'Target',
            order: 0,
            layout: GalleryLayout.hero,
            motion: GalleryMotion.push,
            placements: [
              GalleryPlacement(
                id: 'target-placement',
                mediaId: 'target-media',
                order: 0,
              ),
            ],
          ),
        ],
      ),
      templateJson: encoded,
      createId: () => 'new-${nextId++}',
      now: now,
    );

    final appliedFilmstrip = applied.chapters.single;
    expect(appliedFilmstrip.layout, GalleryLayout.filmstrip);
    expect(appliedFilmstrip.placements.single.mediaId, 'target-media');
    expect(appliedFilmstrip.placements.single.size, GallerySize.small);
    expect(appliedFilmstrip.placements.single.rotation, -6);
    expect(appliedFilmstrip.stickers.single.id, 'film-decoration');

    final appliedHero = appliedFilmstrip.switchLayout(GalleryLayout.hero);
    expect(appliedHero.placements.single.mediaId, 'target-media');
    expect(appliedHero.placements.single.size, GallerySize.large);
    expect(appliedHero.placements.single.frame, GalleryFrame.wood);
    expect(appliedHero.placements.single.rotation, 9);
    expect(appliedHero.stickers.single.id, 'hero-decoration');
  });
}
