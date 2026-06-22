import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/narrative_axis.dart';

void main() {
  test('chooses the primary axis from viewport orientation', () {
    expect(
      NarrativeAxis.fromViewport(const Size(390, 844)),
      NarrativeAxis.vertical,
    );
    expect(
      NarrativeAxis.fromViewport(const Size(844, 390)),
      NarrativeAxis.horizontal,
    );
  });

  test('projects offsets and extents onto vertical coordinates', () {
    const axis = NarrativeAxis.vertical;

    expect(axis.primaryOffset(const Offset(4, 9)), 9);
    expect(axis.crossOffset(const Offset(4, 9)), 4);
    expect(axis.primaryExtent(const Size(12, 18)), 18);
    expect(axis.crossExtent(const Size(12, 18)), 12);
    expect(axis.shiftPrimary(const Offset(4, 9), 3), const Offset(4, 12));
  });

  test('projects offsets and extents onto horizontal coordinates', () {
    const axis = NarrativeAxis.horizontal;

    expect(axis.primaryOffset(const Offset(4, 9)), 4);
    expect(axis.crossOffset(const Offset(4, 9)), 9);
    expect(axis.primaryExtent(const Size(12, 18)), 12);
    expect(axis.crossExtent(const Size(12, 18)), 18);
    expect(axis.shiftPrimary(const Offset(4, 9), 3), const Offset(7, 9));
  });
}
