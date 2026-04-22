import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vibematch_service.dart';

class EditVibeScreen extends StatefulWidget {
  const EditVibeScreen({super.key});

  @override
  State<EditVibeScreen> createState() => _EditVibeScreenState();
}

class _EditVibeScreenState extends State<EditVibeScreen> {
  final _bioController = TextEditingController();
  final _redFlagsController = TextEditingController();
  final _greenFlagsController = TextEditingController();
  final _branchController = TextEditingController();
  final _divController = TextEditingController();

  String _lookingFor = 'Roommate';
  String _academicYear = 'FY';
  File? _selectedImage;
  bool _isLoading = false;
  final _vibeService = VibeMatchService();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final error = await _vibeService.saveVibeProfile(
      bio: _bioController.text,
      lookingFor: _lookingFor,
      redFlags: _redFlagsController.text,
      greenFlags: _greenFlagsController.text,
      academicYear: _academicYear,
      branch: _branchController.text,
      division: _divController.text,
      imageFile: _selectedImage,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Live! \u2728"), backgroundColor: Colors.pinkAccent));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Vibe Profile", style: TextStyle(color: Colors.pinkAccent))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- PHOTO UPLOAD UI ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.pinkAccent) : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text("Tap to upload photo", style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 32),

            // --- ACADEMIC INFO UI ---
            const Text("Academic Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _academicYear,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Year"),
                    items: ['FY', 'SY', 'TY', 'Final'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _academicYear = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: _branchController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Branch (e.g. CSE)")),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: _divController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Div")),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- VIBE PREFERENCES UI ---
            const Text("What are you looking for?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _lookingFor,
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.search_rounded)),
              items: ['Roommate', 'Flat/Room', 'Both'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _lookingFor = v!),
            ),
            const SizedBox(height: 24),

            TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: "Short Bio", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            TextField(controller: _greenFlagsController, decoration: const InputDecoration(labelText: "Green Flags \u2705", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            TextField(controller: _redFlagsController, decoration: const InputDecoration(labelText: "Red Flags \uD83D\uDEA9", border: OutlineInputBorder())),
            const SizedBox(height: 40),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}