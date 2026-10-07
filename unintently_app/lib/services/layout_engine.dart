import '../models/assignment_doc.dart';

class PaperMetrics {
  final double firstLineTopRatio;
  final double lineSpacingRatio;
  final double leftMarginRatio;
  final double rightMarginRatio;
  final double headerTopRatio;
  final int maxLines;

  const PaperMetrics({
    required this.firstLineTopRatio,
    required this.lineSpacingRatio,
    required this.leftMarginRatio,
    required this.rightMarginRatio,
    required this.headerTopRatio,
    required this.maxLines,
  });

  static PaperMetrics forAsset(String assetPath) {
    if (assetPath.contains('ruled5')) {
      // 1604x2680: double red header at 0.0843, line 1 at text start: 0.1103, pitch 0.03172
      return const PaperMetrics(
        firstLineTopRatio: 0.1103,
        lineSpacingRatio: 0.03172,
        leftMarginRatio: 0.150,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.045,
        maxLines: 27,
      );
    } else if (assetPath.contains('ruled4')) {
      // 1448x2392: double red header at 0.0857, line 1 at text start: 0.1052, pitch 0.02926
      return const PaperMetrics(
        firstLineTopRatio: 0.1052,
        lineSpacingRatio: 0.02926,
        leftMarginRatio: 0.160,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.045,
        maxLines: 27,
      );
    } else if (assetPath.contains('ruled2')) {
      // 1684x2404: header at 0.048, line 1 at text start: 0.1202, pitch 0.02787
      return const PaperMetrics(
        firstLineTopRatio: 0.1202,
        lineSpacingRatio: 0.02787,
        leftMarginRatio: 0.160,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.048,
        maxLines: 28,
      );
    } else if (assetPath.contains('ruled3')) {
      // 1788x2204 (2-hole punch benchmark): line 1 at 0.1574, pitch 0.03196, margin 0.132, header 0.075
      return const PaperMetrics(
        firstLineTopRatio: 0.1574,
        lineSpacingRatio: 0.03196,
        leftMarginRatio: 0.132,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.075,
        maxLines: 25,
      );
    } else if (assetPath.contains('ruledAssignment')) {
      // 1164x1820: line 1 at text start: 0.1645, pitch 0.03077, margin 0.146, header 0.055
      return const PaperMetrics(
        firstLineTopRatio: 0.1645,
        lineSpacingRatio: 0.03077,
        leftMarginRatio: 0.146,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.055,
        maxLines: 25,
      );
    } else if (assetPath.contains('printRuled1') ||
        assetPath.contains('RedPage') ||
        assetPath.contains('GreyPage')) {
      // 1414x2000 (A4): top ruling line at 0.1365 -> firstLineTopRatio: 0.1320, pitch: 0.03750, margin 0.142, header 0.068
      return const PaperMetrics(
        firstLineTopRatio: 0.1320,
        lineSpacingRatio: 0.03750,
        leftMarginRatio: 0.142,
        rightMarginRatio: 0.060,
        headerTopRatio: 0.068,
        maxLines: 22,
      );
    } else if (assetPath.contains('ruled.') || assetPath.endsWith('ruled.jpg')) {
      // 910x1338: classic notebook: line 1 at 0.1380, pitch 0.03886, margin 0.125
      return const PaperMetrics(
        firstLineTopRatio: 0.1380,
        lineSpacingRatio: 0.03886,
        leftMarginRatio: 0.125,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.055,
        maxLines: 22,
      );
    } else if (assetPath.contains('blank')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.120,
        lineSpacingRatio: 0.0320,
        leftMarginRatio: 0.100,
        rightMarginRatio: 0.080,
        headerTopRatio: 0.060,
        maxLines: 26,
      );
    }
    // Default: ruled1.jpg (1504x1912) notebook with Expt. No. / Page No. / Date box
    // Line 1 at text start: 0.1668, pitch: 0.02955, margin: 0.125, header: 0.052
    return const PaperMetrics(
      firstLineTopRatio: 0.1668,
      lineSpacingRatio: 0.02955,
      leftMarginRatio: 0.125,
      rightMarginRatio: 0.065,
      headerTopRatio: 0.052,
      maxLines: 25,
    );
  }
}

class FontCalibration {
  final double scale;
  final double ascentRatio;

  const FontCalibration({required this.scale, required this.ascentRatio});

  static const Map<String, FontCalibration> _calibrations = {
    'intentlyR1': FontCalibration(scale: 1.30, ascentRatio: 1.014),
    'intentlyR2': FontCalibration(scale: 1.05, ascentRatio: 0.786),
    'intentlyR8': FontCalibration(scale: 1.40, ascentRatio: 1.001),
    'intentlyR11': FontCalibration(scale: 1.18, ascentRatio: 0.697),
    'intentlyR12': FontCalibration(scale: 0.95, ascentRatio: 0.924),
    'Writing1': FontCalibration(scale: 1.00, ascentRatio: 0.924),
    'Writing2': FontCalibration(scale: 1.25, ascentRatio: 0.812),
    'Writing3': FontCalibration(scale: 1.02, ascentRatio: 1.044),
    'Writing4': FontCalibration(scale: 1.00, ascentRatio: 0.963),
    'Writing5': FontCalibration(scale: 0.72, ascentRatio: 1.690),
    'Writing7': FontCalibration(scale: 1.12, ascentRatio: 0.795),
    'Writing8': FontCalibration(scale: 0.90, ascentRatio: 0.960),
  };

