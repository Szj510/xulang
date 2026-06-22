import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_camera_controller.dart';

void main() {
  test('horizontal drag changes progress continuously without snapping', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(-78, 2),
      viewport: const Size(390, 844),
      itemCount: 5,
      scale: 1,
    );

    expect(controller.progress, closeTo(.45, .001));
    expect(controller.direction, GalleryGesture.horizontal);
  });

  test('waits for eight logical pixels before moving the camera', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1);

    controller.update(
      delta: const Offset(-5, 1),
      viewport: const Size(390, 844),
      itemCount: 5,
      scale: 1,
    );

    expect(controller.progress, .4);
    expect(controller.direction, GalleryGesture.undecided);
  });

  test('zoomed content reserves movement for image panning', () {
    final controller = NarrativeCameraController(initialProgress: .4);
    controller.begin(scale: 1.5);

    controller.update(
      delta: const Offset(-120, 0),
      viewport: const Size(390, 844),
      itemCount: 5,
      scale: 1.5,
    );

    expect(controller.progress, .4);
    expect(controller.direction, GalleryGesture.pan);
  });

  test('progress is clamped and velocity creates forward inertia', () {
    final controller = NarrativeCameraController(initialProgress: .96);
    controller.setProgress(2);
    expect(controller.progress, 1);
    controller.setProgress(.5);

    final simulation = controller.simulationForVelocity(
      pixelsPerSecond: -780,
      viewportWidth: 390,
      itemCount: 5,
    );

    expect(simulation.x(.2), greaterThan(.5));
    expect(
      controller.clampSimulationValue(simulation.x(10)),
      inInclusiveRange(0, 1),
    );
  });
}
