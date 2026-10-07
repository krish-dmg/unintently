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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final list = await LocalStorageService.getDocs();
    if (list.isEmpty) {
      // Seed initial sample documents if first run
      final sample1 = AssignmentDoc(
        id: '1',
        title: 'C and Python Lab',
        docType: 'qa',
        heading: 'MCSL-205',
        items: [
          QAItem(
            question: 'Using Structures write an interactive program in C language to create an application program for a small office to maintain the employee database.',
            answer: 'Program to Maintain Employee Database using Structures in C',
          ),
          QAItem(
            question: 'Attempt the following: Write Program to perform following tasks: Create a database schema and insert records.',
            answer: 'Program to Perform Database Operations using Python (MySQL)',
          ),
          QAItem(
            question: 'Write a python code to read a dataset (may be CSV file) and print all features i.e. columns.',
            answer: 'Program to Read CSV Dataset and Compute Descriptive Statistics',
          ),
        ],
        paperAsset: 'assets/images/ruledAssignment.jpeg',
      );
      final sample2 = AssignmentDoc(
        id: '2',
        title: 'Windows and Linux Lab',
        docType: 'qa',
        heading: 'MCSL-206',
        items: [
          QAItem(question: 'Explain Linux file permissions in detail.', answer: 'File permissions in Linux are categorized into read, write, and execute for owner, group, and others.'),
        ],
        paperAsset: 'assets/images/ruled1.jpg',
      );
      final sample3 = AssignmentDoc(
        id: '3',
        title: 'Operating Systems Assignment',
        docType: 'general',
        heading: 'OS Concepts',
        generalContent: 'Process synchronization and deadlock handling mechanisms in modern operating systems.',
        paperAsset: 'assets/images/ruled2.jpg',
      );
      await LocalStorageService.saveDoc(sample1);
      await LocalStorageService.saveDoc(sample2);
      await LocalStorageService.saveDoc(sample3);
      final refreshed = await LocalStorageService.getDocs();
      if (mounted) setState(() { _docs = refreshed; _isLoading = false; });
      return;
    }

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
    return currentTabDocs.where((d) => d.title.toLowerCase().contains(q) || d.heading.toLowerCase().contains(q)).toList();
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
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
                child: const Icon(Icons.question_answer_outlined, color: Colors.blue),
              ),
              title: const Text('Question & Answers', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('for structured Assignments', style: TextStyle(fontSize: 12)),
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
              title: const Text('General', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('for small documents', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGeneralDocumentScreen()),
                ).then((_) => _loadDocs());
              },
            ),

            // Talk with other students
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.forum_outlined, color: Colors.green),
              ),
              title: const Text('Talk with other students', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('for discussions, feature requests', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),

            // ChatGPT to assignment tutorial / QR sync
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.teal),
              ),
              title: const Text('ChatGPT to assignment (QR Sync)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Sync directly with ChatGPT browser extension', style: TextStyle(fontSize: 12)),
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
      // Original Burger Drawer
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
              leading: const Icon(Icons.folder_copy_outlined),
              title: const Text('All Files'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('ChatGPT Sync'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrExtensionSyncScreen()));
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Community & Socials', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub Source Code'),
              subtitle: const Text('krish-dmg/unintently'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share App with Friends'),
              onTap: () => Navigator.pop(context),
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
      ),
      body: _currentBottomNavIndex != 0
          ? _buildProfileOrOtherTabs()
          : Column(
              children: [
                // Top Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for Assignments,Files...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'All Files'),
                      Tab(text: 'Pending'),
                      Tab(text: 'Completed'),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(height: 8),

                // File Cards List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'No assignments found',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
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
                                          // Document Icon
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: d.docType == 'qa' ? const Color(0xFF10A37F).withOpacity(0.15) : Colors.blue.withOpacity(0.15),
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
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                                Text(
                                                  d.docType == 'qa' ? 'Question & Answers' : 'General',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Edit Icon
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
                                          // Time & Date badges
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

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(icon: Icons.home, label: 'Home', index: 0),
            _buildBottomNavItem(icon: Icons.chat_bubble_outline, label: 'Friends', index: 1),
            const SizedBox(width: 48), // Floating Action Button spacer
            _buildBottomNavItem(icon: Icons.workspace_premium_outlined, label: 'Premium', index: 2),
            _buildBottomNavItem(icon: Icons.person_outline, label: 'Profile', index: 3),
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

  Widget _buildBottomNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentBottomNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentBottomNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey, size: 24),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOrOtherTabs() {
    if (_currentBottomNavIndex == 3) {
      // Profile Screen as in screenshot
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
                const Text('Otzua', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('unintently-user', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                        leading: const Icon(Icons.sync),
                        title: const Text('Sync data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Assignment Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.forum_outlined, color: Colors.green),
                        title: const Text('Connect on WhatsApp'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
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

    if (_currentBottomNavIndex == 1) {
      // Friends / Referral as in screenshot
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Refer a friend', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('And you both will get 5 Free Assignments.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildStepRow(step: '1', title: 'Invite your friends', desc: 'Just share your link'),
            const SizedBox(height: 20),
            _buildStepRow(step: '2', title: 'They hit the road', desc: 'With unlimited free Assignments'),
            const SizedBox(height: 20),
            _buildStepRow(step: '3', title: 'Open-Source for All', desc: 'Completely free for everyone'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.upload),
                label: const Text('Refer friends now', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      );
    }

    // Premium Tab
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Everything is Free!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('In Unintently v2, all fonts, paper styles, and pages are 100% unlocked forever.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStepRow({required String step, required String title, required String desc}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.shade50,
          child: Text(step, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
