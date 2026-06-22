import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';

class NarrativeCameraController extends ChangeNotifier {
  NarrativeCameraController({double initialProgress = 0})
    : progress = initialProgress.clamp(0, 1);

  final GestureDirectionLock _directionLock = GestureDirectionLock();

  double progress;
  double scale = 1;

  GalleryGesture get direction => _directionLock.gesture;
  bool get navigationEnabled => scale <= 1.01;

  void begin({required double scale}) {
    this.scale = scale;
    _directionLock.begin(scale: scale);
  }

  GalleryGesture update({
    required Offset delta,
    required Size viewport,
    required int itemCount,
    required double scale,
    required NarrativeAxis axis,
  }) {
    this.scale = scale;
    final gesture = _directionLock.update(delta, scale: scale);
    final expectedGesture = axis == NarrativeAxis.vertical
        ? GalleryGesture.vertical
        : GalleryGesture.horizontal;
    final extent = axis.primaryExtent(viewport);
    if (gesture != expectedGesture || extent <= 0) {
      return gesture;
    }
    final dragSpan = math.max(1, itemCount - 1).toDouble();
    setProgress(progress - axis.primaryOffset(delta) / extent / dragSpan);
    return gesture;
  }

  void end() => _directionLock.end();

  void setScale(double value) {
    if ((scale - value).abs() < .001) return;
    scale = value;
    notifyListeners();
  }

  void setProgress(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((progress - next).abs() < .000001) return;
    progress = next;
    notifyListeners();
  }

  void resetOverview() => setProgress(0);

  FrictionSimulation simulationForVelocity({
    required double pixelsPerSecond,
    required Size viewport,
    required int itemCount,
    required NarrativeAxis axis,
  }) {
    final dragSpan = math.max(1, itemCount - 1).toDouble();
    final extent = axis.primaryExtent(viewport);
    final progressVelocity = extent <= 0
        ? 0.0
        : -pixelsPerSecond / extent / dragSpan;
    return FrictionSimulation(.135, progress, progressVelocity);
  }

  double clampSimulationValue(double value) => value.clamp(0.0, 1.0);
}
