double clampFloatingPanelLeft({
  required double viewportWidth,
  required double panelWidth,
  required double desiredLeft,
  double margin = 8,
}) {
  final minimum = margin;
  final maximum = (viewportWidth - panelWidth - margin).clamp(
    minimum,
    viewportWidth,
  );
  return desiredLeft.clamp(minimum, maximum).toDouble();
}
