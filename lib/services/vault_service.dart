import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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

  // Store the last error for debugging
  String? lastFetchError;

  // Fetches files based on Year, Branch, and Search Query
  Future<List<dynamic>> fetchVaultFiles(String year, String branch, String searchQuery) async {
    lastFetchError = null;
    try {
      print("📂 VAULT: Fetching files for year=$year, branch=$branch, search='$searchQuery'");

      var query = supabase
          .from('vault_files')
          .select()
          .eq('academic_year', year);

      if (branch != 'All') {
        query = query.eq('branch', branch);
      }

      if (searchQuery.isNotEmpty) {
        final keywords = searchQuery.split(RegExp(r'[\s_]+'));
        for (String keyword in keywords) {
          if (keyword.isNotEmpty) {
            query = query.or('subject.ilike.%$keyword%,topic.ilike.%$keyword%,file_name.ilike.%$keyword%');
          }
        }
      }

      final List<dynamic> files = await query;
      print("✅ VAULT: Fetched ${files.length} files.");

      if (files.isEmpty) return [];

      // Fetch uploader names separately to avoid join issues
      try {
        final uploaderIds = files
            .map((f) => f['uploader_id']?.toString())
            .where((id) => id != null)
            .toSet()
            .toList();

        if (uploaderIds.isNotEmpty) {
          final profilesResponse = await supabase
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', uploaderIds);

          final Map<String, String> nameMap = {};
          for (final p in (profilesResponse as List)) {
            nameMap[p['id'].toString()] = p['full_name'] ?? 'Unknown';
          }

          for (final file in files) {
            final uid = file['uploader_id']?.toString();
            file['profiles'] = {'full_name': nameMap[uid] ?? 'Unknown Student'};
          }
        }
      } catch (profileError) {
        print("⚠️ VAULT: Could not fetch uploader names (non-fatal): $profileError");
        for (final file in files) {
          file['profiles'] = {'full_name': 'Unknown Student'};
        }
      }

      return files;
    } catch (e) {
      lastFetchError = e.toString();
      print("❌ VAULT FETCH ERROR: $e");
      return [];
    }
  }
  // --- NEW DOWNLOAD METHOD ---
  Future<String> downloadStudyMaterial(String url, String fileName) async {
    try {
      // 1. Find the laptop's default 'Downloads' folder
      Directory? downloadsDir = await getDownloadsDirectory();

      if (downloadsDir == null) {
        return "Error: Could not find Downloads folder.";
      }

      // 2. Create the exact path where the file will be saved
      // Platform.pathSeparator handles Windows (\) vs Mac/Linux (/) automatically
      String savePath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';

      // 3. Fetch the file data directly from the Supabase URL
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 4. Create the file and write the downloaded bytes into it
        File file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return "Success: Saved to Downloads folder!";
      } else {
        return "Error: Failed to download from server.";
      }
    } catch (e) {
      print("Download error: $e");
      return "Error: Something went wrong.";
    }
  }
}