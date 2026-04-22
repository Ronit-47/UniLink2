import 'package:flutter/material.dart';
import '../services/vault_service.dart';
import 'upload_vault_screen.dart';

class VaultFeedScreen extends StatefulWidget {
  const VaultFeedScreen({super.key});

  @override
  State<VaultFeedScreen> createState() => _VaultFeedScreenState();
}

// The 'SingleTickerProviderStateMixin' is required for smooth TabBar animations!
class _VaultFeedScreenState extends State<VaultFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _vaultService = VaultService();

  List<dynamic> _files = [];
  bool _isLoading = true;

  final List<String> _years = ['FY', 'SY', 'TY', 'Final'];

  @override
  void initState() {
    super.initState();
    // Set up the 4 tabs (FY, SY, TY, Final)
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Load the First Year files by default when the screen opens
    _loadFiles('FY');
  }

  // This fires every time the user taps a different year tab
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadFiles(_years[_tabController.index]);
    }
  }

  Future<void> _loadFiles(String year) async {
    setState(() => _isLoading = true);
    final data = await _vaultService.fetchVaultFiles(year);
    if (mounted) {
      setState(() {
        _files = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("The Vault", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.green),
        // This creates the swipeable menu under the AppBar
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: "FY"),
            Tab(text: "SY"),
            Tab(text: "TY"),
            Tab(text: "Final"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _files.isEmpty
          ? const Center(child: Text("No files uploaded for this year yet.", style: TextStyle(fontSize: 16)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          final uploaderName = file['profiles']?['full_name'] ?? 'Unknown Student';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              ),
              title: Text(file['topic'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("${file['subject']}\nUploaded by $uploaderName", style: const TextStyle(height: 1.4)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.green, size: 30),
                onPressed: () {
                  // For the Viva Demo, we just show a SnackBar.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Downloading ${file['file_name']} to local storage...")),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to the upload screen, and if a file is uploaded, refresh the current tab!
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadVaultScreen()),
          );
          if (shouldRefresh == true) {
            _loadFiles(_years[_tabController.index]);
          }
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Upload Notes"),
      ),
    );
  }
}