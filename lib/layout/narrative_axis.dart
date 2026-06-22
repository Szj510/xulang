import 'package:flutter/widgets.dart';

enum NarrativeAxis {
  vertical,
  horizontal;

  factory NarrativeAxis.fromViewport(Size viewport) =>
      viewport.height >= viewport.width ? vertical : horizontal;

  double primaryOffset(Offset offset) => switch (this) {
    vertical => offset.dy,
    horizontal => offset.dx,
  };

  double crossOffset(Offset offset) => switch (this) {
    vertical => offset.dx,
    horizontal => offset.dy,
  };

  double primaryExtent(Size size) => switch (this) {
    vertical => size.height,
    horizontal => size.width,
  };

  double crossExtent(Size size) => switch (this) {
    vertical => size.width,
    horizontal => size.height,
  };

  Offset shiftPrimary(Offset offset, double distance) => switch (this) {
    vertical => offset.translate(0, distance),
    horizontal => offset.translate(distance, 0),
  };
}
