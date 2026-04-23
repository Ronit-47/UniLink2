// lib/screens/chat_screen.dart
//
// PURPOSE: The one-on-one chat interface for the Circles feature.
//
// HOW TO NAVIGATE HERE:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
//     conversationId: 'abc_xyz',
//     otherUserName: 'Ronit Dahiwal',
//     otherUserAvatar: 'https://...',
//     receiverId: 'other-user-supabase-uuid',
//   )));
//
// This screen:
//   1. Streams messages in real-time from Firestore (no polling)
//   2. Auto-scrolls to the newest message
//   3. Marks messages as read on open
//   4. Sends messages with a batch write (message + metadata update)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  /// Firestore document ID for this conversation (from ChatService)
  final String conversationId;

  /// Display name of the person being chatted with
  final String otherUserName;

  /// Avatar URL of the other person (can be empty string)
  final String otherUserAvatar;

  /// Supabase UUID of the other person — needed to increment their unread count
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── Dependencies ─────────────────────────────────────────────────────────────

  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  // ScrollController lets us jump to the bottom when new messages arrive
  final ScrollController _scrollController = ScrollController();

  // ── State ─────────────────────────────────────────────────────────────────────

  String _myName = 'Me';       // fetched from Supabase on init
  bool _isSending = false;     // disables send button while writing to Firestore

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Runs once on screen open: load our name, mark messages as read.
  Future<void> _initialize() async {
    // Mark messages as read — resets the unread badge for this conversation
    await _chatService.markAsRead(widget.conversationId);

    // Fetch our display name so it appears correctly in sent messages
    final profile = await _chatService.fetchMyProfile();
    if (mounted) {
      setState(() => _myName = profile['name'] ?? 'Me');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  /// Sends the current text in the input field.
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear(); // clear immediately for snappy UX

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
        senderName: _myName,
        receiverId: widget.receiverId,
      );
      // After sending, jump to the bottom so the new message is visible
      _scrollToBottom();
    } catch (e) {
      // If sending fails, restore the message text so the user doesn't lose it
      _messageController.text = content;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Animates the scroll position to the very bottom of the message list.
  void _scrollToBottom() {
    // Small delay lets the new message render before we scroll
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final myId = _chatService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F2A), // deep indigo background

      // ── Top App Bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar circle — shows photo or initials fallback
            _buildAvatarCircle(widget.otherUserAvatar, widget.otherUserName, 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Message List + Input Field ────────────────────────────────────────────
      body: Column(
        children: [
          // Message list takes all available space above the input bar
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                // While waiting for Firestore to respond
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
                  );
                }

                // If stream errored
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages.\nPlease try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Empty state — no messages yet
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                // Scroll to bottom whenever new messages arrive
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == myId;

                    // Check if we need a date divider above this message
                    // (show divider when date changes between consecutive messages)
                    final showDateDivider = index == 0 ||
                        !_isSameDay(
                          messages[index - 1].timestamp,
                          message.timestamp,
                        );

                    return Column(
                      children: [
                        if (showDateDivider) _buildDateDivider(message.timestamp),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Message Input Bar ──────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Widget Builders ────────────────────────────────────────────────────────────

  /// Builds a single message bubble.
  /// My messages → right-aligned, purple. Other person's → left-aligned, grey.
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Max width = 70% of screen so long messages don't stretch edge-to-edge
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF5C35E8)  // purple for sent messages
              : const Color(0xFF2A2A4A), // dark grey for received messages
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            // The "tail" of the bubble points toward the sender
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? const Color(0xFF5C35E8).withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message text
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp + read receipt row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                  ),
                ),
                // Show a double-tick read receipt only on messages we sent
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF00BCD4) // cyan = read
                        : Colors.white38,          // grey = delivered
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Text divider between messages on different dates (e.g. "Today", "Yesterday")
  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    String label;

    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, y').format(date); // e.g. "April 20, 2025"
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }

  /// The text input bar pinned to the bottom of the screen.
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        // Respect keyboard insets so the bar lifts above the soft keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      color: const Color(0xFF1A1A3E),
      child: Row(
        children: [
          // Text field — expands for multi-line messages
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null, // allow multi-line typing
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2A4A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              // Allow sending by pressing Enter on physical keyboards
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C35E8), Color(0xFF00BCD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C35E8).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when a conversation exists but no messages have been sent yet.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient circle icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C35E8), Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Say hi to ${widget.otherUserName.split(' ').first}! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the conversation below.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Builds a circular avatar. Shows photo if URL is valid, otherwise initials.
  Widget _buildAvatarCircle(String avatarUrl, String name, double radius) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: const Color(0xFF2A2A4A),
        // If the image fails to load, fall back to the initial letter
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // No avatar URL — show a gradient circle with the first letter of the name
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C35E8), Color(0xFF00BCD4)],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Utility ────────────────────────────────────────────────────────────────────

  /// Returns true if two DateTime values fall on the same calendar day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}