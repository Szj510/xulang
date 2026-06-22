import 'package:image_picker/image_picker.dart';

abstract class ImageSelectionService {
  Future<List<String>> selectImages();
}

class SystemImageSelectionService implements ImageSelectionService {
  SystemImageSelectionService(this._picker);

  final ImagePicker _picker;

  @override
  Future<List<String>> selectImages() async {
    final files = await _picker.pickMultiImage(requestFullMetadata: false);
    return files.map((file) => file.path).toList(growable: false);
  }
}
