import 'package:flutter/material.dart';
import '../models/assignment_doc.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import 'choose_page_screen.dart';

class CreateGeneralDocumentScreen extends StatefulWidget {
  final AssignmentDoc? initialDoc;

  const CreateGeneralDocumentScreen({super.key, this.initialDoc});

  @override
  State<CreateGeneralDocumentScreen> createState() => _CreateGeneralDocumentScreenState();
}

class _CreateGeneralDocumentScreenState extends State<CreateGeneralDocumentScreen> {
  late String _id;
  late TextEditingController _titleController;
  late TextEditingController _headingController;
  late TextEditingController _contentController;

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
    _contentController = TextEditingController(text: d?.generalContent ?? '');

    _paperAsset = d?.paperAsset ?? 'assets/images/ruled.jpg';
    _fontFamily = d?.fontFamily ?? 'intentlyR1';
    _questionColor = d?.questionColorValue ?? 0xFF0D47A1;
    _answerColor = d?.answerColorValue ?? 0xFF1A237E;
    _hasMobileShadow = d?.hasMobileShadow ?? false;
  }

  AssignmentDoc _buildDoc() {
    return AssignmentDoc(
      id: _id,
      title: _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim(),
      docType: 'general',
      heading: _headingController.text.trim(),
      generalContent: _contentController.text,
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
    _contentController.dispose();
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
            hintText: 'Document Title...',
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
                    const SnackBar(content: Text('Document saved!'), duration: Duration(seconds: 1)),
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
                      const Text(
                        'Heading',
                        style: TextStyle(
                          color: Color(0xFF9333EA),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      TextField(
                        controller: _headingController,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)),
                        decoration: const InputDecoration(
                          hintText: 'Document title / heading...',
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

                // Content Card
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Content',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            hintText: 'Start writing your document text...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _saveSilently(),
                        ),
                      ),
                    ],
                  ),
                ),
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
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
