import 'dart:io';
import 'package:finsight/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
 // final SupabaseClient _client = Supabase.instance.client;


/*  Future<String?> uploadCasFile(String filePath) async {
    try {

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File not found at $filePath");
      }

      var fileSize= await file.length();
      print("FILE SIZE:"+fileSize.toString());
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final storagePath = 'cas_uploads/$fileName';
      print("Storage Path:" +storagePath);

      // Upload file to the "documents" bucket

     var bucket= await  supabase.storage.listBuckets();
     print("Bucket Details:" +bucket.length.toString());


     *//*var data= await _client.storage.from("cas_docs").upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: false),
          );

     print("Uploaded:" +data);

      // Extract the public URL
      final publicUrl = _client.storage.from('cas_docs').getPublicUrl(storagePath);
      print("Public URL:" +publicUrl);
      return publicUrl;*//*
    } on StorageException catch (e) {
      String customMessage = 'Storage Error: ${e.message}';
      if (e.statusCode == '404') {
        customMessage = 'Bucket "cas_docs" not found. Please ensure it exists and is lowercase in your Supabase dashboard.' +'${e}';
      } else if (e.statusCode == '403') {
        customMessage = 'Permission denied. Please ensure you have an RLS policy allowing "anon" uploads to the "cas_docs" bucket.';
      }
      
      print("Storage Exception: $customMessage");
      throw Exception(customMessage);
    } catch (e) {
      print("Exception: " +e.toString());
      throw Exception('Upload Failed: $e');
    }
  }*/
}
