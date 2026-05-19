import 'dart:io';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

import '../env/env.dart';

class CloudinaryService {
  late final Cloudinary _cloudinary;

  CloudinaryService() {
    // Initializing Cloudinary using the modular SDK pattern
    _cloudinary = Cloudinary.fromStringUrl(
      'cloudinary://${Env.cloudinaryAPIKey}:${Env.cloudinarySecretKey}@${Env.cloudinaryName}'
    );
  }

  /// Uploads a file to Cloudinary.
  /// [filePath] is the local path of the file to be uploaded.
  /// Returns the secure URL of the uploaded file if successful, null otherwise.
  Future<String?> uploadFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File not found at $filePath");
      }

      // Using the uploader from cloudinary_api
      final response = await _cloudinary.uploader().upload(
        file,
        params: UploadParams(
          folder: 'cas_uploads',
          resourceType: 'raw', // Important for PDF files
        ),
      );

      if (response != null && response.data != null && response.data!.secureUrl != null) {

        final secureUrl = response.data!.secureUrl;
        print('Cloudinary Upload Successful: $secureUrl');
        return secureUrl;
      } else {
        final error = response?.error?.message ?? 'Unknown error';
        print('Cloudinary Upload Failed: $error');
        throw Exception('Cloudinary Upload Failed: $error');
      }
    } catch (e) {
      print('Cloudinary Service Error: $e');
      rethrow;
    }
  }
}
