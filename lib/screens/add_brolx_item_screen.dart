import 'dart:io' show File; // Restricted import
import 'package:flutter/foundation.dart' show kIsWeb; // Added to check for Web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/brolx_service.dart';

class AddBrolxItemScreen extends StatefulWidget {
  final Map<String, dynamic>? initialItem; // ADDED: Accepts existing data

  const AddBrolxItemScreen({super.key, this.initialItem});

  @override
  State<AddBrolxItemScreen> createState() => _AddBrolxItemScreenState();
}

class _AddBrolxItemScreenState extends State<AddBrolxItemScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedType = 'Sell';
  String _selectedCategory = BrolxService.categories[1]; 
  bool _isLoading = false;
  final _brolxService = BrolxService();

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ADDED: If we passed an item in, pre-fill all the text fields!
    if (widget.initialItem != null) {
      _titleController.text = widget.initialItem!['title'] ?? '';
      _descController.text = widget.initialItem!['description'] ?? '';
      _priceController.text = widget.initialItem!['price']?.toString() ?? '';
      _selectedType = widget.initialItem!['listing_type'] ?? 'Sell';
      
      final cat = widget.initialItem!['category'];
      if (BrolxService.categories.contains(cat)) {
        _selectedCategory = cat;
      }
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 photos allowed.")),
      );
      return;
    }

    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);

    if (pickedFiles.isEmpty) return;

    final remaining = 5 - _selectedImages.length;
    // FIX 2: Stop casting to dart:io File
    final toAdd = pickedFiles.take(remaining).toList();

    setState(() {
      _selectedImages.addAll(toAdd);
    });

    if (pickedFiles.length > remaining) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Only $remaining more photo(s) could be added (max 5).")),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitItem() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Price are required!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? error;

    // Check if we are editing or creating
    if (widget.initialItem != null) {
      // EDIT MODE
      error = await _brolxService.updateItemDetails(
        itemId: widget.initialItem!['id'].toString(),
        title: _titleController.text,
        description: _descController.text,
        price: _priceController.text,
        category: _selectedCategory,
      );
    } else {
      // CREATE MODE
      error = await _brolxService.addItem(
        title: _titleController.text,
        description: _descController.text,
        price: _priceController.text,
        listingType: _selectedType,
        category: _selectedCategory,
        imageFiles: _selectedImages.isEmpty ? null : _selectedImages,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(widget.initialItem != null ? "Item Updated!" : "Item Posted!"), 
             backgroundColor: Colors.green
           ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Post to BroLX", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── PHOTO PICKER ──────────────────────────────────────────────
            _buildSectionLabel("Photos", Icons.camera_alt_outlined),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._selectedImages.asMap().entries.map((entry) {
                    return _buildImageTile(entry.value, entry.key);
                  }),

                  if (_selectedImages.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1.5, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: Colors.blueAccent, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              _selectedImages.isEmpty ? "Add Photos" : "${_selectedImages.length}/5",
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── LISTING TYPE ──────────────────────────────────────────────
            _buildSectionLabel("Listing Type", Icons.sell_outlined),
            const SizedBox(height: 10),
            Row(
              children: ['Sell', 'Rent'].map((type) {
                final selected = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: type == 'Sell' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? Colors.blueAccent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          type == 'Sell' ? '🏷️  Sell' : '🔄  Rent',
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── CATEGORY ──────────────────────────────────────────────────
            _buildSectionLabel("Category", Icons.category_outlined),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
                  items: BrolxService.categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── TITLE ─────────────────────────────────────────────────────
            _buildSectionLabel("Item Title", Icons.title),
            const SizedBox(height: 10),
            _buildTextField(_titleController, "e.g. Arduino Uno, Washing Machine"),
            const SizedBox(height: 24),

            // ── PRICE ─────────────────────────────────────────────────────
            _buildSectionLabel(
              _selectedType == 'Rent' ? "Price per day / month (₹)" : "Selling Price (₹)",
              Icons.currency_rupee,
            ),
            const SizedBox(height: 10),
            _buildTextField(_priceController, "0", isNumeric: true),
            const SizedBox(height: 24),

            // ── DESCRIPTION ───────────────────────────────────────────────
            _buildSectionLabel("Description", Icons.notes_outlined),
            const SizedBox(height: 10),
            _buildTextField(_descController, "Condition, age, any damage, reason for selling...", maxLines: 4),
            const SizedBox(height: 36),

            // ── SUBMIT ────────────────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("Post Item", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueAccent),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumeric = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
      ),
    );
  }

  // FIX 3: Dynamic Image Rendering based on Web vs Mobile
  Widget _buildImageTile(XFile file, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              // Use NetworkImage for Web Blob URLs, FileImage for mobile
              image: kIsWeb ? NetworkImage(file.path) : FileImage(File(file.path)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}