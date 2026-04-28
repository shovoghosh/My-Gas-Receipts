import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> captureAndSaveReceipt() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      imageQuality: 85,
    );

    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(dir.path, fileName);

    final result = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      targetPath,
      quality: 70,
      minWidth: 1200,
      rotate: 0,
    );

    return result?.path;
  }

  Future<String?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 85,
    );

    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(dir.path, fileName);

    final result = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      targetPath,
      quality: 70,
      minWidth: 1200,
      rotate: 0,
    );

    return result?.path;
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
