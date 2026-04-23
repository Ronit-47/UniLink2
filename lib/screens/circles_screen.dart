// lib/screens/circles_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/circles_service.dart';
import 'chat_screen.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final CirclesService _circlesService = CirclesService();

  late TabController _tabController;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _selectedChip = 'All';
  bool _isLoadingUsers = true;

  static const _filterChips = [
    'All',
    'Co-Pilots',
    'The Squad',
    'Lowkey',
    'Brain Trust',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _circlesService.getCampusUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load people: $e')),
        );
      }
    }
  }

  void _filterUsers(String chip) {
    setState(() {
      _selectedChip = chip;
      _filteredUsers = chip == 'All' ? _allUsers : _allUsers.where((user) {
        switch (chip) {
          case 'Brain Trust':
            return (user['trust_score'] ?? 0) > 10;
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> _openChatWith(Map<String, dynamic> otherUser) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
      ),
    );

    try {
      final myProfile = await _chatService.fetchMyProfile();
      final conversationId = await _chatService.getOrCreateConversation(
        otherUserId: otherUser['id'],
        otherUserName: otherUser['full_name'] ?? 'Campus Peer',
        otherUserAvatar: otherUser['avatar_url'] ?? '',
        myName: myProfile['name'] ?? 'Me',
        myAvatar: myProfile['avatar'] ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserName: otherUser['full_name'] ?? 'Campus Peer',
            otherUserAvatar: otherUser['avatar_url'] ?? '',
            receiverId: otherUser['id'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A3E),
        elevation: 0,
        // FIX: explicitly white so back arrow is always visible
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Circles',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'People'),
            Tab(text: 'Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPeopleTab(),
          _buildChatsTab(),
        ],
      ),
    );
  }

  // ── PEOPLE TAB ────────────────────────────────────────────────────────────

  Widget _buildPeopleTab() {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
      );
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(
                  child: Text(
                    'No campus peers found.\nCheck back later!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) =>
                      _buildPersonTile(_filteredUsers[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filterChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _filterChips[index];
          final isSelected = chip == _selectedChip;
          return GestureDetector(
            onTap: () => _filterUsers(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF5C35E8), Color(0xFF00BCD4)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF2A2A4A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonTile(Map<String, dynamic> user) {
    final name = user['full_name'] ?? 'Campus Peer';
    final branch = user['branch'] ?? '';
    final year = user['year'] ?? '';
    final avatar = user['avatar_url'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: _buildAvatar(avatar, initial, 22),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: branch.isNotEmpty
            ? Text(
                '$branch${year.isNotEmpty ? ' · $year' : ''}',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 13),
              )
            : null,
        trailing: GestureDetector(
          onTap: () => _openChatWith(user),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C35E8), Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 18),
          ),
        ),
        onTap: () => _openChatWith(user),
      ),
    );
  }

  // ── CHATS TAB ─────────────────────────────────────────────────────────────

  Widget _buildChatsTab() {
    return StreamBuilder<List<Conversation>>(
      // FIX: removed orderBy from Firestore query (caused index error)
      // Sorting is now done in Dart after the data arrives — no index needed
      stream: _chatService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load chats.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined,
                    color: Colors.white24, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'No conversations yet.',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Go to People and start chatting!',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text(
                    'Browse People →',
                    style:
                        TextStyle(color: Color(0xFF00BCD4), fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: conversations.length,
          itemBuilder: (context, index) =>
              _buildConversationTile(conversations[index]),
        );
      },
    );
  }

  Widget _buildConversationTile(Conversation convo) {
    final hasUnread = convo.unreadCount > 0;
    final initial = convo.otherUserName.isNotEmpty
        ? convo.otherUserName[0].toUpperCase()
        : '?';

    String timeLabel = '';
    if (convo.lastMessageTime != null) {
      final now = DateTime.now();
      final diff = now.difference(convo.lastMessageTime!);
      if (diff.inMinutes < 1) {
        timeLabel = 'Just now';
      } else if (diff.inHours < 1) {
        timeLabel = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        timeLabel = DateFormat('h:mm a').format(convo.lastMessageTime!);
      } else {
        timeLabel = DateFormat('MMM d').format(convo.lastMessageTime!);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(14),
        border: hasUnread
            ? Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.4))
            : null,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(convo.otherUserAvatar, initial, 24),
        title: Text(
          convo.otherUserName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: convo.lastMessage.isNotEmpty
            ? Text(
                convo.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread ? Colors.white70 : Colors.white38,
                  fontSize: 13,
                  fontWeight: hasUnread
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              )
            : const Text(
                'Tap to start chatting',
                style:
                    TextStyle(color: Colors.white24, fontSize: 13),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: TextStyle(
                  color: hasUnread
                      ? const Color(0xFF00BCD4)
                      : Colors.white38,
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 4),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C35E8), Color(0xFF00BCD4)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  convo.unreadCount > 99
                      ? '99+'
                      : convo.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convo.id,
              otherUserName: convo.otherUserName,
              otherUserAvatar: convo.otherUserAvatar,
              receiverId: convo.otherUserId,
            ),
          ),
        ),
      ),
    );
  }

  // ── SHARED HELPER ─────────────────────────────────────────────────────────

  Widget _buildAvatar(String avatarUrl, String initial, double radius) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: const Color(0xFF2A2A4A),
      );
    }
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
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}