import 'package:supabase_flutter/supabase_flutter.dart';

class CirclesService {
  final supabase = Supabase.instance.client;

  // FETCH YOUR NETWORK
  // For this Sprint, we fetch all registered users (except you) to populate the network.
  Future<List<dynamic>> fetchNetwork() async {
    try {
      final myId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('profiles')
          .select('*')
          .neq('id', myId);

      return response as List<dynamic>;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }
}