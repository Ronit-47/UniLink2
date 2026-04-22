import 'package:supabase_flutter/supabase_flutter.dart';

class BrolxService {
  final supabase = Supabase.instance.client;

  // 1. ADD AN ITEM TO THE MARKETPLACE
  Future<String?> addItem({
    required String title,
    required String description,
    required String price,
    required String listingType, // 'Rent' or 'Sell'
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('brolx_items').insert({
        'seller_id': userId,
        'title': title.trim(),
        'description': description.trim(),
        'price': price.trim(),
        'listing_type': listingType,
      });
      return null; // Success!
    } catch (e) {
      return "Error posting item: $e";
    }
  }

  // 2. FETCH ALL ITEMS (WITH SELLER DETAILS)
  Future<List<dynamic>> fetchMarketplaceItems() async {
    try {
      // The Magic Join: Fetches the item AND the seller's name/course!
      final response = await supabase
          .from('brolx_items')
          .select('*, profiles(full_name, course)')
          .order('created_at', ascending: false); // Shows newest items first

      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return []; // Return empty list if it fails
    }
  }
}