import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/layout/floating_panel_position.dart';

void main() {
  test(
    'landscape panel can move horizontally without leaving the viewport',
    () {
      expect(
        clampFloatingPanelLeft(
          viewportWidth: 900,
          panelWidth: 340,
          desiredLeft: 420,
        ),
        420,
      );
      expect(
        clampFloatingPanelLeft(
          viewportWidth: 900,
          panelWidth: 340,
          desiredLeft: -100,
        ),
        8,
      );
      expect(
        clampFloatingPanelLeft(
          viewportWidth: 900,
          panelWidth: 340,
          desiredLeft: 800,
        ),
        552,
      );
    },
  );
}
