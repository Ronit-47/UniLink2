import 'package:flutter/material.dart';
import '../services/vault_service.dart';

class UploadVaultScreen extends StatefulWidget {
  const UploadVaultScreen({super.key});

  @override
  State<UploadVaultScreen> createState() => _UploadVaultScreenState();
}

class _UploadVaultScreenState extends State<UploadVaultScreen> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  String _selectedYear = 'SY'; // Default

  bool _isUploading = false;
  final _vaultService = VaultService();

  Future<void> _handleUpload() async {
    if (_subjectController.text.isEmpty || _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject and Topic are required!")));
      return;
    }

    setState(() => _isUploading = true);

    // This single function call triggers the picker, the storage upload, and the database insert!
    final error = await _vaultService.uploadStudyMaterial(
      academicYear: _selectedYear,
      subject: _subjectController.text,
      topic: _topicController.text,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (error != null) {
        if (error != "Upload cancelled.") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File saved to The Vault!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Go back and trigger a refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload to Vault", style: TextStyle(color: Colors.green))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Tag your file so others can find it:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Academic Year"),
              items: ['FY', 'SY', 'TY', 'Final'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedYear = newValue!),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Subject (e.g., Logic Devices)"),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _topicController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Topic (e.g., Unit 1 Notes)"),
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.upload_file),
                label: Text(_isUploading ? "Uploading to Cloud..." : "Select File & Upload", style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}