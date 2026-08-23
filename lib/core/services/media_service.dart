import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaService {
  static final MediaService instance = MediaService._();
  MediaService._();

  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery, permanently saves it to the app storage directory,
  /// and returns its local file path.
  Future<String?> pickAndPersistImageFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return null;
      return await _persistImageFile(picked);
    } catch (e) {
      return null;
    }
  }

  /// Takes a photo using the camera, permanently saves it, and returns its local file path.
  Future<String?> pickAndPersistImageFromCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (picked == null) return null;
      return await _persistImageFile(picked);
    } catch (e) {
      return null;
    }
  }

  /// Copies an XFile to local permanent documents storage
  Future<String> _persistImageFile(XFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/null_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final extension = file.path.contains('.') ? file.path.split('.').last : 'jpg';
    final fileName = 'null_img_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final targetPath = '${mediaDir.path}/$fileName';

    final savedFile = await File(file.path).copy(targetPath);
    return savedFile.path;
  }

  /// Deletes a cached image file if exists
  Future<void> deleteMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
