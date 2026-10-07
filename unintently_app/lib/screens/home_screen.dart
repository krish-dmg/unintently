import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment_model.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import 'create_document_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssignmentModel> _assignments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final list = await LocalStorageService.getAssignments();
    if (mounted) {
      setState(() {
        _assignments = list;
        _isLoading = false;
      });
    }
  }

  List<AssignmentModel> get _filteredAssignments {
    if (_searchQuery.trim().isEmpty) return _assignments;
    final q = _searchQuery.toLowerCase();
    return _assignments
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.content.toLowerCase().contains(q) ||
            a.heading.toLowerCase().contains(q))
        .toList();
  }

  void _openEditor([AssignmentModel? assignment]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDocumentScreen(initialAssignment: assignment),
      ),
    );
    _loadAssignments();
  }

  void _confirmDelete(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: Text('Are you sure you want to delete "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.deleteAssignment(assignment.id);
              _loadAssignments();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'Unintently',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(width: 6),
            Text(
              'v2',
              style: TextStyle(
                fontSize: 12,
                color: UnintentlyTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search assignments and notes...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // Assignments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssignments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/homework.png',
                              width: 100,
                              height: 100,
                              errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.note_alt_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No assignments yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create realistic handwritten notes in seconds',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAssignments.length,
                        itemBuilder: (context, index) {
                          final a = _filteredAssignments[index];
                          final formattedDate =
                              DateFormat('MMM d, yyyy • h:mm a').format(a.updatedAt);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  a.paperAsset,
                                  width: 48,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 48,
                                    height: 64,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.description),
                                  ),
                                ),
                              ),
                              title: Text(
                                a.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    a.content.replaceAll('\n', ' '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: a.fontFamily,
                                      color: Color(a.fontColorValue),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined),
                                    tooltip: 'Print / Export PDF',
                                    onPressed: () =>
                                        PdfExportService.printOrSharePdf(a),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(a),
                                  ),
                                ],
                              ),
                              onTap: () => _openEditor(a),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UnintentlyTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
        onPressed: () => _openEditor(),
      ),
    );
  }
}
