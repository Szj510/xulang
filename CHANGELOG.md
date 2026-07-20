# Changelog

All notable changes to this project will be documented in this file. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases use [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-07-20

### Added

- Added a caption-mat photo frame whose photo, paper, inscription, and rotation behave as one object.
- Added free-text canvas decorations with four font choices, adaptive ink colors, sizing, movement, rotation, editing, and deletion.
- Bundled three OFL-licensed Chinese display fonts and documented their third-party notices.

### Changed

- Moved the caption-mat frame into the hand-drawn frame family.
- Limited single-photo notes to Story Path and gave caption-mat inscriptions their own independent persisted field.

### Fixed

- Tapping empty canvas space now closes the active editing panel, while image and decoration taps still open their matching controls.
- Selecting an existing text decoration now opens and scrolls to its text controls instead of the sticker catalog.

## [1.1.1] - 2026-07-20

### Added

- One fictional portrait to the bundled first-run exhibition.

### Changed

- Replaced bundled sample media with documented synthetic assets that can be safely redistributed with the project.
- Updated the public README screenshot and full-length editor and immersive-viewer recordings.

### Fixed

- Refreshed the previously saved sample exhibition when it referenced removed bundled assets, preventing blank image placeholders.
- Corrected the sample image dimensions and canvas captions to match their displayed media.

## [1.1.0] - 2026-07-19

### Added

- Local-first photo exhibitions with chapters, layouts, frames, stickers, text, music, templates, offline HTML export, and Android screen recording.
- Open-source community documentation, issue forms, pull request template, and automated CI/release workflows.
- Bilingual project documentation and a public showcase media specification.
- Experimental iOS contribution policy with a no-codesign CI check when an iOS platform directory is present.

### Changed

- Prepared the first public open-source release under GPL-3.0.

[Unreleased]: https://github.com/Szj510/xulang/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/Szj510/xulang/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/Szj510/xulang/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/Szj510/xulang/releases/tag/v1.1.0
