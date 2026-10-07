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

  @override
  void initState() {
    super.initState();
    final d = widget.initialDoc;
    _id = d?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleController = TextEditingController(text: d?.title ?? 'C and Python Lab');
    _headingController = TextEditingController(text: d?.heading ?? 'MCSL-205');

    _paperAsset = d?.paperAsset ?? 'assets/images/ruledAssignment.jpeg';
    _fontFamily = d?.fontFamily ?? 'intentlyR1';
    _questionColor = d?.questionColorValue ?? 0xFF0D47A1;
    _answerColor = d?.answerColorValue ?? 0xFF1A237E;

    _qControllers = [];
    _aControllers = [];

    if (d != null && d.items.isNotEmpty) {
      for (var item in d.items) {
        _qControllers.add(TextEditingController(text: item.question));
        _aControllers.add(TextEditingController(text: item.answer));
      }
    } else {
      // Default 3 questions as seen in screenshot
      _addQA(
        q: 'Using Structures write an interactive program in C language to create an application program for a small office to maintain the employee database.',
        a: 'Program to Maintain Employee Database using Structures in C',
      );
      _addQA(
        q: 'Attempt the following: Write Program to perform following tasks: Create a database schema and insert records.',
        a: 'Program to Perform Database Operations using Python (MySQL)',
      );
      _addQA(
        q: 'Write a python code to read a dataset (may be CSV file) and print all features i.e. columns.',
        a: 'Program to Read CSV Dataset and Compute Descriptive Statistics',
      );
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
      items.add(QAItem(
        question: _qControllers[i].text.trim(),
        answer: _aControllers[i].text.trim(),
      ));
    }
    return AssignmentDoc(
      id: _id,
      title: _titleController.text.trim().isEmpty ? 'Untitled Assignment' : _titleController.text.trim(),
      docType: 'qa',
      heading: _headingController.text.trim(),
      items: items,
      fontFamily: _fontFamily,
      paperAsset: _paperAsset,
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
          decoration: const InputDecoration(border: InputBorder.none),
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
                if (mounted) {
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
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'e.g. MCSL-205',
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
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                color: Color(0xFF1D4ED8), // Blue Question
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
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Enter question here...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => _saveSilently(),
                        ),

                        const Divider(height: 24),

                        // Answer Header
                        Text(
                          'Answer ${index + 1}.',
                          style: const TextStyle(
                            color: Color(0xFF10B981), // Green Answer
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _aControllers[index],
                          maxLines: null,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Enter answer here...',
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
                          backgroundColor: const Color(0xFF0D9488), // Teal Green
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
                          backgroundColor: const Color(0xFF0D9488), // Teal Green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Diagram insertion enabled')),
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
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChoosePageScreen(
                          currentPaper: _paperAsset,
                          currentFont: _fontFamily,
                          currentQuestionColor: _questionColor,
                          currentAnswerColor: _answerColor,
                          onApply: (paper, font, qCol, aCol) async {
                            setState(() {
                              _paperAsset = paper;
                              _fontFamily = font;
                              _questionColor = qCol;
                              _answerColor = aCol;
                            });
                            await _saveSilently();
                            // Print / Export
                            await PdfExportService.printOrSharePdf(_buildDoc());
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
