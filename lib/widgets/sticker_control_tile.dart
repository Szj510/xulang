import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/theme/xulang_theme.dart';
import 'package:xulang/widgets/atmospheric_sticker.dart';

class StickerControlTile extends StatelessWidget {
  const StickerControlTile({
    super.key,
    required this.sticker,
    required this.label,
    required this.onRotationChanged,
  });

  final GallerySticker sticker;
  final String label;
  final ValueChanged<double> onRotationChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings.of(context);
    final degrees = sticker.rotation * 180 / math.pi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AtmosphericSticker(
                    kind: sticker.kind,
                    size: 28,
                    rotation: sticker.rotation,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label)),
                  Text(
                    '${degrees.round()}°',
                    style: const TextStyle(
                      fontSize: 11,
                      color: XulangColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      l10n.stickerRotation,
                      style: const TextStyle(
                        fontSize: 11,
                        color: XulangColors.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: Key('editor-sticker-rotation-${sticker.id}'),
                      value: degrees.clamp(-180, 180).toDouble(),
                      min: -180,
                      max: 180,
                      divisions: 72,
                      label: '${degrees.round()}°',
                      onChanged: onRotationChanged,
                    ),
                  ),
                ],
              ),
              Text(
                l10n.deleteStickerOnCanvas,
                style: const TextStyle(fontSize: 11, color: XulangColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
