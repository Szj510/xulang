import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  test('each layout restores its own photo and decoration state', () {
    const heroSticker = GallerySticker(
      id: 'hero-text',
      kind: GalleryStickerKind.text,
      x: .3,
      y: .7,
      text: 'Hero',
    );
    final hero = const GalleryChapter(
      id: 'chapter',
      title: 'Independent layouts',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [
        GalleryPlacement(
          id: 'photo',
          mediaId: 'media',
          order: 0,
          size: GallerySize.large,
          frame: GalleryFrame.captionMat,
          scale: 1.4,
          rotation: 18,
          frameCaption: 'Hero caption',
        ),
      ],
      stickers: [heroSticker],
    ).recordCurrentLayoutState();

    final freshFilmstrip = hero.switchLayout(GalleryLayout.filmstrip);

    expect(freshFilmstrip.placements.single.size, GallerySize.medium);
    expect(freshFilmstrip.placements.single.frame, GalleryFrame.none);
    expect(freshFilmstrip.placements.single.scale, 1);
    expect(freshFilmstrip.placements.single.rotation, 0);
    expect(freshFilmstrip.stickers, isEmpty);

    final editedFilmstrip = freshFilmstrip
        .copyWith(
          placements: [
            freshFilmstrip.placements.single.copyWith(
              size: GallerySize.small,
              rotation: -7,
            ),
          ],
          stickers: const [
            GallerySticker(
              id: 'film-star',
              kind: GalleryStickerKind.star,
              x: .8,
              y: .2,
            ),
          ],
        )
        .recordCurrentLayoutState();

    final restoredHero = editedFilmstrip.switchLayout(GalleryLayout.hero);
    expect(restoredHero.placements.single.size, GallerySize.large);
    expect(restoredHero.placements.single.rotation, 18);
    expect(restoredHero.placements.single.frameCaption, 'Hero caption');
    expect(restoredHero.stickers.single.id, 'hero-text');

    final restoredFilmstrip = restoredHero.switchLayout(
      GalleryLayout.filmstrip,
    );
    expect(restoredFilmstrip.placements.single.size, GallerySize.small);
    expect(restoredFilmstrip.placements.single.rotation, -7);
    expect(restoredFilmstrip.stickers.single.id, 'film-star');
  });

  test('saved layouts reconcile photos added and removed elsewhere', () {
    final chapter = const GalleryChapter(
      id: 'chapter',
      title: 'Reconcile',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [
        GalleryPlacement(id: 'p1', mediaId: 'm1', order: 0),
        GalleryPlacement(id: 'p2', mediaId: 'm2', order: 1),
      ],
    ).recordCurrentLayoutState();
    final filmstrip = chapter
        .switchLayout(GalleryLayout.filmstrip)
        .recordCurrentLayoutState();
    final changedHero = filmstrip
        .switchLayout(GalleryLayout.hero)
        .copyWith(
          placements: const [
            GalleryPlacement(id: 'p2', mediaId: 'm2', order: 0),
            GalleryPlacement(id: 'p3', mediaId: 'm3', order: 1),
          ],
        )
        .recordCurrentLayoutState();

    final reconciled = changedHero.switchLayout(GalleryLayout.filmstrip);

    expect(reconciled.placements.map((item) => item.id), ['p2', 'p3']);
    expect(reconciled.placements.map((item) => item.order), [0, 1]);
  });
}
