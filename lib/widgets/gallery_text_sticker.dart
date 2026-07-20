import 'package:flutter/material.dart';
import 'package:xulang/domain/gallery_document.dart';

const galleryTextStickerColors = <int>[
  0xFF2C241B,
  0xFF6F442A,
  0xFFA8692F,
  0xFFF0E5D2,
  0xFF5E6B4E,
  0xFF536775,
  0xFF202221,
];

String? galleryTextFontFamily(GalleryTextFont font) => switch (font) {
  GalleryTextFont.system => null,
  GalleryTextFont.editorial => 'Xulang Editorial',
  GalleryTextFont.handwriting => 'Xulang Handwriting',
  GalleryTextFont.brush => 'Xulang Brush',
};

TextStyle galleryTextStickerStyle(GallerySticker sticker) => TextStyle(
  color: Color(sticker.textColor),
  fontFamily: galleryTextFontFamily(sticker.textFont),
  fontFamilyFallback: const [
    'Noto Serif SC',
    'Source Han Serif SC',
    'STSong',
    'serif',
  ],
  fontSize: 27 * sticker.scale.clamp(.6, 2.4),
  height: 1.22,
  letterSpacing: sticker.textFont == GalleryTextFont.brush ? 1.2 : .4,
  shadows: const [
    Shadow(color: Color(0x2BFFF8EA), blurRadius: 1.5, offset: Offset(0, 1)),
  ],
);

Size measureGalleryTextSticker(GallerySticker sticker) {
  final scale = sticker.scale.clamp(.6, 2.4);
  final painter = TextPainter(
    text: TextSpan(
      text: sticker.text.trim(),
      style: galleryTextStickerStyle(sticker),
    ),
    maxLines: 3,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    ellipsis: '…',
  )..layout(minWidth: 72 * scale, maxWidth: 240 * scale);
  return Size(painter.width + 12 * scale, painter.height + 8 * scale);
}

class GalleryTextStickerView extends StatelessWidget {
  const GalleryTextStickerView({
    super.key,
    required this.sticker,
    this.textAlign = TextAlign.center,
  });

  final GallerySticker sticker;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final size = measureGalleryTextSticker(sticker);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
        child: Text(
          sticker.text.trim(),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: galleryTextStickerStyle(sticker),
        ),
      ),
    );
  }
}
