import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final myId = _supabase.auth.currentUser!.id;

      // Fetch notifications AND join with the profiles table to get the sender's name/photo!
      final data = await _supabase
          .from('notifications')
          .select('*, sender:sender_id(full_name, avatar_url, branch, academic_year)')
          .eq('user_id', myId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });

        // Mark them all as read once they open the screen
        await _supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', myId);
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
        child: Text("No notifications yet! 📭", style: TextStyle(fontSize: 18, color: Colors.grey)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final note = _notifications[index];
          final sender = note['sender'];
          final bool isUnread = !(note['is_read'] as bool);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isUnread ? Colors.indigo.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUnread ? Border.all(color: Colors.indigo.withOpacity(0.3)) : null,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                backgroundImage: sender['avatar_url'] != null ? NetworkImage(sender['avatar_url']) : null,
                child: sender['avatar_url'] == null ? const Icon(Icons.person, color: Colors.indigo) : null,
              ),
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  children: [
                    TextSpan(text: sender['full_name'] ?? 'Someone', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: " wants to match with you!"),
                  ],
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "Quiz Result: ${note['quiz_result']}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}