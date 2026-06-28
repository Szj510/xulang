import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/l10n/app_strings.dart';
import 'package:xulang/providers/app_providers.dart';
import 'package:xulang/screens/library_screen.dart';
import 'package:xulang/theme/xulang_theme.dart';

class XulangApp extends ConsumerWidget {
  const XulangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const AppSettings());
    return MaterialApp(
      title: AppStrings.from(settings).appTitle,
      locale: settings.language.toLocale(),
      supportedLocales: const [Locale('zh'), Locale('en')],
      debugShowCheckedModeBanner: false,
      theme: buildXulangTheme(),
      home: const LibraryScreen(),
    );
  }
}
