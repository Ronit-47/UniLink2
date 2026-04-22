import 'package:flutter/material.dart';
import '../services/vault_service.dart';
import 'upload_vault_screen.dart';

class VaultFeedScreen extends StatefulWidget {
  const VaultFeedScreen({super.key});

  @override
  State<VaultFeedScreen> createState() => _VaultFeedScreenState();
}

class _VaultFeedScreenState extends State<VaultFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _vaultService = VaultService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _files = [];
  bool _isLoading = true;

  final List<String> _years = ['FY', 'SY', 'TY', 'Final'];

  // Filter State
  String _selectedBranch = 'All';
  final List<String> _branches = ['All', 'Computer', 'IT', 'ENTC', 'Mechanical', 'Civil'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadFiles();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadFiles(); // Reloads files using the new tab's year
    }
  }

  // Updated to use the branch and search query
  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);

    final currentYear = _years[_tabController.index];
    final searchQuery = _searchController.text.trim();

    final data = await _vaultService.fetchVaultFiles(currentYear, _selectedBranch, searchQuery);

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
    _searchController.dispose();
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
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: // Inside VaultFeedScreen:
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadFiles(),
                    decoration: InputDecoration(
                      hintText: "Search notes (e.g., saad_unit1)", // UPDATED HINT
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadFiles();
                        },
                      ),
                      contentPadding: const EdgeInsets.all(0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    items: _branches.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _selectedBranch = newValue!);
                      _loadFiles(); // Auto-reload when branch changes
                    },
                  ),
                ),
              ],
            ),
          ),

          // File List Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _files.isEmpty
                ? const Center(child: Text("No files found matching your criteria.", style: TextStyle(fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final uploaderName = file['profiles']?['full_name'] ?? 'Unknown Student';
                final fileBranch = file['branch'] ?? 'General';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    ),
                    // Change the title to show the actual file_name
                    title: Text(
                      file['file_name'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),

                    // Keep the branch and uploader in the subtitle
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "${file['branch'] ?? 'General'}\nUploaded by $uploaderName",
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.green, size: 30),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Downloading ${file['topic']}...")),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadVaultScreen()),
          );
          if (shouldRefresh == true) {
            _loadFiles();
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