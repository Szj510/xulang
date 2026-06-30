import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/widgets/sticker_control_tile.dart';

void main() {
  testWidgets('sticker control tile localizes action labels in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: StickerControlTile(
            sticker: const GallerySticker(
              id: 'sticker-1',
              kind: GalleryStickerKind.star,
              x: 0.5,
              y: 0.5,
            ),
            label: 'Star mark',
            onRotationChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Rotation'), findsOneWidget);
    expect(find.text('Tap the cross on the canvas to delete'), findsOneWidget);
  });
}
