import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/domain/gallery_document.dart';

void main() {
  test('database preserves independent layout states', () async {
    final database = GalleryDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 7, 23);
    final hero = const GalleryChapter(
      id: 'chapter',
      title: 'Layouts',
      order: 0,
      layout: GalleryLayout.hero,
      motion: GalleryMotion.push,
      placements: [
        GalleryPlacement(
          id: 'placement',
          mediaId: 'media',
          order: 0,
          size: GallerySize.large,
          rotation: 12,
        ),
      ],
      stickers: [
        GallerySticker(
          id: 'hero-sticker',
          kind: GalleryStickerKind.heart,
          x: .2,
          y: .3,
        ),
      ],
    ).recordCurrentLayoutState();
    final filmstrip = hero
        .switchLayout(GalleryLayout.filmstrip)
        .copyWith(
          placements: const [
            GalleryPlacement(
              id: 'placement',
              mediaId: 'media',
              order: 0,
              size: GallerySize.small,
              rotation: -4,
            ),
          ],
          stickers: const [
            GallerySticker(
              id: 'film-sticker',
              kind: GalleryStickerKind.star,
              x: .8,
              y: .7,
            ),
          ],
        )
        .recordCurrentLayoutState();
    final document = GalleryDocument(
      id: 'exhibition',
      title: 'Persistence',
      createdAt: now,
      updatedAt: now,
      chapters: [filmstrip],
    );
    const media = GalleryMedia(
      id: 'media',
      originalPath: '/media/original.jpg',
      thumbnailPath: '/media/thumb.jpg',
      width: 100,
      height: 100,
      contentHash: 'hash',
    );

    await database.saveDocument(document, const [media]);
    final restored = await database.loadDocument(document.id);

    expect(restored, isNotNull);
    final restoredFilmstrip = restored!.chapters.single;
    expect(restoredFilmstrip.layoutStates, hasLength(2));
    expect(restoredFilmstrip.placements.single.rotation, -4);
    expect(restoredFilmstrip.stickers.single.id, 'film-sticker');

    final restoredHero = restoredFilmstrip.switchLayout(GalleryLayout.hero);
    expect(restoredHero.placements.single.size, GallerySize.large);
    expect(restoredHero.placements.single.rotation, 12);
    expect(restoredHero.stickers.single.id, 'hero-sticker');
  });

  test('v1.2 data survives first layout switch and v1.3 save', () async {
    final database = GalleryDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 7, 20);

    await database
        .into(database.exhibitions)
        .insert(
          ExhibitionsCompanion.insert(
            id: 'legacy-exhibition',
            title: 'Legacy exhibition',
            theme: GalleryTheme.ink.name,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await database
        .into(database.mediaAssets)
        .insert(
          MediaAssetsCompanion.insert(
            id: 'legacy-media',
            exhibitionId: 'legacy-exhibition',
            originalPath: '/old-version/original.jpg',
            thumbnailPath: '/old-version/thumbnail.webp',
            width: 2400,
            height: 1600,
            contentHash: 'legacy-hash',
          ),
        );
    await database
        .into(database.chapters)
        .insert(
          ChaptersCompanion.insert(
            id: 'legacy-chapter',
            exhibitionId: 'legacy-exhibition',
            title: 'Legacy chapter',
            caption: 'Kept from v1.2',
            sortOrder: 0,
            layout: GalleryLayout.hero.name,
            motion: GalleryMotion.push.name,
            customPathData: const Value(
              '{"version":2,"anchors":[],"connections":[],"stickers":[]}',
            ),
          ),
        );
    await database
        .into(database.placements)
        .insert(
          PlacementsCompanion.insert(
            id: 'legacy-placement',
            chapterId: 'legacy-chapter',
            mediaId: 'legacy-media',
            sortOrder: 0,
            size: GallerySize.large.name,
            frame: GalleryFrame.vintage.name,
            focalX: .35,
            focalY: .62,
            zoom: 1.4,
            caption: 'Original caption',
            scale: const Value(1.25),
            offsetX: const Value(.12),
            offsetY: const Value(-.08),
            rotation: const Value(7),
          ),
        );

    final legacy = await database.loadDocument('legacy-exhibition');
    final legacyMedia = await database.loadMedia('legacy-exhibition');

    expect(legacy, isNotNull);
    expect(legacyMedia.single.originalPath, '/old-version/original.jpg');
    expect(legacy!.chapters.single.layoutStates, isEmpty);
    expect(legacy.chapters.single.placements.single.rotation, 7);

    final orbit = legacy.chapters.single.switchLayout(GalleryLayout.orbit);
    expect(orbit.placements.single.rotation, 0);
    final restoredHero = orbit.switchLayout(GalleryLayout.hero);
    expect(restoredHero.placements.single.frame, GalleryFrame.vintage);
    expect(restoredHero.placements.single.focalX, .35);
    expect(restoredHero.placements.single.focalY, .62);
    expect(restoredHero.placements.single.zoom, 1.4);
    expect(restoredHero.placements.single.scale, 1.25);
    expect(restoredHero.placements.single.offsetX, .12);
    expect(restoredHero.placements.single.offsetY, -.08);
    expect(restoredHero.placements.single.rotation, 7);
    expect(restoredHero.placements.single.caption, 'Original caption');

    await database.saveDocument(
      legacy.copyWith(chapters: [restoredHero]),
      legacyMedia,
    );
    final upgraded = await database.loadDocument('legacy-exhibition');
    final upgradedMedia = await database.loadMedia('legacy-exhibition');

    expect(upgraded, isNotNull);
    expect(upgraded!.title, 'Legacy exhibition');
    expect(upgraded.chapters.single.title, 'Legacy chapter');
    expect(upgraded.chapters.single.caption, 'Kept from v1.2');
    expect(upgraded.chapters.single.layoutStates, hasLength(2));
    expect(upgraded.chapters.single.placements.single.rotation, 7);
    expect(upgradedMedia.single.contentHash, 'legacy-hash');
    expect(upgradedMedia.single.originalPath, '/old-version/original.jpg');
  });
}
