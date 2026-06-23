# Export, Share, Templates, Frames Design

## Goal

Add a practical v1 for sharing and reusing exhibitions while improving the current viewing quality issues reported after manual testing.

## Scope

- Export an exhibition as a self-contained offline HTML file that can be opened in a browser.
- Share exported HTML and template files through Android Sharesheet.
- Export and import reusable templates as `.xulang-template.json`; templates include structure, chapter text, layouts, motions, frame styles, sizes, focal settings, and captions, but not photos.
- Add more frame styles: wood, dark wood, metal, vintage album, and film perforation.
- Increase gesture sensitivity without breaking boundary chapter switching.
- Remove the bottom item-control buttons from immersive playback to avoid covering the artwork.
- Fix horizontal filmstrip so all imported images are reachable, not only the first visible pair.

## Explicit boundaries

- No hosted template marketplace in this iteration.
- No accounts, cloud sync, remote moderation, or network permission.
- Template “download” means importing a template file that another user shared or saved locally.
- HTML export is an offline artifact; it is not an editable project package.

## Architecture

- Add pure export/template codecs under `lib/share/` so serialization can be tested without UI.
- Add a small `ShareService` that writes files to the app documents directory and invokes platform share APIs.
- Keep persisted gallery schema compatible by adding new `GalleryFrame` enum values only; existing database frame strings continue to load.
- Add UI entry points in editor actions and library card overflow/menu surfaces where the user already manages exhibitions.
- Fix filmstrip by making the layout resolver and narrative track expose the real content extent for non-story horizontal templates.

## Test strategy

- Unit tests for HTML escaping, embedded image data, template omission of media paths, and template application to existing placements.
- Widget tests for frame visual distinction and hidden immersive item controls.
- Layout/controller tests for faster drag progress and filmstrip reachability with six images.
- Full verification: `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --release`.
