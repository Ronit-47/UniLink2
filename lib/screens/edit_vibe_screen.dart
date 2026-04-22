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
  final _branchController = TextEditingController();
  final _divController = TextEditingController();

  String _lookingFor = 'Roommate';
  String _academicYear = 'FY';
  File? _selectedImage;
  bool _isLoading = false;
  final _vibeService = VibeMatchService();

  // THE QUIZ LOGIC: Pre-defined options to make it feel like a Google Form
  final List<String> _allGreenFlags = ['Early Bird', 'Night Owl', 'Clean Freak', 'Chill/Messy', 'Gym Rat', 'Gamer', 'Studious', 'Party Goer'];
  final List<String> _allRedFlags = ['Smokes', 'Loud Music', 'Shares Clothes', 'Messy Kitchen', 'Never Leaves Room'];

  List<String> _selectedGreenFlags = [];
  List<String> _selectedRedFlags = [];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    // Convert the selected chips into a comma-separated string for the database
    final greenFlagsString = _selectedGreenFlags.join(', ');
    final redFlagsString = _selectedRedFlags.join(', ');

    final error = await _vibeService.saveVibeProfile(
      bio: _bioController.text,
      lookingFor: _lookingFor,
      redFlags: redFlagsString,
      greenFlags: greenFlagsString,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Live! ✨"), backgroundColor: Colors.pinkAccent));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(title: const Text("The Vibe Quiz", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PHOTO UPLOAD
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
            const SizedBox(height: 32),

            // GOOGLE FORM STYLE CARD 1: Academic Info
            _buildQuizCard(
              title: "1. The Basics",
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _academicYear,
                    decoration: const InputDecoration(labelText: "Year", border: OutlineInputBorder()),
                    items: ['FY', 'SY', 'TY', 'Final'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _academicYear = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _branchController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Branch (e.g. CSE)")),
                ],
              ),
            ),

            // GOOGLE FORM STYLE CARD 2: Green Flags (Multi-Select)
            _buildQuizCard(
              title: "2. Your Vibe (Select multiple) ✅",
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _allGreenFlags.map((flag) {
                  final isSelected = _selectedGreenFlags.contains(flag);
                  return ChoiceChip(
                    label: Text(flag),
                    selected: isSelected,
                    selectedColor: Colors.green.withOpacity(0.3),
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedGreenFlags.add(flag) : _selectedGreenFlags.remove(flag);
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            // GOOGLE FORM STYLE CARD 3: Red Flags (Multi-Select)
            _buildQuizCard(
              title: "3. Dealbreakers (Select multiple) 🚩",
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _allRedFlags.map((flag) {
                  final isSelected = _selectedRedFlags.contains(flag);
                  return ChoiceChip(
                    label: Text(flag),
                    selected: isSelected,
                    selectedColor: Colors.red.withOpacity(0.3),
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedRedFlags.add(flag) : _selectedRedFlags.remove(flag);
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            // GOOGLE FORM STYLE CARD 4: Bio
            _buildQuizCard(
              title: "4. About Me",
              child: TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(hintText: "I sleep late, study hard, and make great coffee...", border: OutlineInputBorder())),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Quiz & Match", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to draw the neat white Google-Form style cards
  Widget _buildQuizCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}