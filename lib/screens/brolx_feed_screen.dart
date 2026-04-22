import 'package:flutter/material.dart';
import '../services/brolx_service.dart';
import 'add_brolx_item_screen.dart';

class BrolxFeedScreen extends StatefulWidget {
  const BrolxFeedScreen({super.key});

  @override
  State<BrolxFeedScreen> createState() => _BrolxFeedScreenState();
}

class _BrolxFeedScreenState extends State<BrolxFeedScreen> {
  final _brolxService = BrolxService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  bool _showMyListings = false;


  // Tracks which items the user has already requested (itemId -> bool)
  final Map<String, bool> _requestedItems = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    
    // If toggle is ON, fetch only my items. Otherwise, fetch normally.
    final data = _showMyListings 
      ? await _brolxService.fetchMyMarketplaceItems()
      : await _brolxService.fetchMarketplaceItems(
          category: _selectedCategory == 'All' ? null : _selectedCategory,
        );
        
    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
      _checkRequestStatuses(data);
    }
  }
  Future<void> _checkRequestStatuses(List<dynamic> items) async {
    for (final item in items) {
      final itemId = item['id']?.toString();
      if (itemId == null) continue;
      final has = await _brolxService.hasRequestedItem(itemId);
      if (mounted) {
        setState(() => _requestedItems[itemId] = has);
      }
    }
  }

  Future<void> _handleContactRequest(dynamic item) async {
    final itemId = item['id']?.toString();
    final sellerId = item['seller_id']?.toString();
    if (itemId == null || sellerId == null) return;

    // Show a quick message dialog
    String? userMessage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final msgController = TextEditingController(
          text: "Hi! I'm interested in your listing.",
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Send Contact Request", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your message to the seller:",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msgController,
                maxLines: 3,
                onChanged: (v) => userMessage = v,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: "Add a note...",
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "The seller will review your request and share contact details if interested.",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                userMessage = msgController.text;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Send Request"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final error = await _brolxService.sendContactRequest(
      itemId: itemId,
      sellerId: sellerId,
      message: userMessage,
    );

    if (!mounted) return;

    if (error == null) {
      setState(() => _requestedItems[itemId] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Request sent! The seller will be notified."),
          backgroundColor: Colors.green,
        ),
      );
    } else if (error == "already_sent") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've already requested this item.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              "BroLX Marketplace",
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.blueAccent),
            actions: [
              // 📍 1. PASTE THE NEW "MY LISTINGS" BUTTON HERE
              IconButton(
                icon: Icon(_showMyListings ? Icons.storefront : Icons.inventory_2_outlined),
                tooltip: _showMyListings ? "Back to Marketplace" : "My Listings",
                onPressed: () {
                  setState(() {
                    _showMyListings = !_showMyListings;
                    _selectedCategory = 'All'; // Reset category filter
                  });
                  _loadItems();
                },
              ),
              
              // This is your existing refresh button, leave it here!
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildCategoryChips(),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildItemCard(_items[index]),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBrolxItemScreen()),
          );
          if (shouldRefresh == true) _loadItems();
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Sell / Rent"),
      ),
    );
  }

  // ── CATEGORY FILTER CHIPS ─────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: BrolxService.categories.length,
        itemBuilder: (context, index) {
          final cat = BrolxService.categories[index];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              if (_selectedCategory == cat) return;
              setState(() => _selectedCategory = cat);
              _loadItems();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ITEM CARD ─────────────────────────────────────────────────────────────

  Widget _buildItemCard(dynamic item) {
    final sellerProfile = item['profiles'] ?? {};
    final isRent = item['listing_type'] == 'Rent';
    final imageUrls = (item['image_urls'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .where((u) => u.isNotEmpty)
        .toList() ?? [];
    final itemId = item['id']?.toString() ?? '';
    final isRequested = _requestedItems[itemId] == true;
    final isOwner = item['seller_id'] == _brolxService.supabase.auth.currentUser?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── IMAGE CAROUSEL (only if images exist) ──────────────────────
          if (imageUrls.isNotEmpty)
            _buildImageCarousel(imageUrls),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Title + badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(isRent ? "FOR RENT" : "FOR SALE", isRent ? Colors.orange : Colors.green),
                  ],
                ),
                const SizedBox(height: 4),

                // Category tag
                if (item['category'] != null)
                  Text(
                    item['category'],
                    style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 8),

                // Price
                Text(
                  "₹${item['price']}${isRent ? '/day' : ''}",
                  style: const TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),

                // Description
                if (item['description'] != null && item['description'].toString().isNotEmpty)
                  Text(
                    item['description'],
                    style: TextStyle(color: Colors.grey[700], height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const Divider(height: 28),

                // Seller row + Contact button
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: Colors.blueAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sellerProfile['full_name'] ?? 'Unknown Student',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            sellerProfile['course'] ?? 'VIT Student',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // Contact button — hidden for own listings
                    // If it's not my listing, show Contact. If it IS mine, show Manage options.
                    if (!isOwner)
                      _buildContactButton(isRequested, item)
                    else
                      _buildOwnerActionButtons(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(bool isRequested, dynamic item) {
    if (isRequested) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text("Requested", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _handleContactRequest(item),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        elevation: 0,
      ),
      child: const Text("Contact", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
  // ── OWNER ACTIONS UI ──────────────────────────────────────────────────────
  Widget _buildOwnerActionButtons(dynamic item) {
    final itemId = item['id'].toString();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // EDIT BUTTON
        IconButton(
          onPressed: () async {
            // Push to the Add screen, but pass the current item data!
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddBrolxItemScreen(initialItem: item),
              ),
            );
            if (shouldRefresh == true) _loadItems(); // Refresh feed after editing
          },
          icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
          tooltip: "Edit Listing",
        ),
        
        // MARK AS SOLD BUTTON
        ElevatedButton.icon(
          onPressed: () => _handleMarkAsSold(itemId),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 0,
          ),
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text("Mark Sold", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── MARK AS SOLD LOGIC ────────────────────────────────────────────────────
  Future<void> _handleMarkAsSold(String itemId) async {
    // 1. Show confirmation popup
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Mark as Sold?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("This will remove the item from the active marketplace. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Sold it!"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Update Database & Refresh UI
    setState(() => _isLoading = true);
    final error = await _brolxService.markAsSold(itemId);
    
    if (!mounted) return;

    if (error == null) {
      _loadItems(); // Automatically refreshes the feed to make the item vanish
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Item successfully marked as sold!"), backgroundColor: Colors.green),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildImageCarousel(List<String> urls) {
    if (urls.length == 1) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: _buildNetworkImage(urls.first),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (_, i) => Stack(
          fit: StackFit.expand,
          children: [
            _buildNetworkImage(urls[i]),
            // Page indicator
            Positioned(
              bottom: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${i + 1}/${urls.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorBuilder: (_, __, ___) =>
          Container(color: Colors.grey[200], child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.shade(700), fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == 'All'
                ? "No items listed yet.\nBe the first!"
                : "No items in '$_selectedCategory' yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Helper extension to safely darken a color for badge text
extension _ColorShade on Color {
  Color shade(int value) {
    // Returns a slightly darker version by reducing brightness
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}