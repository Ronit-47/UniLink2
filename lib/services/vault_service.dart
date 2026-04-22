import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VaultService {
  // Initialize the Supabase client
  final supabase = Supabase.instance.client;

  // Handles the file picker, storage upload, and database insert
  Future<String?> uploadStudyMaterial({
    required String academicYear,
    required String branch,
    required String subject,
    required String topic,
  }) async {
    try {
      // 1. Pick the file (PDF or DOCX)
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null) {
        return "Upload cancelled.";
      }

      File file = File(result.files.single.path!);
      String originalFileName = result.files.single.name;
      String userId = supabase.auth.currentUser!.id;

      // --- CUSTOM FILE NAMING LOGIC ---
      // Extract the extension (e.g., 'pdf')
      String extension = originalFileName.split('.').last;

      // Clean up spaces in subject and topic to prevent broken URLs
      String cleanSubject = subject.replaceAll(' ', '_');
      String cleanTopic = topic.replaceAll(' ', '_');

      // Create the new custom name: e.g., "Logic_Devices_Unit_1_Notes.pdf"
      String customFileName = '${cleanSubject}_$cleanTopic.$extension';

      // 2. Upload to Supabase Storage bucket named 'vault'
      final storagePath = '$academicYear/$branch/$customFileName';
      await supabase.storage.from('vault').upload(
        storagePath,
        file,
      );

      // 3. Get the public URL for downloading later
      final fileUrl = supabase.storage.from('vault').getPublicUrl(storagePath);

      // 4. Save the record to your PostgreSQL database
      await supabase.from('vault_files').insert({
        'academic_year': academicYear,
        'branch': branch,
        'subject': subject,
        'topic': topic,
        'file_name': customFileName, // Now saves the custom name!
        'file_url': fileUrl,
        'uploader_id': userId,       // Matches your table column exactly!
      });

      return null; // Returning null means success (no errors)
    } catch (e) {
      print("Upload error: $e");
      return e.toString();
    }
  }

  // Fetches files based on Year, Branch, and Search Query
  Future<List<dynamic>> fetchVaultFiles(String year, String branch, String searchQuery) async {
    try {
      var query = supabase
          .from('vault_files')
          .select('*, profiles(full_name)')
          .eq('academic_year', year);

      if (branch != 'All') {
        query = query.eq('branch', branch);
      }

      if (searchQuery.isNotEmpty) {
        // Split the search query by spaces or underscores
        final keywords = searchQuery.split(RegExp(r'[\s_]+'));

        // Build a dynamic search string for Supabase
        // This makes sure EVERY keyword must exist somewhere in the row
        for (String keyword in keywords) {
          if (keyword.isNotEmpty) {
            query = query.or('subject.ilike.%$keyword%,topic.ilike.%$keyword%,file_name.ilike.%$keyword%');
          }
        }
      }

      // Supabase returns a List of Maps by default
      final response = await query;
      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }
}