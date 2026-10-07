import 'package:flutter/material.dart';
import '../models/preset_options.dart';
import '../models/assignment_doc.dart';

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
  int _colorTab = 0; // 0: Question, 1: Answer
  int _activeSheet = 0; // 0: none, 1: Background, 2: Writing, 3: Pen Color, 4: Effects

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
          // Live Dynamic Preview Canvas (No Cutoff, AspectRatio 1 : 1.414)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AspectRatio(
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          // 1. Paper Background (Uncut, Fill Full Dimensions)
                          Positioned.fill(
                            child: Image.asset(
                              _selectedPaper,
                              fit: BoxFit.fill,
                            ),
                          ),

                          // 2. Real Mobile Shadow Effect (PE.jpeg with multiply blend)
                          if (_hasMobileShadow)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.45,
                                child: Image.asset(
                                  'assets/images/PE.jpeg',
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),

                          // 3. User's Real Content
                          Padding(
                            padding: const EdgeInsets.only(top: 48, left: 38, right: 28, bottom: 28),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.doc.heading.isNotEmpty) ...[
                                    Center(
                                      child: Text(
                                        widget.doc.heading,
                                        style: TextStyle(
                                          fontFamily: _selectedFont,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(_selectedQColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  if (widget.doc.docType == 'general') ...[
                                    Text(
                                      widget.doc.generalContent.isEmpty
                                          ? 'Start writing your document text...'
                                          : widget.doc.generalContent,
                                      style: TextStyle(
                                        fontFamily: _selectedFont,
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Color(_selectedAColor),
                                      ),
                                    ),
                                  ] else ...[
                                    if (widget.doc.items.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        child: Text(
                                          'No questions added yet. Go back to add questions.',
                                          style: TextStyle(
                                            fontFamily: _selectedFont,
                                            fontSize: 14,
                                            color: Color(_selectedAColor),
                                          ),
                                        ),
                                      )
                                    else
                                      ...List.generate(widget.doc.items.length, (i) {
                                        final item = widget.doc.items[i];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Q${i + 1}. ${item.question}',
                                                style: TextStyle(
                                                  fontFamily: _selectedFont,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(_selectedQColor),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Ans. ${item.answer}',
                                                style: TextStyle(
                                                  fontFamily: _selectedFont,
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: Color(_selectedAColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ],
                              ),
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

          // Active Drawer / Customization Sheet
          if (_activeSheet > 0) _buildActiveSheet(),

          // Bottom 4 Tab Buttons (Background, Writing, Pen Color, Effects)
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
                        isActive: _activeSheet == 1,
                        onTap: () => setState(() => _activeSheet = _activeSheet == 1 ? 0 : 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        icon: Icons.text_fields,
                        label: 'Writing',
                        isActive: _activeSheet == 2,
                        onTap: () => setState(() => _activeSheet = _activeSheet == 2 ? 0 : 2),
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
                        isActive: _activeSheet == 3,
                        onTap: () => setState(() => _activeSheet = _activeSheet == 3 ? 0 : 3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        icon: Icons.phone_android,
                        label: 'Effects',
                        isActive: _activeSheet == 4,
                        onTap: () => setState(() => _activeSheet = _activeSheet == 4 ? 0 : 4),
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
                    ),
                    onPressed: () {
                      final updated = _generateUpdatedDoc();
                      widget.onApply(updated);
                      Navigator.pop(context);
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
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
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
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFCBD5E1))),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _activeSheet == 1
                    ? 'Background'
                    : _activeSheet == 2
                        ? 'Writing'
                        : _activeSheet == 3
                            ? 'Pen Color'
                            : 'Effects',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF1E293B)),
                onPressed: () => setState(() => _activeSheet = 0),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Background Picker (Horizontal)
          if (_activeSheet == 1)
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: PaperTemplateOption.allPapers.length,
                itemBuilder: (ctx, i) {
                  final p = PaperTemplateOption.allPapers[i];
                  final isSelected = _selectedPaper == p.assetPath;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPaper = p.assetPath),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                          width: isSelected ? 2.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Image.asset(p.assetPath, fit: BoxFit.fill, width: 80, height: 110),
                            if (isSelected)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 2. Writing Font Picker (Horizontal)
          if (_activeSheet == 2)
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: HandwritingFontOption.allFonts.length,
                itemBuilder: (ctx, i) {
                  final f = HandwritingFontOption.allFonts[i];
                  final isSelected = _selectedFont == f.fontFamily;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFont = f.fontFamily),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              'Demo Text',
                              style: TextStyle(
                                fontFamily: f.fontFamily,
                                fontSize: 16,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. Pen Color Picker (Question vs Answer Tabs)
          if (_activeSheet == 3) ...[
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _colorTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _colorTab == 0 ? const Color(0xFF2563EB) : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Question',
                        style: TextStyle(
                          color: _colorTab == 0 ? const Color(0xFF2563EB) : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _colorTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _colorTab == 1 ? const Color(0xFF2563EB) : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Answer',
                        style: TextStyle(
                          color: _colorTab == 1 ? const Color(0xFF2563EB) : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _inkPalette.map((col) {
                final currentTarget = _colorTab == 0 ? _selectedQColor : _selectedAColor;
                final isSelected = currentTarget == col.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_colorTab == 0) {
                        _selectedQColor = col.toARGB32();
                      } else {
                        _selectedAColor = col.toARGB32();
                      }
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: col,
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
          ],

          // 4. Effects Picker (Mobile Shadow Toggle with Checkmark)
          if (_activeSheet == 4)
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _hasMobileShadow = !_hasMobileShadow);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _hasMobileShadow ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                      width: _hasMobileShadow ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/PH.jpg',
                            width: 64,
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.phone_android, size: 50, color: Colors.blue),
                          ),
                          if (_hasMobileShadow)
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mobile Shadow',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _hasMobileShadow ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => setState(() => _activeSheet = 0),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
