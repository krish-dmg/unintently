import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import 'create_qa_assignment_screen.dart';
import 'create_general_document_screen.dart';
import 'qr_extension_sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AssignmentDoc> _docs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentBottomNavIndex = 0;
  String _userName = 'Otzua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final list = await LocalStorageService.getDocs();
    if (mounted) {
      setState(() {
        _docs = list;
        _isLoading = false;
      });
    }
  }

  List<AssignmentDoc> get _filteredDocs {
    List<AssignmentDoc> currentTabDocs;
    if (_tabController.index == 1) {
      currentTabDocs = _docs.where((d) => !d.isCompleted).toList();
    } else if (_tabController.index == 2) {
      currentTabDocs = _docs.where((d) => d.isCompleted).toList();
    } else {
      currentTabDocs = _docs;
    }

    if (_searchQuery.trim().isEmpty) return currentTabDocs;
    final q = _searchQuery.toLowerCase();
    return currentTabDocs.where((d) =>
        d.title.toLowerCase().contains(q) ||
        d.heading.toLowerCase().contains(q)).toList();
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Assignments?'),
        content: const Text('This will permanently delete all saved assignments from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              for (var d in List.from(_docs)) {
                await LocalStorageService.deleteDoc(d.id);
              }
              _loadDocs();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question & Answers Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.question_answer_outlined, color: Color(0xFF1D4ED8)),
              ),
              title: const Text('Question & Answers', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: const Text('for structured Assignments', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateQAAssignmentScreen()),
                ).then((_) => _loadDocs());
              },
            ),

            // General Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note, color: Colors.orange),
              ),
              title: const Text('General', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: const Text('for small documents', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGeneralDocumentScreen()),
                ).then((_) => _loadDocs());
              },
            ),

            // ChatGPT to assignment tutorial / QR sync
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Color(0xFF10A37F)),
              ),
              title: const Text('ChatGPT to assignment (QR Sync)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: const Text('Sync directly with ChatGPT browser extension', style: TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrExtensionSyncScreen()),
                ).then((_) => _loadDocs());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // Left Burger Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1D4ED8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/intentlyLogo.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.school, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Unintently', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('Free & Open-Source Assignment Generator', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_copy_outlined, color: Color(0xFF1E3A8A)),
              title: const Text('All Files'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Color(0xFF1E3A8A)),
              title: const Text('ChatGPT Sync'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrExtensionSyncScreen())).then((_) => _loadDocs());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              title: const Text('Delete All Assignments', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAll();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Intently',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
            tooltip: 'Clear All',
            onPressed: _docs.isEmpty ? null : _confirmDeleteAll,
          ),
        ],
      ),
      body: _currentBottomNavIndex == 1
          ? _buildProfileTab()
          : Column(
              children: [
                // Top Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search for Assignments,Files...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      suffixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // 3 Top Tabs: All Files | Pending | Completed
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1D4ED8),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF1D4ED8),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'All Files'),
                      Tab(text: 'Pending'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // File Cards List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredDocs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No assignments found',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap the + button below to create one',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: _filteredDocs.length,
                              itemBuilder: (ctx, index) {
                                final d = _filteredDocs[index];
                                final timeStr = DateFormat('h:mm a').format(d.updatedAt);
                                final dateStr = DateFormat('MMM d, yyyy').format(d.updatedAt);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: d.docType == 'qa'
                                                  ? const Color(0xFF10A37F).withValues(alpha: 0.15)
                                                  : Colors.blue.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              d.docType == 'qa' ? Icons.chat_bubble_outline : Icons.description_outlined,
                                              color: d.docType == 'qa' ? const Color(0xFF10A37F) : Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d.title,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                                ),
                                                Text(
                                                  d.docType == 'qa' ? 'Question & Answers' : 'General',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1D4ED8)),
                                            onPressed: () {
                                              if (d.docType == 'qa') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => CreateQAAssignmentScreen(initialDoc: d)),
                                                ).then((_) => _loadDocs());
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => CreateGeneralDocumentScreen(initialDoc: d)),
                                                ).then((_) => _loadDocs());
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D4ED8),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              timeStr,
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D4ED8),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              dateStr,
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const Spacer(),
                                          // Toggle completed checkbox
                                          IconButton(
                                            icon: Icon(
                                              d.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                              color: d.isCompleted ? Colors.green : Colors.grey,
                                              size: 20,
                                            ),
                                            tooltip: d.isCompleted ? 'Mark Pending' : 'Mark Completed',
                                            onPressed: () async {
                                              d.isCompleted = !d.isCompleted;
                                              await LocalStorageService.saveDoc(d);
                                              _loadDocs();
                                            },
                                          ),
                                          // Print PDF button
                                          IconButton(
                                            icon: const Icon(Icons.print_outlined, size: 20, color: Colors.grey),
                                            onPressed: () => PdfExportService.printOrSharePdf(d),
                                          ),
                                          // Delete Button
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                            onPressed: () async {
                                              await LocalStorageService.deleteDoc(d.id);
                                              _loadDocs();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),

      // Clean 2-Item Bottom Bar (Home & Profile)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () => setState(() => _currentBottomNavIndex = 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: _currentBottomNavIndex == 0 ? const Color(0xFF1D4ED8) : Colors.grey, size: 24),
                  Text('Home', style: TextStyle(color: _currentBottomNavIndex == 0 ? const Color(0xFF1D4ED8) : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 48), // FAB center space
            InkWell(
              onTap: () => setState(() => _currentBottomNavIndex = 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: _currentBottomNavIndex == 1 ? const Color(0xFF1D4ED8) : Colors.grey, size: 24),
                  Text('Profile', style: TextStyle(color: _currentBottomNavIndex == 1 ? const Color(0xFF1D4ED8) : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _showCreateBottomSheet,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      children: [
        Container(
          color: const Color(0xFF1D4ED8),
          height: 80,
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/user.svg',
                    width: 72,
                    height: 72,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.account_circle, size: 76, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                    onPressed: () {
                      final ctrl = TextEditingController(text: _userName);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Edit Name'),
                          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Display Name')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                setState(() => _userName = ctrl.text.trim().isEmpty ? 'User' : ctrl.text.trim());
                                Navigator.pop(ctx);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Text('unintently-offline', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatBox(label: 'REMAINING', value: '∞'),
                    _buildStatBox(label: 'CREATED', value: '${_docs.length}'),
                    _buildStatBox(label: 'SHARED', value: '0'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder_outlined, color: Color(0xFF1E3A8A)),
                      title: const Text('Total Assignments Saved', style: TextStyle(color: Color(0xFF0F172A))),
                      trailing: Text('${_docs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                      title: const Text('Delete All Saved Data', style: TextStyle(color: Colors.red)),
                      onTap: _confirmDeleteAll,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({required String label, required String value}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
