import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/layout/motion_resolver.dart';
import 'package:xulang/layout/story_path_geometry.dart';
import 'package:xulang/widgets/gallery_image.dart';
import 'package:xulang/widgets/scene_canvas.dart';

void main() {
  const media = GalleryMedia(
    id: 'media',
    originalPath: 'asset://assets/sample/coast-sunset.png',
    thumbnailPath: 'asset://assets/sample/train-lake.png',
    width: 1536,
    height: 1024,
    contentHash: 'hash',
  );
  const chapter = GalleryChapter(
    id: 'chapter',
    title: '章节',
    order: 0,
    layout: GalleryLayout.hero,
    motion: GalleryMotion.push,
    placements: [
      GalleryPlacement(
        id: 'placement',
        mediaId: 'media',
        order: 0,
        focalX: 1,
        focalY: 0,
        zoom: 2,
      ),
    ],
  );

  testWidgets('applies crop focus and zoom to each image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(chapter: chapter, media: [media]),
        ),
      ),
    );

    final image = tester.widget<GalleryImage>(find.byType(GalleryImage));
    expect(image.alignment, const Alignment(1, -1));
    expect(image.scale, 2);
    expect(image.path, media.thumbnailPath);
  });

  testWidgets('viewer mode selects the original image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            useOriginals: true,
          ),
        ),
      ),
    );

    final image = tester.widget<GalleryImage>(find.byType(GalleryImage));
    expect(image.path, media.originalPath);
  });

  testWidgets('paper theme changes the scene surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            sceneTheme: GalleryTheme.paper,
          ),
        ),
      ),
    );

    final background = tester.widget<CustomPaint>(
      find.byKey(const Key('scene-background')),
    );
    expect(
      background.painter,
      isA<SceneBackgroundPainter>().having(
        (painter) => painter.sceneTheme,
        'theme',
        GalleryTheme.paper,
      ),
    );
  });

  testWidgets('custom canvas image is layered above the painted theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            sceneTheme: GalleryTheme.moonlight,
            canvasBackgroundPath: 'asset://assets/sample/coast-sunset.png',
            canvasBackgroundOpacity: 0.42,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('scene-custom-canvas-background')),
      findsOneWidget,
    );
    final image = tester.widget<GalleryImage>(
      find.descendant(
        of: find.byKey(const Key('scene-custom-canvas-background')),
        matching: find.byType(GalleryImage),
      ),
    );
    expect(image.path, 'asset://assets/sample/coast-sunset.png');
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('scene-custom-canvas-opacity')))
          .opacity,
      0.42,
    );
  });

  testWidgets('camera progress changes node transforms continuously', (
    tester,
  ) async {
    Future<void> pumpAt(double cameraProgress) {
      return tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 844,
            child: SceneCanvas(
              chapter: chapter,
              media: const [media],
              cameraProgress: cameraProgress,
            ),
          ),
        ),
      );
    }

    await pumpAt(.25);
    final before = tester
        .widget<Transform>(find.byKey(const Key('scene-node-placement')))
        .transform
        .clone();
    await pumpAt(.30);
    final after = tester
        .widget<Transform>(find.byKey(const Key('scene-node-placement')))
        .transform;

    expect(after, isNot(before));
  });

  testWidgets('scene node gestures emit placement transform updates', (
    tester,
  ) async {
    final updates = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            onPlacementTransformStart: (id) => updates.add('start:$id'),
            onPlacementTransformUpdate: (id, scale, delta, rotationDelta) =>
                updates.add('update:$id'),
            onPlacementTransformEnd: (id) => updates.add('end:$id'),
          ),
        ),
      ),
    );

    final center = tester.getCenter(
      find.byKey(const Key('scene-node-placement')),
    );
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(12, 8));
    await gesture.up();
    await tester.pump();

    expect(updates.first, 'start:placement');
    expect(updates, contains('update:placement'));
    expect(updates.last, 'end:placement');
  });

  testWidgets('scene node two finger pinch emits scale greater than one', (
    tester,
  ) async {
    final scales = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: [media],
            onPlacementTransformStart: (_) {},
            onPlacementTransformUpdate: (_, scale, _, _) => scales.add(scale),
            onPlacementTransformEnd: (_) {},
          ),
        ),
      ),
    );

    final center = tester.getCenter(
      find.byKey(const Key('scene-node-placement')),
    );
    final first = await tester.createGesture();
    final second = await tester.createGesture();
    await first.down(center - const Offset(20, 0));
    await second.down(center + const Offset(20, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(44, 0));
    await second.moveTo(center + const Offset(44, 0));
    await tester.pump();
    await first.up();
    await second.up();

    expect(scales, isNotEmpty);
    expect(scales.reduce((a, b) => a > b ? a : b), greaterThan(1.2));
  });

  testWidgets('sticker placement surface lets image taps select placements', (
    tester,
  ) async {
    final tappedPlacements = <String>[];
    final placedStickers = <Offset>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: chapter,
            media: const [media],
            stickerEditingEnabled: true,
            selectedStickerKind: GalleryStickerKind.star,
            onPlacementTap: tappedPlacements.add,
            onStickerPlaced: (position, _) => placedStickers.add(position),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('scene-node-placement'))),
    );
    await tester.pump();

    expect(tappedPlacements, ['placement']);
    expect(placedStickers, isEmpty);
  });

  testWidgets('story path painter receives resolved scene geometry', (
    tester,
  ) async {
    const placements = [
      GalleryPlacement(id: 'p0', mediaId: 'media', order: 0),
      GalleryPlacement(id: 'p1', mediaId: 'media', order: 1),
      GalleryPlacement(id: 'p2', mediaId: 'media', order: 2),
      GalleryPlacement(id: 'p3', mediaId: 'media', order: 3),
    ];
    const storyChapter = GalleryChapter(
      id: 'story',
      title: 'Story',
      order: 0,
      layout: GalleryLayout.storyPath,
      motion: GalleryMotion.push,
      placements: placements,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: storyChapter,
            media: [media],
            cameraProgress: .35,
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('story-path-line')),
    );
    final painter = paint.painter! as StoryPathPainter;
    expect(painter.geometry.segments, isNotEmpty);

    final placementIndices = painter.geometry.anchors
        .map(
          (anchor) => placements.indexWhere((p) => p.id == anchor.placementId),
        )
        .toList();
    expect(placementIndices, isNotEmpty);
    expect(placementIndices, everyElement(greaterThanOrEqualTo(0)));
    expect(placementIndices, orderedEquals([...placementIndices]..sort()));

    final sceneStack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byKey(const Key('scene-background')),
            matching: find.byType(Stack),
          )
          .first,
    );
    final pathLayer = sceneStack.children.first as Positioned;
    final pathIgnorePointer = pathLayer.child as IgnorePointer;
    final pathOpacity = pathIgnorePointer.child! as Opacity;
    expect(
      (pathOpacity.child! as CustomPaint).key,
      const Key('story-path-line'),
    );
  });

  testWidgets('custom story path anchors drive geometry and labels', (
    tester,
  ) async {
    const storyChapter = GalleryChapter(
      id: 'custom-story',
      title: 'Story',
      order: 0,
      layout: GalleryLayout.storyPath,
      motion: GalleryMotion.push,
      customPathAnchors: [
        CustomPathAnchor(x: 0.2, y: 0.25, label: 'start'),
        CustomPathAnchor(x: 0.8, y: 0.75, label: 'end'),
      ],
      placements: [
        GalleryPlacement(id: 'p0', mediaId: 'media', order: 0),
        GalleryPlacement(id: 'p1', mediaId: 'media', order: 1),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 800,
          child: SceneCanvas(chapter: storyChapter, media: [media]),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('story-path-line')),
    );
    final painter = paint.painter! as StoryPathPainter;
    final viewport = tester.getSize(find.byKey(const Key('scene-background')));
    expect(painter.geometry.anchors, hasLength(2));
    expect(painter.geometry.segments, hasLength(1));
    expect(
      painter.geometry.anchors.first.point.dx,
      closeTo(viewport.width * 0.2, 0.01),
    );
    expect(
      painter.geometry.anchors.first.point.dy,
      closeTo(viewport.height * 0.25, 0.01),
    );
    expect(find.text('start'), findsOneWidget);
    expect(find.text('end'), findsOneWidget);
  });

  test('story path painter repaints for geometry or theme changes', () {
    final geometry = StoryPathGeometry(
      anchors: const [
        StoryPathAnchor(
          placementId: 'p0',
          point: Offset(20, 30),
          nodeRect: Rect.fromLTWH(0, 0, 10, 10),
        ),
      ],
      segments: const [],
    );
    final equalGeometry = StoryPathGeometry(
      anchors: const [
        StoryPathAnchor(
          placementId: 'p0',
          point: Offset(20, 30),
          nodeRect: Rect.fromLTWH(0, 0, 10, 10),
        ),
      ],
      segments: const [],
    );
    final changedGeometry = StoryPathGeometry(
      anchors: const [
        StoryPathAnchor(
          placementId: 'p0',
          point: Offset(21, 30),
          nodeRect: Rect.fromLTWH(0, 0, 10, 10),
        ),
      ],
      segments: const [],
    );

    final painter = StoryPathPainter(
      sceneTheme: GalleryTheme.ink,
      geometry: geometry,
    );
    expect(
      painter.shouldRepaint(
        StoryPathPainter(sceneTheme: GalleryTheme.ink, geometry: equalGeometry),
      ),
      isFalse,
    );
    expect(
      painter.shouldRepaint(
        StoryPathPainter(
          sceneTheme: GalleryTheme.ink,
          geometry: changedGeometry,
        ),
      ),
      isTrue,
    );
    expect(
      painter.shouldRepaint(
        StoryPathPainter(sceneTheme: GalleryTheme.paper, geometry: geometry),
      ),
      isTrue,
    );
  });

  test('story path anchor dots use opaque themed foreground color', () {
    expect(storyPathDotColor(GalleryTheme.ink).toARGB32(), 0xD9E8DFCE);
    expect(storyPathDotColor(GalleryTheme.paper).toARGB32(), 0xD90A0B0C);
  });

  test('story path painter draws geometry onto the canvas', () async {
    final geometry = StoryPathGeometry(
      anchors: const [
        StoryPathAnchor(
          placementId: 'p0',
          point: Offset(12, 12),
          nodeRect: Rect.fromLTWH(4, 4, 16, 16),
        ),
        StoryPathAnchor(
          placementId: 'p1',
          point: Offset(52, 52),
          nodeRect: Rect.fromLTWH(44, 44, 16, 16),
        ),
      ],
      segments: const [
        StoryPathSegment(
          start: Offset(12, 12),
          control1: Offset(24, 12),
          control2: Offset(40, 52),
          end: Offset(52, 52),
        ),
      ],
    );

    Future<int> paintedAlpha(StoryPathGeometry value) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      StoryPathPainter(
        sceneTheme: GalleryTheme.ink,
        geometry: value,
      ).paint(canvas, const Size(64, 64));
      final image = await recorder.endRecording().toImage(64, 64);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      var alpha = 0;
      final pixels = bytes!.buffer.asUint8List();
      for (var index = 3; index < pixels.length; index += 4) {
        alpha += pixels[index];
      }
      return alpha;
    }

    expect(await paintedAlpha(geometry), greaterThan(0));
    expect(await paintedAlpha(const StoryPathGeometry.empty()), 0);
  });

  test('story label defaults to the right of its anchor', () {
    const anchor = StoryPathAnchor(
      placementId: 'p0',
      point: Offset(100, 100),
      nodeRect: Rect.fromLTWH(0, 0, 50, 50),
    );

    final rect = resolveStoryLabelRect(
      anchor: anchor,
      viewport: const Size(390, 844),
    );

    expect(rect, const Rect.fromLTWH(108, 85, 92, 30));
  });

  test('story label flips left when its right position overlaps the node', () {
    const anchor = StoryPathAnchor(
      placementId: 'p0',
      point: Offset(100, 100),
      nodeRect: Rect.fromLTWH(105, 70, 120, 80),
    );

    final rect = resolveStoryLabelRect(
      anchor: anchor,
      viewport: const Size(390, 844),
    );

    expect(rect, const Rect.fromLTWH(8, 85, 92, 30));
  });

  test('story label stays inside the viewport margin', () {
    const anchor = StoryPathAnchor(
      placementId: 'p0',
      point: Offset(388, 840),
      nodeRect: Rect.fromLTWH(0, 0, 20, 20),
    );

    final rect = resolveStoryLabelRect(
      anchor: anchor,
      viewport: const Size(390, 844),
    );

    expect(rect, const Rect.fromLTWH(290, 806, 92, 30));
  });

  test('story label compares overlap after clamping both candidates', () {
    const viewport = Size(390, 844);
    const anchor = StoryPathAnchor(
      placementId: 'p0',
      point: Offset(380, 100),
      nodeRect: Rect.fromLTWH(374, 70, 12, 80),
    );

    final rect = resolveStoryLabelRect(anchor: anchor, viewport: viewport);

    expect(rect, const Rect.fromLTWH(280, 85, 92, 30));
    expect(rect.overlaps(anchor.nodeRect), isFalse);
    expect(rect.left, greaterThanOrEqualTo(8));
    expect(rect.right, lessThanOrEqualTo(viewport.width - 8));
  });

  test(
    'story label chooses the smaller overlap when neither side is clear',
    () {
      const anchor = StoryPathAnchor(
        placementId: 'p0',
        point: Offset(380, 100),
        nodeRect: Rect.fromLTWH(280, 70, 90, 80),
      );

      final rect = resolveStoryLabelRect(
        anchor: anchor,
        viewport: const Size(390, 844),
      );

      expect(rect, const Rect.fromLTWH(290, 85, 92, 30));
    },
  );

  testWidgets('story path and labels follow entrance motion', (tester) async {
    const storyChapter = GalleryChapter(
      id: 'story-motion',
      title: 'Story',
      order: 0,
      layout: GalleryLayout.storyPath,
      motion: GalleryMotion.push,
      placements: [
        GalleryPlacement(
          id: 'p0',
          mediaId: 'media',
          order: 0,
          caption: 'motion-label',
        ),
        GalleryPlacement(id: 'p1', mediaId: 'media', order: 1),
        GalleryPlacement(id: 'p2', mediaId: 'media', order: 2),
        GalleryPlacement(id: 'p3', mediaId: 'media', order: 3),
      ],
    );

    Future<void> pumpAt(double progress) => tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: SceneCanvas(
            chapter: storyChapter,
            media: const [media],
            cameraProgress: .35,
            progress: progress,
          ),
        ),
      ),
    );

    await pumpAt(0);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('story-path-opacity')))
          .opacity,
      0,
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('story-label-opacity-p0')))
          .opacity,
      0,
    );

    await pumpAt(1);
    final settledPainter =
        tester
                .widget<CustomPaint>(find.byKey(const Key('story-path-line')))
                .painter!
            as StoryPathPainter;
    final settledPoint = settledPainter.geometry.anchors.first.point;
    final settledLabel = tester.getTopLeft(find.textContaining('motion-label'));

    await pumpAt(.5);
    final movingPainter =
        tester
                .widget<CustomPaint>(find.byKey(const Key('story-path-line')))
                .painter!
            as StoryPathPainter;
    final movingPoint = movingPainter.geometry.anchors.first.point;
    final movingLabel = tester.getTopLeft(find.textContaining('motion-label'));

    expect(movingPoint.dy, greaterThan(settledPoint.dy));
    expect(movingLabel.dy, greaterThan(settledLabel.dy));
  });

  test('story geometry applies motion around each node center', () {
    final geometry = StoryPathGeometry(
      anchors: const [
        StoryPathAnchor(
          placementId: 'p0',
          point: Offset(110, 100),
          nodeRect: Rect.fromLTWH(90, 90, 20, 20),
        ),
      ],
      segments: const [],
    );

    final transformed = transformStoryPathGeometry(
      geometry: geometry,
      motion: MotionFrame(
        offset: const Offset(.1, .2),
        scale: .5,
        rotation: math.pi / 2,
      ),
      viewport: const Size(200, 200),
    );

    expect(transformed.anchors.single.point.dx, closeTo(120, .0001));
    expect(transformed.anchors.single.point.dy, closeTo(145, .0001));
    expect(
      transformed.anchors.single.nodeRect,
      const Rect.fromLTWH(115, 135, 10, 10),
    );
  });
}
