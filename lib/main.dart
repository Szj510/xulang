import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xulang/app.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/data/sample_gallery.dart';
import 'package:xulang/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final repository = GalleryRepository(
    database: GalleryDatabase(),
    mediaRoot: Directory(p.join(support.path, 'media')),
    createId: () => const Uuid().v7(),
  );
  if (const bool.fromEnvironment('XULANG_DEMO')) {
    final existing = await repository.load('sample-exhibition');
    if (existing == null) {
      await repository.save(buildSampleGallery(DateTime.now()));
    }
  }
  runApp(
    ProviderScope(
      overrides: [galleryRepositoryProvider.overrideWithValue(repository)],
      child: const XulangApp(),
    ),
  );
}
