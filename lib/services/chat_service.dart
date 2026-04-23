// lib/services/chat_service.dart
//
// PURPOSE: All Firebase Firestore logic for the Circles (chat) feature.
// This service is the ONLY file that should talk to Firestore directly.
// Screens call these methods; they never import Firebase themselves.
//
// FIRESTORE STRUCTURE:
//   conversations/{conversationId}/
//     - participants, participantNames, participantAvatars
//     - lastMessage, lastMessageTime
//     - unreadCount_{userId}: int   ← one field per participant
//     messages/{messageId}/
//       - senderId, senderName, content, timestamp, isRead

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single chat message in a conversation.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  /// Build a ChatMessage from a Firestore document snapshot.
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Firestore timestamps arrive as Timestamp objects — convert to DateTime
    final ts = data['timestamp'] as Timestamp?;

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      content: data['content'] ?? '',
      timestamp: ts?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}

/// Represents a conversation thread between two users.
class Conversation {
  final String id;
  final List<String> participants;

  /// Maps userId → display name (e.g. "Raj Choudhari")
  final Map<String, String> participantNames;

  /// Maps userId → avatar URL string
  final Map<String, String> participantAvatars;

  final String lastMessage;
  final DateTime? lastMessageTime;

  /// How many unread messages the CURRENT user has in this conversation
  final int unreadCount;

  /// The other person's userId (not the logged-in user)
  final String otherUserId;

  const Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    required this.otherUserId,
  });

  /// Helper — get the other person's display name.
  String get otherUserName => participantNames[otherUserId] ?? 'Campus Peer';

  /// Helper — get the other person's avatar URL (may be empty string if none).
  String get otherUserAvatar => participantAvatars[otherUserId] ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

/// Manages all real-time chat operations using Firebase Firestore.
///
/// Identity comes from Supabase Auth — we reuse the Supabase user UUID as
/// the Firestore document key so we don't need a second Firebase Auth login.
class ChatService {
  // Firestore instance (singleton provided by Firebase SDK)
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Supabase client to get the current user's ID and profile data
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Identity ────────────────────────────────────────────────────────────────

  /// The currently logged-in user's Supabase UUID.
  /// This same UUID is used as the participant ID in Firestore.
  String get currentUserId => _supabase.auth.currentUser!.id;

  // ── Conversation ID Generation ───────────────────────────────────────────────

