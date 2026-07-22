# Changelog

All notable changes to this project will be documented in this file. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases use [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Moved the official project website and privacy policy to `https://xulang.dpdns.org/`.

## [1.3.0] - 2026-07-22

### Added

- Added an in-app About & Open Source panel with the exact app version, source, official downloads, privacy policy, private security reporting, GPL-3.0, and third-party license entries.
- Added a bilingual GitHub Pages project home and a dedicated social preview image.
- Added ARM64 and universal Android release artifacts, build provenance attestations, a consolidated checksum file, and a manual release dry run.

### Changed

- Shortened the official sample title and moved its identity into a separate badge so editor and viewer titles remain readable.
- Converted the six bundled sample photos from PNG to visually reviewed quality-88 JPEGs and stopped bundling the large launcher-icon source as a runtime asset.
- Improved small-text contrast while preserving the existing ink, paper, and warm-gold visual language.
- Reorganized the README around the real Library → Editor → Immersive viewer flow and clarified APK selection and verification.

### Security

- Added Android signing-certificate verification and GitHub artifact provenance to the release workflow.
- Enabled dependency vulnerability alerts and automated security updates, and tightened GitHub Actions and protected-branch settings.
- Made GitHub private vulnerability reporting the only security disclosure channel.

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

[Unreleased]: https://github.com/Szj510/xulang/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/Szj510/xulang/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/Szj510/xulang/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/Szj510/xulang/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/Szj510/xulang/releases/tag/v1.1.0