  static FontCalibration forFont(String fontFamily) {
    return _calibrations[fontFamily] ?? const FontCalibration(scale: 1.10, ascentRatio: 0.90);
  }
}

class RuledLineItem {
  final String marginLabel; // Question/Answer index placed in the left margin (e.g. Q.1, Ans.)
  final String text;        // Body text placed to the right of the margin line
  final bool isQuestion;
  final bool isBlank;

  RuledLineItem({
    this.marginLabel = '',
    required this.text,
    required this.isQuestion,
    this.isBlank = false,
  });

  factory RuledLineItem.blank() => RuledLineItem(marginLabel: '', text: '', isQuestion: false, isBlank: true);
}

class AssignmentLayoutEngine {
  static const int maxCharsPerLine = 44;

  static List<List<RuledLineItem>> paginateDoc(AssignmentDoc doc, PaperMetrics metrics) {
    final List<RuledLineItem> allLines = [];

    if (doc.docType == 'general') {
      final text = doc.generalContent.trim().isEmpty && doc.items.isEmpty
          ? 'Intently General Document\n\nThis is a demo preview of your handwriting document. Customize the paper background, handwriting font, pen color, and shadow effects using the options below.\n\nEverything you write is rendered with realistic pen strokes perfectly aligned to the notebook rulings.'
          : doc.generalContent;

      final paragraphs = text.split('\n');
      for (final para in paragraphs) {
        if (para.trim().isEmpty) {
          allLines.add(RuledLineItem.blank());
          continue;
        }
        final wrapped = _wrapWords(para.trim(), maxCharsPerLine);
        for (final line in wrapped) {
          allLines.add(RuledLineItem(marginLabel: '', text: line, isQuestion: false));
        }
      }
    } else {
      // Q&A document
      final List<QAItem> activeItems = doc.items.isNotEmpty
          ? doc.items
          : [
              QAItem(
                question: 'What is this?',
                answer: 'This is intently demo Question Answers page. On this page you can choose the configuration of the pages which will reflect in your pdf.',
              ),
              QAItem(
                question: 'How to Customize page?',
                answer: 'You can customize from the options given below like:-\n1. Background  2. Writing  3. Pen Color  4. Effects',
              ),
              QAItem(
                question: 'Have any questions?',
                answer: 'Ask us on our social media pages.',
              ),
            ];

      for (int i = 0; i < activeItems.length; i++) {
        final item = activeItems[i];
        final qNum = i + 1;

        // Clean user input if they already typed "Q1." or "Question 1:" or "Q."
        String qText = item.question.trim();
        qText = qText.replaceFirst(
          RegExp(r'^(?:Q(?:uestion)?\s*\.?\s*\d*[\.\:\-\)]\s*|Q\s*[\:\.]\s*)', caseSensitive: false),
          '',
        ).trim();

        if (qText.isNotEmpty) {
          final wrappedQ = _wrapWords(qText, maxCharsPerLine);
          for (int lIdx = 0; lIdx < wrappedQ.length; lIdx++) {
            allLines.add(RuledLineItem(
              marginLabel: (lIdx == 0) ? 'Q.$qNum' : '',
              text: wrappedQ[lIdx],
              isQuestion: true,
            ));
          }
        }

        String aText = item.answer.trim();
        aText = aText.replaceFirst(
          RegExp(r'^(?:Ans(?:wer)?\s*\.?\s*\d*[\.\:\-\)]\s*|Ans\s*[\:\.]\s*)', caseSensitive: false),
          '',
        ).trim();

        // Question and Answer sit on consecutive lines matching student notebook layout

        if (aText.isNotEmpty) {
          final aLines = aText.split('\n');
          bool isFirstAnswerLine = true;
          for (final aPara in aLines) {
            if (aPara.trim().isEmpty) {
              allLines.add(RuledLineItem.blank());
              continue;
            }
            final wrappedA = _wrapWords(aPara.trim(), maxCharsPerLine);
            for (final line in wrappedA) {
              allLines.add(RuledLineItem(
                marginLabel: isFirstAnswerLine ? 'Ans.' : '',
                text: line,
                isQuestion: false,
              ));
              isFirstAnswerLine = false;
            }
          }
        }

        // Add 1 blank ruled line between questions as a spacer
        if (i < activeItems.length - 1) {
          allLines.add(RuledLineItem.blank());
        }
      }
    }

    if (allLines.isEmpty) {
      return [[]];
    }

    final List<List<RuledLineItem>> pages = [];
    final int linesPerPage = metrics.maxLines;

    for (int i = 0; i < allLines.length; i += linesPerPage) {
      final end = (i + linesPerPage < allLines.length) ? i + linesPerPage : allLines.length;
      pages.add(allLines.sublist(i, end));
    }

    return pages;
  }

  static List<String> _wrapWords(String text, int maxChars) {
    final List<String> lines = [];
    final words = text.split(' ');
    String current = '';

    for (final word in words) {
      if (word.isEmpty) continue;
      if (current.isEmpty) {
        if (word.length > maxChars) {
          lines.add(word.substring(0, maxChars));
          current = word.substring(maxChars);
        } else {
          current = word;
        }
      } else if (current.length + 1 + word.length <= maxChars) {
        current += ' $word';
      } else {
        lines.add(current);
        if (word.length > maxChars) {
          lines.add(word.substring(0, maxChars));
          current = word.substring(maxChars);
        } else {
          current = word;
        }
      }
    }

    if (current.isNotEmpty) {
      lines.add(current);
    }

    return lines;
  }
}
