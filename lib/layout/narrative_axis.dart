import 'package:flutter/widgets.dart';
import 'package:xulang/domain/gallery_document.dart';

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

  Rect shiftPrimary(Rect rect, double distance) => switch (this) {
    vertical => rect.shift(Offset(0, distance)),
    horizontal => rect.shift(Offset(distance, 0)),
  };
}

NarrativeAxis editorCameraAxisForLayout(GalleryLayout layout) =>
    layout == GalleryLayout.storyPath
    ? NarrativeAxis.vertical
    : NarrativeAxis.horizontal;
