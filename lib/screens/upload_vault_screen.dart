import 'package:flutter/material.dart';
import '../services/vault_service.dart';
import 'package:flutter/services.dart';

class UploadVaultScreen extends StatefulWidget {
  const UploadVaultScreen({super.key});

  @override
  State<UploadVaultScreen> createState() => _UploadVaultScreenState();
}

class _UploadVaultScreenState extends State<UploadVaultScreen> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();

  String _selectedYear = 'SY'; // Default
  String _selectedBranch = 'Computer'; // Default Branch

  // Add your branches here
  final List<String> _branches = ['Computer', 'IT', 'ENTC', 'Mechanical', 'Civil'];

  bool _isUploading = false;
  final _vaultService = VaultService();

  Future<void> _handleUpload() async {
    if (_subjectController.text.isEmpty || _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject and Topic are required!")));
      return;
    }

    setState(() => _isUploading = true);

    // Passed the new branch parameter
    final error = await _vaultService.uploadStudyMaterial(
      academicYear: _selectedYear,
      branch: _selectedBranch,
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
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload to Vault", style: TextStyle(color: Colors.green))),
      body: SingleChildScrollView( // Added scroll view to prevent keyboard overflow
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Tag your file so others can find it:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Year & Branch Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Year"),
                    items: ['FY', 'SY', 'TY', 'Final'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedYear = newValue!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Branch"),
                    items: _branches.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedBranch = newValue!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject TextField
            TextField(
              controller: _subjectController,
              // Add this formatter to block spaces
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Subject (e.g., LogicDevices)", // Updated hint
                hintText: "No spaces allowed",
              ),
            ),
            const SizedBox(height: 16),

// Topic TextField
            TextField(
              controller: _topicController,
              // Add this formatter to block spaces
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Topic (e.g., Unit1Notes)", // Updated hint
                hintText: "No spaces allowed",
              ),
            ),

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