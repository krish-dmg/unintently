import 'package:flutter/material.dart';
import '../models/preset_options.dart';

class ChoosePageScreen extends StatefulWidget {
  final String currentPaper;
  final String currentFont;
  final int currentQuestionColor;
  final int currentAnswerColor;
  final Function(String paper, String font, int qColor, int aColor) onApply;

  const ChoosePageScreen({
    super.key,
    required this.currentPaper,
    required this.currentFont,
    required this.currentQuestionColor,
    required this.currentAnswerColor,
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
  int _colorTab = 0; // 0 for Question, 1 for Answer

  // 0: none, 1: Background, 2: Writing, 3: Pen Color, 4: Effects
  int _activeSheet = 0;

  final List<Color> _inkPalette = [
    const Color(0xFF0D47A1), // Deep Blue
    const Color(0xFF4A148C), // Violet
    const Color(0xFF2979FF), // Bright Blue
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF000000), // Black
    const Color(0xFF00C853), // Green
  ];

  @override
  void initState() {
    super.initState();
    _selectedPaper = widget.currentPaper;
    _selectedFont = widget.currentFont;
    _selectedQColor = widget.currentQuestionColor;
    _selectedAColor = widget.currentAnswerColor;
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
          // Live Page Preview
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: AspectRatio(
                  aspectRatio: 1 / 1.414,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(_selectedPaper),
                        fit: BoxFit.cover,
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 45, left: 35, right: 25, bottom: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Intently Demo',
                            style: TextStyle(
                              fontFamily: _selectedFont,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(_selectedQColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'What is this?',
                          style: TextStyle(
                            fontFamily: _selectedFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(_selectedQColor),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This is demo preview page. You can customize background, handwriting style, and pen colors below.',
                          style: TextStyle(
                            fontFamily: _selectedFont,
                            fontSize: 14,
                            color: Color(_selectedAColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Active Sheet Drawer / Selection Area
          if (_activeSheet > 0) _buildActiveSheet(),

          // Bottom 4-Button Action Grid (Background, Writing, Pen Color, Effects)
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
                      widget.onApply(
                        _selectedPaper,
                        _selectedFont,
                        _selectedQColor,
                        _selectedAColor,
                      );
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
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
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
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _activeSheet = 0),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Background Picker
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
                            Image.asset(p.assetPath, fit: BoxFit.cover, width: 80, height: 110),
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

          // Writing Font Picker
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
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Demo Text',
                        style: TextStyle(
                          fontFamily: f.fontFamily,
                          fontSize: 16,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Pen Color Picker (Question vs Answer Tabs)
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
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Question',
                        style: TextStyle(
                          color: _colorTab == 0 ? const Color(0xFF2563EB) : Colors.grey,
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
                            width: 2,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Answer',
                        style: TextStyle(
                          color: _colorTab == 1 ? const Color(0xFF2563EB) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: col.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],

          // Effects Picker
          if (_activeSheet == 4)
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/PE.jpeg', width: 64, height: 64, errorBuilder: (ctx, err, stack) => const Icon(Icons.phone_android, size: 50)),
                  const SizedBox(height: 6),
                  const Text('Mobile Shadow', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          const SizedBox(height: 12),
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
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
