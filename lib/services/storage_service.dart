import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final photoId = _uuid.v4();
    final ref = _storage.ref().child('users/$userId/photos/$photoId.jpg');

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deletePhoto(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Ignore if photo doesn't exist
    }
  }

  Future<List<String>> uploadMultiplePhotos(
    String userId,
    List<File> imageFiles,
  ) async {
    final futures = imageFiles.map((f) => uploadProfilePhoto(userId, f));
    return Future.wait(futures);
  }
}
