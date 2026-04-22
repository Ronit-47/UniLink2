// Removed dart:io import to prevent Web crashes
import 'package:image_picker/image_picker.dart'; // Added for XFile
import 'package:supabase_flutter/supabase_flutter.dart';

class BrolxService {
  final supabase = Supabase.instance.client;

  // ─── CATEGORIES ───────────────────────────────────────────────────────────
  static const List<String> categories = [
    'All',
    'Electronics',
    'Lab Equipment',
    'Books & Notes',
    'Furniture',
    'Appliances',
    'Clothing',
    'Sports',
    'Vehicles',
    'Other',
  ];

  // ─── 1. ADD AN ITEM TO THE MARKETPLACE ────────────────────────────────────
  Future<String?> addItem({
    required String title,
    required String description,
    required String price,
    required String listingType,   // 'Rent' or 'Sell'
    required String category,
    List<XFile>? imageFiles,       // CHANGED: Now expects XFile instead of File
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Upload images first, collect their public URLs
      final List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (int i = 0; i < imageFiles.length; i++) {
          final xfile = imageFiles[i];
          
          // Read the file as raw bytes for Web compatibility
          final bytes = await xfile.readAsBytes();
          
          // Use .name instead of .path to safely get the extension on Web
          final ext = xfile.name.split('.').last; 
          final path = 'brolx/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

          // CHANGED: Use uploadBinary instead of upload
          await supabase.storage
              .from('brolx-images')
              .uploadBinary(
                path, 
                bytes, 
                fileOptions: const FileOptions(upsert: true)
              );

          final url = supabase.storage.from('brolx-images').getPublicUrl(path);
          imageUrls.add(url);
        }
      }

      await supabase.from('brolx_items').insert({
        'seller_id': userId,
        'title': title.trim(),
        'description': description.trim(),
        'price': price.trim(),
        'listing_type': listingType,
        'category': category,
        'image_urls': imageUrls,   // stored as text[] in Postgres
        'is_available': true,
      });

      return null; // success
    } catch (e) {
      return "Error posting item: $e";
    }
  }

  // ─── 2. FETCH ITEMS (WITH OPTIONAL CATEGORY FILTER) ───────────────────────
  Future<List<dynamic>> fetchMarketplaceItems({String? category}) async {
    try {
      var query = supabase
          .from('brolx_items')
          .select('*, profiles(full_name, course)')
          .eq('is_available', true)
          .order('created_at', ascending: false);

      if (category != null && category != 'All') {
        query = supabase
            .from('brolx_items')
            .select('*, profiles(full_name, course)')
            .eq('is_available', true)
            .eq('category', category)
            .order('created_at', ascending: false);
      }

      final response = await query;
      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  // ─── 3. SEND A CONTACT REQUEST ─────────────────────────────────────────────
  Future<String?> sendContactRequest({
    required String itemId,
    required String sellerId,
    String? message,
  }) async {
    try {
      final buyerId = supabase.auth.currentUser!.id;

      if (buyerId == sellerId) {
        return "You can't request your own item!";
      }

      // Check if a request already exists (avoid spam)
      final existing = await supabase
          .from('brolx_contact_requests')
          .select()
          .eq('item_id', itemId)
          .eq('buyer_id', buyerId)
          .maybeSingle();

      if (existing != null) {
        return "already_sent"; // special flag, UI can show "Requested" state
      }

      await supabase.from('brolx_contact_requests').insert({
        'item_id': itemId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'message': message ?? "Hi! I'm interested in your listing.",
        'status': 'pending',
      });

      return null; // success
    } catch (e) {
      return "Error sending request: $e";
    }
  }
  // ─── 5. MARK ITEM AS SOLD / RENTED ────────────────────────────────────────
  Future<String?> markAsSold(String itemId) async {
    try {
      // Flips the boolean so it instantly disappears from the main feed
      await supabase
          .from('brolx_items')
          .update({'is_available': false})
          .eq('id', itemId);
          
      return null; // success
    } catch (e) {
      return "Error updating status: $e";
    }
  }

  // ─── 6. EDIT EXISTING ITEM ────────────────────────────────────────────────
  Future<String?> updateItemDetails({
    required String itemId,
    required String title,
    required String description,
    required String price,
    required String category,
  }) async {
    try {
      await supabase
          .from('brolx_items')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'price': price.trim(),
            'category': category,
          })
          .eq('id', itemId);
          
      return null; // success
    } catch (e) {
      return "Error updating item: $e";
    }
  }
  // ─── 7. FETCH LOGGED-IN USER'S ITEMS ──────────────────────────────────────
  Future<List<dynamic>> fetchMyMarketplaceItems() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('brolx_items')
          .select('*, profiles(full_name, course)')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);
      return response as List<dynamic>;
    } catch (e) {
      print("Fetch my items error: $e");
      return [];
    }
  }

  // ─── 4. CHECK IF CURRENT USER ALREADY REQUESTED AN ITEM ───────────────────
  Future<bool> hasRequestedItem(String itemId) async {
    try {
      final buyerId = supabase.auth.currentUser!.id;
      final existing = await supabase
          .from('brolx_contact_requests')
          .select()
          .eq('item_id', itemId)
          .eq('buyer_id', buyerId)
          .maybeSingle();
      return existing != null;
    } catch (_) {
      return false;
    }
  }
}