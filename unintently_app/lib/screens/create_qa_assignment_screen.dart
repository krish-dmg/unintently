import 'package:flutter/material.dart';
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import 'choose_page_screen.dart';

class CreateQAAssignmentScreen extends StatefulWidget {
  final AssignmentDoc? initialDoc;

  const CreateQAAssignmentScreen({super.key, this.initialDoc});

  @override
  State<CreateQAAssignmentScreen> createState() => _CreateQAAssignmentScreenState();
}

class _CreateQAAssignmentScreenState extends State<CreateQAAssignmentScreen> {
  late String _id;
  late TextEditingController _titleController;
  late TextEditingController _headingController;
  late List<TextEditingController> _qControllers;
  late List<TextEditingController> _aControllers;

  late String _paperAsset;
  late String _fontFamily;
  late int _questionColor;
  late int _answerColor;
  late bool _hasMobileShadow;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDoc;
    _id = d?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleController = TextEditingController(text: d?.title ?? '');
    _headingController = TextEditingController(text: d?.heading ?? '');

    _paperAsset = d?.paperAsset ?? 'assets/images/ruledAssignment.jpeg';
    _fontFamily = d?.fontFamily ?? 'intentlyR1';
    _questionColor = d?.questionColorValue ?? 0xFF0D47A1;
    _answerColor = d?.answerColorValue ?? 0xFF1A237E;
    _hasMobileShadow = d?.hasMobileShadow ?? false;

    _qControllers = [];
    _aControllers = [];

    if (d != null && d.items.isNotEmpty) {
      for (var item in d.items) {
        _qControllers.add(TextEditingController(text: item.question));
        _aControllers.add(TextEditingController(text: item.answer));
      }
    } else {
      // Start completely blank with 1 clean question & answer pair
      _addQA();
    }
  }

  void _addQA({String q = '', String a = ''}) {
    setState(() {
      _qControllers.add(TextEditingController(text: q));
      _aControllers.add(TextEditingController(text: a));
    });
  }

  void _removeQA(int index) {
    setState(() {
      _qControllers[index].dispose();
      _aControllers[index].dispose();
      _qControllers.removeAt(index);
      _aControllers.removeAt(index);
    });
  }

  AssignmentDoc _buildDoc() {
    final List<QAItem> items = [];
    for (int i = 0; i < _qControllers.length; i++) {
      final q = _qControllers[i].text.trim();
      final a = _aControllers[i].text.trim();
      if (q.isNotEmpty || a.isNotEmpty) {
        items.add(QAItem(question: q, answer: a));
      }
    }
    return AssignmentDoc(
      id: _id,
      title: _titleController.text.trim().isEmpty ? 'Untitled Assignment' : _titleController.text.trim(),
      docType: 'qa',
      heading: _headingController.text.trim(),
      items: items,
      fontFamily: _fontFamily,
      paperAsset: _paperAsset,
      hasMobileShadow: _hasMobileShadow,
      questionColorValue: _questionColor,
      answerColorValue: _answerColor,
    );
  }

  Future<void> _saveSilently() async {
    final doc = _buildDoc();
    await LocalStorageService.saveDoc(doc);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _headingController.dispose();
    for (var c in _qControllers) {
      c.dispose();
    }
    for (var c in _aControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'Assignment Title...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onChanged: (_) => _saveSilently(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await _saveSilently();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment saved!'), duration: Duration(seconds: 1)),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Heading Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Heading',
                            style: TextStyle(
                              color: Color(0xFF9333EA), // Purple heading text
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _headingController.clear());
                              _saveSilently();
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _headingController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)),
                        decoration: const InputDecoration(
                          hintText: 'e.g. MCSL-205 or Experiment 1',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSilently(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Question & Answer Cards List
                ...List.generate(_qControllers.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${index + 1}.',
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8), // Deep Blue
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeQA(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _qControllers[index],
                          maxLines: null,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            hintText: 'Enter question text...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => _saveSilently(),
                        ),

                        const Divider(height: 24, color: Color(0xFFE2E8F0)),

                        // Answer Header
                        Text(
                          'Answer ${index + 1}.',
                          style: const TextStyle(
                            color: Color(0xFF059669), // Emerald Green
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _aControllers[index],
                          maxLines: null,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            hintText: 'Enter answer text...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => _saveSilently(),
                        ),
                      ],
                    ),
                  );
                }),

                // Add Question & Add Diagram Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _addQA(),
                        child: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Diagram support attached')),
                          );
                        },
                        child: const Text('Add Diagram', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Continue Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await _saveSilently();
                  final currentDoc = _buildDoc();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChoosePageScreen(
                          doc: currentDoc,
                          onApply: (updated) async {
                            setState(() {
                              _paperAsset = updated.paperAsset;
                              _fontFamily = updated.fontFamily;
                              _questionColor = updated.questionColorValue;
                              _answerColor = updated.answerColorValue;
                              _hasMobileShadow = updated.hasMobileShadow;
                            });
                            await LocalStorageService.saveDoc(updated);
                            await PdfExportService.printOrSharePdf(updated);
                          },
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
