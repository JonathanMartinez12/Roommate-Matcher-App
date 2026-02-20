import 'dart:io';

/// Stub storage service — no Firebase Storage in the mock build.
/// Photo uploads return empty string; the UI falls back to initials.
class StorageService {
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '';
  }

  Future<void> deletePhoto(String downloadUrl) async {}

  Future<List<String>> uploadMultiplePhotos(
    String userId,
    List<File> imageFiles,
  ) async {
    return [];
  }
}
