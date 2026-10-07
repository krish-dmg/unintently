import 'package:flutter/material.dart';
import '../models/preset_options.dart';
import '../models/assignment_doc.dart';
import '../services/layout_engine.dart';
import '../widgets/ruled_page_preview.dart';
import 'assignment_preview_screen.dart';

class ChoosePageScreen extends StatefulWidget {
  final AssignmentDoc doc;
  final Function(AssignmentDoc updatedDoc) onApply;

  const ChoosePageScreen({
    super.key,
    required this.doc,
    required this.onApply,
  });

  @override
  State<ChoosePageScreen> createState() => _ChoosePageScreenState();
}

class _ChoosePageScreenState extends State<ChoosePageScreen> {
  late String _selectedPaper;
  late String _selectedFont;
  late int _selectedQColor;
  late int _selectedAColor;
  late bool _hasMobileShadow;
  int _previewPageIndex = 0;

  final List<Color> _inkPalette = [
    const Color(0xFF0D47A1), // Deep Navy Blue
    const Color(0xFF4A148C), // Violet Ink
    const Color(0xFF1E40AF), // Royal Blue
    const Color(0xFF1E293B), // Dark Slate
    const Color(0xFF000000), // Classic Black Ink
    const Color(0xFF047857), // Forest Green
  ];

  @override
  void initState() {
    super.initState();
    _selectedPaper = widget.doc.paperAsset;
    _selectedFont = widget.doc.fontFamily;
    _selectedQColor = widget.doc.questionColorValue;
    _selectedAColor = widget.doc.answerColorValue;
    _hasMobileShadow = widget.doc.hasMobileShadow;
  }

  AssignmentDoc _generateUpdatedDoc() {
    return AssignmentDoc(
      id: widget.doc.id,
      title: widget.doc.title,
      docType: widget.doc.docType,
      heading: widget.doc.heading,
      items: widget.doc.items,
      generalContent: widget.doc.generalContent,
      fontFamily: _selectedFont,
      fontSize: widget.doc.fontSize,
      lineSpacing: widget.doc.lineSpacing,
      questionColorValue: _selectedQColor,
      answerColorValue: _selectedAColor,
      paperAsset: _selectedPaper,
      hasMobileShadow: _hasMobileShadow,
      isCompleted: widget.doc.isCompleted,
      createdAt: widget.doc.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void _openBackgroundSheet() {
    String tempPaper = _selectedPaper;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Background',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: PaperTemplateOption.allPapers.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, idx) {
                          final paper = PaperTemplateOption.allPapers[idx];
                          final isSelected = paper.assetPath == tempPaper;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() => tempPaper = paper.assetPath);
                              setState(() => _selectedPaper = paper.assetPath);
                            },
                            child: Container(
                              width: 95,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      paper.assetPath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() => _selectedPaper = tempPaper);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openWritingSheet() {
    String tempFont = _selectedFont;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Writing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: HandwritingFontOption.allFonts.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, idx) {
                          final font = HandwritingFontOption.allFonts[idx];
                          final isSelected = font.fontFamily == tempFont;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() => tempFont = font.fontFamily);
                              setState(() => _selectedFont = font.fontFamily);
                            },
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Text(
                                      'Demo Text',
                                      style: TextStyle(
                                        fontFamily: font.fontFamily,
                                        fontSize: 20,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() => _selectedFont = tempFont);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openPenColorSheet() {
    int colorTab = 0; // 0: Question, 1: Answer
    int tempQColor = _selectedQColor;
    int tempAColor = _selectedAColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeColor = colorTab == 0 ? tempQColor : tempAColor;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pen Color',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => colorTab = 0),
                            child: Column(
                              children: [
                                Text(
                                  'Question',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorTab == 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 2.5,
                                  color: colorTab == 0 ? const Color(0xFF1D4ED8) : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => colorTab = 1),
                            child: Column(
                              children: [
                                Text(
                                  'Answer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorTab == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 2.5,
                                  color: colorTab == 1 ? const Color(0xFF1D4ED8) : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _inkPalette.map((color) {
                        final isSelected = color.toARGB32() == activeColor;
                        return GestureDetector(
                          onTap: () {
                            if (colorTab == 0) {
                              setSheetState(() => tempQColor = color.toARGB32());
                              setState(() => _selectedQColor = color.toARGB32());
                            } else {
                              setSheetState(() => tempAColor = color.toARGB32());
                              setState(() => _selectedAColor = color.toARGB32());
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 22)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedQColor = tempQColor;
                            _selectedAColor = tempAColor;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEffectsSheet() {
    bool tempShadow = _hasMobileShadow;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Effects',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() => tempShadow = !tempShadow);
                          setState(() => _hasMobileShadow = tempShadow);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: tempShadow ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                              width: tempShadow ? 2.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/PH.jpg',
                                    width: 70,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.phone_android, size: 50, color: Colors.blue),
                                  ),
                                  if (tempShadow)
                                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mobile Shadow',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tempShadow ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() => _hasMobileShadow = tempShadow);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedDoc = _generateUpdatedDoc();
    final metrics = PaperMetrics.forAsset(updatedDoc.paperAsset);
    final pages = AssignmentLayoutEngine.paginateDoc(updatedDoc, metrics);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Page',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Dynamic Preview Canvas (Stable A4 Aspect Ratio matching notebook rulings)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1 / 1.414,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: PageView.builder(
                          itemCount: pages.length,
                          onPageChanged: (idx) => setState(() => _previewPageIndex = idx),
                          itemBuilder: (context, idx) {
                            return RuledPagePreview(
                              doc: updatedDoc,
                              pageIndex: idx,
                              pages: pages,
                              metrics: metrics,
                            );
                          },
                        ),
                      ),
                    ),
                    if (pages.length > 1) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Page ${_previewPageIndex + 1} of ${pages.length}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls: 4 Tab Buttons + Save Changes (Matching Reference 5661a3ba)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        icon: Icons.layers,
                        label: 'Background',
                        onTap: _openBackgroundSheet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        icon: Icons.text_fields,
                        label: 'Writing',
                        onTap: _openWritingSheet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        icon: Icons.palette_outlined,
                        label: 'Pen Color',
                        onTap: _openPenColorSheet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        icon: Icons.phone_android,
                        label: 'Effects',
                        onTap: _openEffectsSheet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    onPressed: () {
                      final updated = _generateUpdatedDoc();
                      widget.onApply(updated);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentPreviewScreen(doc: updated),
                        ),
                      );
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
