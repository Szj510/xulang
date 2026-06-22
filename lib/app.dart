import 'package:flutter/material.dart';
import 'package:xulang/screens/library_screen.dart';
import 'package:xulang/theme/xulang_theme.dart';

class XulangApp extends StatelessWidget {
  const XulangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '叙廊',
      debugShowCheckedModeBanner: false,
      theme: buildXulangTheme(),
      home: const LibraryScreen(),
    );
  }
}
