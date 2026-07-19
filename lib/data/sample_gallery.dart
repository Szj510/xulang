import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/domain/gallery_document.dart';

const _obsoleteSampleMediaIds = {
  'sample-friends',
  'sample-notes',
  'sample-rain',
};

/// Detects the short-lived nine-image sample revision that referenced assets
/// no longer bundled with the app. Only that known broken revision is reset.
bool shouldRefreshBundledSample(GalleryBundle? bundle) {
  return bundle?.media.any(
        (item) => _obsoleteSampleMediaIds.contains(item.id),
      ) ??
      false;
}

GalleryBundle buildSampleGallery(DateTime now) {
  const media = [
    GalleryMedia(
      id: 'sample-coast',
      originalPath: 'asset://assets/sample/coast-sunset.png',
      thumbnailPath: 'asset://assets/sample/coast-sunset.png',
      width: 1536,
      height: 1024,
      contentHash: 'sample-coast',
    ),
    GalleryMedia(
      id: 'sample-alley',
      originalPath: 'asset://assets/sample/coastal-alley.png',
      thumbnailPath: 'asset://assets/sample/coastal-alley.png',
      width: 1023,
      height: 1537,
      contentHash: 'sample-alley',
    ),
    GalleryMedia(
      id: 'sample-walk',
      originalPath: 'asset://assets/sample/summer-walk.png',
      thumbnailPath: 'asset://assets/sample/summer-walk.png',
      width: 1024,
      height: 1536,
      contentHash: 'sample-walk',
    ),
    GalleryMedia(
      id: 'sample-train',
      originalPath: 'asset://assets/sample/train-lake.png',
      thumbnailPath: 'asset://assets/sample/train-lake.png',
      width: 1536,
      height: 1024,
      contentHash: 'sample-train',
    ),
    GalleryMedia(
      id: 'sample-window',
      originalPath: 'asset://assets/sample/sunset-window.png',
      thumbnailPath: 'asset://assets/sample/sunset-window.png',
      width: 1536,
      height: 1024,
      contentHash: 'sample-window',
    ),
    GalleryMedia(
      id: 'sample-portrait',
      originalPath: 'asset://assets/sample/portrait-golden-hour.png',
      thumbnailPath: 'asset://assets/sample/portrait-golden-hour.png',
      width: 1024,
      height: 1536,
      contentHash: 'sample-portrait',
    ),
  ];
  return GalleryBundle(
    document: GalleryDocument(
      id: 'sample-exhibition',
      title: '山海之间（官方示例）',
      coverMediaId: 'sample-coast',
      createdAt: now,
      updatedAt: now,
      chapters: const [
        GalleryChapter(
          id: 'sample-chapter-1',
          title: '潮汐的方向',
          caption: '沿着海岸走，风把远方一点点推近。',
          order: 0,
          layout: GalleryLayout.hero,
          motion: GalleryMotion.push,
          placements: [
            GalleryPlacement(
              id: 'sample-placement-1',
              mediaId: 'sample-coast',
              order: 0,
              size: GallerySize.large,
              frame: GalleryFrame.hairline,
            ),
            GalleryPlacement(
              id: 'sample-placement-2',
              mediaId: 'sample-alley',
              order: 1,
              frame: GalleryFrame.hairline,
            ),
          ],
        ),
        GalleryChapter(
          id: 'sample-chapter-2',
          title: '夏日散步',
          caption: '风穿过发梢，也穿过了那段慢下来的时光。',
          order: 1,
          layout: GalleryLayout.storyPath,
          motion: GalleryMotion.unfold,
          placements: [
            GalleryPlacement(
              id: 'sample-placement-3',
              mediaId: 'sample-train',
              order: 0,
              frame: GalleryFrame.none,
              caption: '驶向湖畔',
            ),
            GalleryPlacement(
              id: 'sample-placement-4',
              mediaId: 'sample-walk',
              order: 1,
              size: GallerySize.large,
              frame: GalleryFrame.stamp,
              caption: '山径',
            ),
            GalleryPlacement(
              id: 'sample-placement-5',
              mediaId: 'sample-coast',
              order: 2,
              size: GallerySize.large,
              frame: GalleryFrame.mat,
              caption: '海岸',
            ),
            GalleryPlacement(
              id: 'sample-placement-6',
              mediaId: 'sample-window',
              order: 3,
              size: GallerySize.small,
              frame: GalleryFrame.none,
              caption: '窗外日落',
            ),
            GalleryPlacement(
              id: 'sample-placement-7',
              mediaId: 'sample-portrait',
              order: 4,
              size: GallerySize.large,
              frame: GalleryFrame.mat,
              caption: '草间微光',
            ),
          ],
        ),
      ],
    ),
    media: media,
  );
}