  /// Creates a deterministic conversation ID from two user UUIDs.
  ///
  /// We always sort the two IDs alphabetically before joining them.
  /// This guarantees that "A→B" and "B→A" produce the SAME document ID,
  /// so there can never be duplicate conversations between the same two people.
  ///
  /// Example: uid "zzz..." + uid "aaa..." → "aaa..._zzz..."
  String _buildConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort(); // sort() mutates in place
    return '${sorted[0]}_${sorted[1]}';
  }

  // ── Open / Create Conversation ────────────────────────────────────────────────

  /// Opens an existing conversation or creates a new one if none exists.
  ///
  /// Returns the Firestore document ID for the conversation.
  /// Call this when a user taps on someone in the Circles People tab.
  ///
  /// [otherUserId]      — Supabase UUID of the person being messaged
  /// [otherUserName]    — Display name of the other person (from Supabase profiles)
  /// [otherUserAvatar]  — Avatar URL of the other person (may be empty)
  /// [myName]           — Display name of the current user
  /// [myAvatar]         — Avatar URL of the current user (may be empty)
  Future<String> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    required String otherUserAvatar,
    required String myName,
    required String myAvatar,
  }) async {
    final conversationId = _buildConversationId(currentUserId, otherUserId);
    final docRef = _db.collection('conversations').doc(conversationId);

    // Check if this conversation already exists in Firestore
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      // First time these two users are chatting — create the document
      await docRef.set({
        'participants': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: myName,
          otherUserId: otherUserName,
        },
        'participantAvatars': {
          currentUserId: myAvatar,
          otherUserId: otherUserAvatar,
        },
        'lastMessage': '',           // empty until first message is sent
        'lastMessageTime': null,
        // Each participant gets their own unread counter field
        'unreadCount_$currentUserId': 0,
        'unreadCount_$otherUserId': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  // ── Send Message ──────────────────────────────────────────────────────────────

  /// Sends a text message in a conversation.
  ///
  /// Uses a Firestore WriteBatch to atomically:
  ///   1. Add the message document to the messages subcollection
  ///   2. Update the conversation's lastMessage + lastMessageTime
  ///   3. Increment the receiver's unread counter
  ///
  /// Using a batch ensures all three writes succeed or all fail together.
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String senderName,
    required String receiverId, // the OTHER person's userId
  }) async {
    if (content.trim().isEmpty) return; // never send blank messages

    final batch = _db.batch();

    // Reference to a new auto-ID document inside the messages subcollection
    final messageRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(); // doc() with no args = auto-generate ID

    // Write 1: the actual message
    batch.set(messageRef, {
      'senderId': currentUserId,
      'senderName': senderName,
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(), // always use server time
      'isRead': false,
    });

    // Write 2 + 3: update conversation metadata in one update call
    final conversationRef = _db.collection('conversations').doc(conversationId);
    batch.update(conversationRef, {
      'lastMessage': content.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      // FieldValue.increment(1) is atomic — no race conditions
      'unreadCount_$receiverId': FieldValue.increment(1),
    });

    // Commit both writes at once
    await batch.commit();
  }

  // ── Real-Time Streams ─────────────────────────────────────────────────────────

  /// Returns a real-time stream of all messages in a conversation.
  ///
  /// Messages are ordered chronologically (oldest first) so the ListView
  /// can display them top-to-bottom in natural reading order.
  ///
  /// The stream automatically updates whenever a new message is sent by
  /// either participant — no polling needed.
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // oldest → newest
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Returns a real-time stream of all conversations the current user is in.
  ///
  /// Conversations are sorted by last message time (most recent first)
  /// so the inbox always shows the freshest conversation at the top.
  Stream<List<Conversation>> getConversations() {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        // NOTE: orderBy removed — combining where+orderBy needs a Firestore
        // composite index. We sort in Dart instead to avoid that requirement.
        .snapshots()
        .map((snapshot) {
      final convos = snapshot.docs.map((doc) {
        final data = doc.data();

        // Figure out who the OTHER person is in this two-person conversation
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId =
            participants.firstWhere((id) => id != currentUserId,
            orElse: () => '');

        // Extract nested maps safely with null fallbacks
        final names = Map<String, String>.from(data['participantNames'] ?? {});
        final avatars =
            Map<String, String>.from(data['participantAvatars'] ?? {});

        // Read THIS user's unread count from the dynamic field name
        final unreadCount =
            (data['unreadCount_$currentUserId'] ?? 0) as int;

        // Convert Firestore Timestamp → DateTime (null if no messages yet)
        final lastMsgTimestamp = data['lastMessageTime'] as Timestamp?;

        return Conversation(
          id: doc.id,
          participants: participants,
          participantNames: names,
          participantAvatars: avatars,
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: lastMsgTimestamp?.toDate(),
          unreadCount: unreadCount,
          otherUserId: otherUserId,
        );
      }).toList();

      // Sort in Dart: most recent first. No Firestore composite index needed.
      convos.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return convos;
    });
  }

  // ── Read Receipts ─────────────────────────────────────────────────────────────

  /// Marks all unread messages as read when the user opens a conversation.
  ///
  /// Does two things:
  ///   1. Resets the current user's unread counter on the conversation doc to 0
  ///   2. Sets isRead=true on all individual message docs sent by the other person
  ///
  /// Step 2 uses a batch for efficiency (one network round-trip instead of N).
  Future<void> markAsRead(String conversationId) async {
    // Step 1: reset the unread badge counter immediately
    await _db.collection('conversations').doc(conversationId).update({
      'unreadCount_$currentUserId': 0,
    });

    // Step 2: find all unread messages NOT sent by us
    final unreadDocs = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    if (unreadDocs.docs.isEmpty) return; // nothing to mark

    final batch = _db.batch();
    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Profile Helper ────────────────────────────────────────────────────────────

  /// Fetches the current user's name and avatar from Supabase profiles.
  ///
  /// Used when opening/creating a conversation to write profile data
  /// into Firestore so the other person can display it without extra queries.
  Future<Map<String, String>> fetchMyProfile() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', currentUserId)
          .single();

      return {
        'name': response['full_name'] ?? 'UniLink User',
        'avatar': response['avatar_url'] ?? '',
      };
    } catch (_) {
      // Return safe defaults if the profile fetch fails
      return {'name': 'UniLink User', 'avatar': ''};
    }
  }
}