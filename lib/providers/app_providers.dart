import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xulang/data/document_access_service.dart';
import 'package:xulang/data/gallery_database.dart';
import 'package:xulang/data/gallery_repository.dart';
import 'package:xulang/data/image_selection_service.dart';
import 'package:xulang/data/media_import_service.dart';
import 'package:xulang/domain/gallery_document.dart';
import 'package:xulang/editor/editor_session.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  throw StateError(
    'GalleryRepository must be provided at application startup.',
  );
});

final mediaImportServiceProvider = Provider<MediaImportService>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return MediaImportService(
    rootDirectory: repository.mediaRoot,
    createId: repository.createId,
  );
});

final documentAccessServiceProvider = Provider<DocumentAccessService>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return DocumentAccessService(mediaRoot: repository.mediaRoot);
});

final imageSelectionServiceProvider = Provider<ImageSelectionService>((ref) {
  return SystemImageSelectionService(ImagePicker());
});

final exhibitionSummariesProvider = StreamProvider<List<ExhibitionSummary>>((
  ref,
) {
  return ref.watch(galleryRepositoryProvider).watchExhibitions();
});

final exhibitionCategoriesProvider = StreamProvider<List<GalleryCategoryInfo>>((
  ref,
) {
  return ref.watch(galleryRepositoryProvider).watchCategories();
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(galleryRepositoryProvider).watchAppSettings();
});

final editorSessionProvider = Provider.autoDispose
    .family<EditorSession, String>((ref, exhibitionId) {
      final session = EditorSession(
        exhibitionId: exhibitionId,
        repository: ref.watch(galleryRepositoryProvider),
        importer: ref.watch(mediaImportServiceProvider),
        imageSelection: ref.watch(imageSelectionServiceProvider),
      );
      ref.onDispose(session.dispose);
      return session;
    });
