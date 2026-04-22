import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class VaultService {
  final supabase = Supabase.instance.client;

  // 1. UPLOAD A FILE
  Future<String?> uploadStudyMaterial({
    required String academicYear,
    required String subject,
    required String topic,
  }) async {
    try {
      // Step A: Open the phone's file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'txt'], // Only allow study formats
      );

      // If they closed the picker without selecting anything
      if (result == null) return "Upload cancelled.";

      // Step B: Prepare the file
      File file = File(result.files.single.path!);
      String originalName = result.files.single.name;

      // We add a timestamp to the filename so if two people upload "Unit1.pdf", it doesn't overwrite!
      String safeFileName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';
      String userId = supabase.auth.currentUser!.id;

      // Step C: Upload the heavy file to the 'vault' Storage Bucket
      await supabase.storage.from('vault').upload(safeFileName, file);

      // Step D: Get the public URL for the newly uploaded file
      final fileUrl = supabase.storage.from('vault').getPublicUrl(safeFileName);

      // Step E: Save the details and the URL to our relational Database table
      await supabase.from('vault_files').insert({
        'uploader_id': userId,
        'academic_year': academicYear,
        'subject': subject.trim(),
        'topic': topic.trim(),
        'file_name': originalName,
        'file_url': fileUrl,
      });

      return null; // Success!
    } catch (e) {
      return "Error uploading file: $e";
    }
  }

  // 2. FETCH FILES BASED ON YEAR
  Future<List<dynamic>> fetchVaultFiles(String year) async {
    try {
      // We use the same 'Profiles' join hack to show who uploaded it!
      final response = await supabase
          .from('vault_files')
          .select('*, profiles(full_name)')
          .eq('academic_year', year)
          .order('created_at', ascending: false);

      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }
}