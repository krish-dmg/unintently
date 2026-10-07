import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../models/preset_options.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/cloudflare_ai_service.dart';
import '../theme/app_theme.dart';

class CreateDocumentScreen extends StatefulWidget {
  final AssignmentModel? initialAssignment;

  const CreateDocumentScreen({super.key, this.initialAssignment});

  @override
  State<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends State<CreateDocumentScreen> {
  late String _id;
  late TextEditingController _titleController;
  late TextEditingController _headingController;
  late TextEditingController _contentController;

  late String _fontFamily;
  late double _fontSize;
  late double _lineSpacing;
  late double _letterSpacing;
  late Color _fontColor;
  late String _paperAsset;
  late double _leftMargin;
  late double _topMargin;

  bool _isAiGenerating = false;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAssignment;
    _id = a?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleController = TextEditingController(text: a?.title ?? 'Untitled Assignment');
    _headingController = TextEditingController(text: a?.heading ?? '');
    _contentController = TextEditingController(
      text: a?.content ??
          'Write or paste your assignment text here, or use the AI Assistant to generate answers directly.\n\nEverything renders with your custom handwriting font on authentic paper.',
    );

    _fontFamily = a?.fontFamily ?? 'intentlyR1';
    _fontSize = a?.fontSize ?? 19.0;
    _lineSpacing = a?.lineSpacing ?? 1.6;
    _letterSpacing = a?.letterSpacing ?? 0.5;
    _fontColor = Color(a?.fontColorValue ?? 0xFF1A237E);
    _paperAsset = a?.paperAsset ?? 'assets/images/ruled.jpg';
    _leftMargin = a?.leftMargin ?? 45.0;
    _topMargin = a?.topMargin ?? 50.0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _headingController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  AssignmentModel _buildModel() {
    return AssignmentModel(
      id: _id,
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Assignment'
          : _titleController.text.trim(),
      heading: _headingController.text.trim(),
      content: _contentController.text,
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      lineSpacing: _lineSpacing,
      letterSpacing: _letterSpacing,
      fontColorValue: _fontColor.toARGB32(),
      paperAsset: _paperAsset,
      topMargin: _topMargin,
      leftMargin: _leftMargin,
    );
  }

  Future<void> _save() async {
    final model = _buildModel();
    await LocalStorageService.saveAssignment(model);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment saved locally'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showAiDialog() {
    final promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: UnintentlyTheme.primaryBlue),
              SizedBox(width: 8),
              Text('Cloudflare AI Assistant'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter an assignment question, topic, or essay prompt to generate handwriting-ready content.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Explain Newton\'s laws of motion with daily examples',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: UnintentlyTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prompt = promptController.text.trim();
                if (prompt.isEmpty) return;

                Navigator.pop(ctx);
                setState(() => _isAiGenerating = true);

                final generated = await CloudflareAiService.generateText(prompt: prompt);

                setState(() {
                  _isAiGenerating = false;
                  _contentController.text = generated;
                });
                await _save();
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Assignment Title',
          ),
          onChanged: (_) => _save(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Assistant',
            onPressed: _showAiDialog,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Export & Print PDF',
            onPressed: () async {
              await _save();
              await PdfExportService.printOrSharePdf(_buildModel());
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAiGenerating) const LinearProgressIndicator(),

          // Live Interactive Canvas Area
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1 / 1.414, // A4 ratio
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                        image: DecorationImage(
                          image: AssetImage(_paperAsset),
                          fit: BoxFit.cover,
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: _topMargin,
                        left: _leftMargin,
                        right: 30.0,
                        bottom: 30.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _headingController,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: _fontSize + 6,
                              fontWeight: FontWeight.bold,
                              color: _fontColor,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Tap to write heading...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (_) => _save(),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TextField(
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: _fontSize,
                                height: _lineSpacing,
                                letterSpacing: _letterSpacing,
                                color: _fontColor,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Start writing your assignment...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => _save(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Customization Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Selectors: Font, Paper, Color, Sizing
                Row(
                  children: [
                    // Font Selector
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _fontFamily,
                        underline: const SizedBox(),
                        items: HandwritingFontOption.allFonts.map((f) {
                          return DropdownMenuItem<String>(
                            value: f.fontFamily,
                            child: Text(
                              f.name,
                              style: TextStyle(fontFamily: f.fontFamily, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _fontFamily = val);
                            _save();
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Paper Template Selector
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _paperAsset,
                        underline: const SizedBox(),
                        items: PaperTemplateOption.allPapers.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.assetPath,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _paperAsset = val);
                            _save();
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Ink Color circles
                    Row(
                      children: UnintentlyTheme.inkColors.take(4).map((c) {
                        final isSelected = _fontColor.toARGB32() == c.toARGB32();
                        return GestureDetector(
                          onTap: () {
                            setState(() => _fontColor = c);
                            _save();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Sliders: Font Size & Line Spacing
                Row(
                  children: [
                    const Icon(Icons.format_size, size: 18, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 14.0,
                        max: 30.0,
                        onChanged: (val) {
                          setState(() => _fontSize = val);
                          _save();
                        },
                      ),
                    ),
                    const Icon(Icons.format_line_spacing, size: 18, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: _lineSpacing,
                        min: 1.2,
                        max: 2.6,
                        onChanged: (val) {
                          setState(() => _lineSpacing = val);
                          _save();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
