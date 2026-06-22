import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';
import 'package:xulang/layout/narrative_camera_controller.dart';

void main() {
  test('portrait drag advances progress on the vertical axis', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(2, -84),
      viewport: const Size(390, 840),
      itemCount: 5,
      scale: 1,
      axis: NarrativeAxis.vertical,
    );

    expect(controller.progress, closeTo(.425, .000001));
    expect(controller.direction, GalleryGesture.vertical);
  });

  test('landscape drag advances progress on the horizontal axis', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(-84, 2),
      viewport: const Size(840, 390),
      itemCount: 5,
      scale: 1,
      axis: NarrativeAxis.horizontal,
    );

    expect(controller.progress, closeTo(.425, .000001));
    expect(controller.direction, GalleryGesture.horizontal);
  });

  test('vertical mode ignores a clearly horizontal gesture', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(-84, 2),
      viewport: const Size(390, 840),
      itemCount: 5,
      scale: 1,
      axis: NarrativeAxis.vertical,
    );

    expect(controller.progress, .4);
    expect(controller.direction, GalleryGesture.horizontal);
  });

  test('waits for eight logical pixels before moving the camera', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(0, -7),
      viewport: const Size(390, 840),
      itemCount: 5,
      scale: 1,
      axis: NarrativeAxis.vertical,
    );

    expect(controller.progress, .4);
    expect(controller.direction, GalleryGesture.undecided);

    controller.update(
      delta: const Offset(0, -1),
      viewport: const Size(390, 840),
      itemCount: 5,
      scale: 1,
      axis: NarrativeAxis.vertical,
    );

    expect(controller.progress, greaterThan(.4));
    expect(controller.direction, GalleryGesture.vertical);
  });

  test('zoomed content reserves movement for image panning', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1.5);

    controller.update(
      delta: const Offset(0, -120),
      viewport: const Size(390, 840),
      itemCount: 5,
      scale: 1.5,
      axis: NarrativeAxis.vertical,
    );

    expect(controller.progress, .4);
    expect(controller.direction, GalleryGesture.pan);
  });

  test('progress is clamped and vertical velocity creates forward inertia', () {
    final controller = NarrativeCameraController(initialProgress: .96);
    controller.setProgress(2);
    expect(controller.progress, 1);
    controller.setProgress(.5);

    final simulation = controller.simulationForVelocity(
      pixelsPerSecond: -840,
      viewport: const Size(390, 840),
      itemCount: 5,
      axis: NarrativeAxis.vertical,
    );

    expect(simulation.x(.2), greaterThan(.5));
    expect(
      controller.clampSimulationValue(simulation.x(10)),
      inInclusiveRange(0, 1),
    );
  });

  test('zero primary extent is safe for updates and inertia', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(0, -84),
      viewport: const Size(390, 0),
      itemCount: 5,
      scale: 1,
      axis: NarrativeAxis.vertical,
    );
    final simulation = controller.simulationForVelocity(
      pixelsPerSecond: -840,
      viewport: const Size(390, 0),
      itemCount: 5,
      axis: NarrativeAxis.vertical,
    );

    expect(controller.progress, .4);
    expect(simulation.dx(0), 0);
    expect(simulation.x(.2), .4);
  });
}
