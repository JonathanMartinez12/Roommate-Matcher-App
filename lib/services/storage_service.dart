import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════════════
// StorageService
//
// Wraps Firebase Storage for profile photo management.
// All uploads use the path: profile_photos/{userId}/{filename}
// Download URLs are stored in UserModel.photoUrls via FirestoreService.
// ═══════════════════════════════════════════════════════════════════════════

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads a single photo and returns its public download URL.
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final fileName =
        'photo_${DateTime.now().millisecondsSinceEpoch}${_ext(imageFile.path)}';
    final ref =
        _storage.ref().child('profile_photos/$userId/$fileName');
    final task = await ref.putFile(imageFile);
    return task.ref.getDownloadURL();
  }

  /// Uploads multiple photos concurrently and returns their download URLs
  /// in the same order as the input list.
  Future<List<String>> uploadMultiplePhotos(
    String userId,
    List<File> imageFiles,
  ) async {
    final futures = imageFiles
        .map((f) => uploadProfilePhoto(userId, f))
        .toList();
    return Future.wait(futures);
  }

  /// Deletes a photo by its download URL.
  Future<void> deletePhoto(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {
      // Ignore — file may already be deleted or URL may be external.
    }
  }

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot != -1 ? path.substring(dot) : '.jpg';
  }
}

final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);
