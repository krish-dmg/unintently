class HandwritingFontOption {
  final String id;
  final String name;
  final String fontFamily;
  final String styleDescription;

  const HandwritingFontOption({
    required this.id,
    required this.name,
    required this.fontFamily,
    required this.styleDescription,
  });

  static const List<HandwritingFontOption> allFonts = [
    HandwritingFontOption(
      id: 'intentlyR1',
      name: 'Intently Signature',
      fontFamily: 'intentlyR1',
      styleDescription: 'Natural, flowing cursive student script',
    ),
    HandwritingFontOption(
      id: 'intentlyR2',
      name: 'Intently Fast Hand',
      fontFamily: 'intentlyR2',
      styleDescription: 'Quick note-taking style',
    ),
    HandwritingFontOption(
      id: 'intentlyR8',
      name: 'Intently Clean',
      fontFamily: 'intentlyR8',
      styleDescription: 'Neat and structured cursive',
    ),
    HandwritingFontOption(
      id: 'intentlyR11',
      name: 'Intently Exam Pen',
      fontFamily: 'intentlyR11',
      styleDescription: 'Dense exam handwriting',
    ),
    HandwritingFontOption(
      id: 'intentlyR12',
      name: 'Intently Journal',
      fontFamily: 'intentlyR12',
      styleDescription: 'Relaxed ballpoint script',
    ),
    HandwritingFontOption(
      id: 'writing1',
      name: 'Classic Script 1',
      fontFamily: 'Writing1',
      styleDescription: 'Standard ruled notebook script',
    ),
    HandwritingFontOption(
      id: 'writing2',
      name: 'Classic Script 2',
      fontFamily: 'Writing2',
      styleDescription: 'Smooth fluid ink style',
    ),
    HandwritingFontOption(
      id: 'writing3',
      name: 'Classic Script 3',
      fontFamily: 'Writing3',
      styleDescription: 'Calligraphic flourished penmanship',
    ),
    HandwritingFontOption(
      id: 'writing4',
      name: 'Gel Pen Quick',
      fontFamily: 'Writing4',
      styleDescription: 'Everyday ballpoint handwriting',
    ),
    HandwritingFontOption(
      id: 'writing5',
      name: 'Casual Student',
      fontFamily: 'Writing5',
      styleDescription: 'Informal classroom notes',
    ),
    HandwritingFontOption(
      id: 'writing7',
      name: 'Practical Lab File',
      fontFamily: 'Writing7',
      styleDescription: 'Sharp technical script',
    ),
    HandwritingFontOption(
      id: 'writing8',
      name: 'Homework Pen',
      fontFamily: 'Writing8',
      styleDescription: 'Neat high-school assignment hand',
    ),
  ];
}

class PaperTemplateOption {
  final String id;
  final String name;
  final String assetPath;
  final String typeDescription;

  const PaperTemplateOption({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.typeDescription,
  });

  static const List<PaperTemplateOption> allPapers = [
    PaperTemplateOption(
      id: 'ruled_classic',
      name: 'Classic Ruled',
      assetPath: 'assets/images/ruled.jpg',
      typeDescription: 'Standard blue ruled notebook lines',
    ),
    PaperTemplateOption(
      id: 'ruled_1',
      name: 'College Ruled 1',
      assetPath: 'assets/images/ruled1.jpg',
      typeDescription: 'Narrow college ruled lines',
    ),
    PaperTemplateOption(
      id: 'ruled_2',
      name: 'College Ruled 2',
      assetPath: 'assets/images/ruled2.jpg',
      typeDescription: 'Realistic paper texture lines',
    ),
    PaperTemplateOption(
      id: 'ruled_3',
      name: 'Wide Ruled 3',
      assetPath: 'assets/images/ruled3.jpg',
      typeDescription: 'Wide spaced school lines',
    ),
    PaperTemplateOption(
      id: 'ruled_4',
      name: 'Notebook Margin 4',
      assetPath: 'assets/images/ruled4.jpg',
      typeDescription: 'Red margin ruled register',
    ),
    PaperTemplateOption(
      id: 'ruled_5',
      name: 'Heavy Paper 5',
      assetPath: 'assets/images/ruled5.jpg',
      typeDescription: 'Parchment toned ruled paper',
    ),
    PaperTemplateOption(
      id: 'ruled_assignment',
      name: 'Assignment Sheet',
      assetPath: 'assets/images/ruledAssignment.jpeg',
      typeDescription: 'Formal assignment layout sheet',
    ),
    PaperTemplateOption(
      id: 'blank_white',
      name: 'Blank White A4',
      assetPath: 'assets/images/blankWhite.jpg',
      typeDescription: 'Clean plain white unruled paper',
    ),
    PaperTemplateOption(
      id: 'blank_natural',
      name: 'Blank Natural',
      assetPath: 'assets/images/blank.jpeg',
      typeDescription: 'Soft ivory plain unruled sheet',
    ),
    PaperTemplateOption(
      id: 'grey_page',
      name: 'Grey Recycled',
      assetPath: 'assets/images/GreyPage.png',
      typeDescription: 'Grey craft notebook paper',
    ),
    PaperTemplateOption(
      id: 'print_ruled',
      name: 'Print Ready Ruled',
      assetPath: 'assets/images/printRuled1.png',
      typeDescription: 'High-contrast ruled printing sheet',
    ),
  ];
}
