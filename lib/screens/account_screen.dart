import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _profileService = ProfileService();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _divController = TextEditingController();

  String _selectedYear = 'FY';
  File? _imageFile;
  String? _currentAvatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final data = await _profileService.getMyProfile();
    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['full_name'] ?? '';
        _branchController.text = data['branch'] ?? '';
        _divController.text = data['division'] ?? '';
        _selectedYear = data['academic_year'] ?? 'FY';
        _currentAvatarUrl = data['avatar_url'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final error = await _profileService.updateProfile(
      fullName: _nameController.text.trim(),
      branch: _branchController.text.trim(),
      academicYear: _selectedYear,
      division: _divController.text.trim(),
      imageFile: _imageFile,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // PROFILE LOGO / AVATAR PICKER
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_currentAvatarUrl != null ? NetworkImage(_currentAvatarUrl!) : null) as ImageProvider?,
                child: (_imageFile == null && _currentAvatarUrl == null)
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.indigo)
                    : null,
              ),
            ),
            const SizedBox(height: 32),

            // DETAILS SECTION
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: "Academic Year", border: OutlineInputBorder()),
              items: ['FY', 'SY', 'TY', 'Final'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (val) => setState(() => _selectedYear = val!),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _branchController,
              decoration: const InputDecoration(labelText: "Branch (e.g. CSE, IT)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _divController,
              decoration: const InputDecoration(labelText: "Division", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Update Details"),
              ),
            )
          ],
        ),
      ),
    );
  }
}