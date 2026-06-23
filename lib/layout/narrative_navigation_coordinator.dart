import 'dart:ui';

import 'package:xulang/layout/gesture_direction_lock.dart';
import 'package:xulang/layout/narrative_axis.dart';

enum ChapterNavigationIntent { none, previous, next }

class NarrativeNavigationCoordinator {
  static const double threshold = 56;

  NarrativeAxis _axis = NarrativeAxis.vertical;
  double _primary = 0;
  double _cross = 0;
  bool _startArmed = false;
  bool _endArmed = false;
  bool _dispatched = false;
  bool _active = false;

  void begin({
    required double progress,
    required NarrativeAxis axis,
    required int itemCount,
  }) {
    _axis = axis;
    _primary = 0;
    _cross = 0;
    _startArmed = itemCount <= 1 || progress <= .001;
    _endArmed = itemCount <= 1 || progress >= .999;
    _dispatched = false;
    _active = true;
  }

  ChapterNavigationIntent update(Offset delta, GalleryGesture gesture) {
    if (!_active || _dispatched) return ChapterNavigationIntent.none;

    if (_axis == NarrativeAxis.horizontal &&
        gesture == GalleryGesture.vertical) {
      _cross += _axis.crossOffset(delta);
      return _dispatchForDistance(_cross, startArmed: true, endArmed: true);
    }

    final matchesAxis = switch (_axis) {
      NarrativeAxis.vertical => gesture == GalleryGesture.vertical,
      NarrativeAxis.horizontal => gesture == GalleryGesture.horizontal,
    };
    if (!matchesAxis) return ChapterNavigationIntent.none;

    _primary += _axis.primaryOffset(delta);
    return _dispatchForDistance(
      _primary,
      startArmed: _startArmed,
      endArmed: _endArmed,
    );
  }

  ChapterNavigationIntent _dispatchForDistance(
    double distance, {
    required bool startArmed,
    required bool endArmed,
  }) {
    final intent = switch (distance) {
      < -threshold when endArmed => ChapterNavigationIntent.next,
      > threshold when startArmed => ChapterNavigationIntent.previous,
      _ => ChapterNavigationIntent.none,
    };
    if (intent != ChapterNavigationIntent.none) _dispatched = true;
    return intent;
  }

  void end() {
    _primary = 0;
    _cross = 0;
    _active = false;
  }
}
