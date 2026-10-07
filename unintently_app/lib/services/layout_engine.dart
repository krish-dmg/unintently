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
    if (assetPath.contains('printRuled1') ||
        assetPath.contains('RedPage') ||
        assetPath.contains('GreyPage')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.1360,
        lineSpacingRatio: 0.0375,
        leftMarginRatio: 0.145,
        rightMarginRatio: 0.060,
        headerTopRatio: 0.065,
        maxLines: 22,
      );
    } else if (assetPath.contains('ruledAssignment')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.170,
        lineSpacingRatio: 0.0308,
        leftMarginRatio: 0.145,
        rightMarginRatio: 0.065,
        headerTopRatio: 0.082,
        maxLines: 25,
      );
    } else if (assetPath.contains('ruled2')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.178,
        lineSpacingRatio: 0.0279,
        leftMarginRatio: 0.125,
        rightMarginRatio: 0.075,
        headerTopRatio: 0.085,
        maxLines: 26,
      );
    } else if (assetPath.contains('ruled3')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.172,
        lineSpacingRatio: 0.0318,
        leftMarginRatio: 0.125,
        rightMarginRatio: 0.075,
        headerTopRatio: 0.085,
        maxLines: 24,
      );
    } else if (assetPath.contains('ruled4')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.170,
        lineSpacingRatio: 0.0293,
        leftMarginRatio: 0.135,
        rightMarginRatio: 0.075,
        headerTopRatio: 0.082,
        maxLines: 26,
      );
    } else if (assetPath.contains('ruled5')) {
      return const PaperMetrics(
        firstLineTopRatio: 0.172,
        lineSpacingRatio: 0.0313,
        leftMarginRatio: 0.135,
        rightMarginRatio: 0.075,
        headerTopRatio: 0.082,
        maxLines: 25,
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
    // Default: ruled1.jpg / ruled.jpg standard notebook
    return const PaperMetrics(
      firstLineTopRatio: 0.1731,
      lineSpacingRatio: 0.02955,
      leftMarginRatio: 0.132,
      rightMarginRatio: 0.075,
      headerTopRatio: 0.086,
      maxLines: 25,
    );
  }
}

class RuledLineItem {
  final String text;
  final bool isQuestion;
  final bool isBlank;

  RuledLineItem({
    required this.text,
    required this.isQuestion,
    this.isBlank = false,
  });

  factory RuledLineItem.blank() => RuledLineItem(text: '', isQuestion: false, isBlank: true);
}

class AssignmentLayoutEngine {
  static const int maxCharsPerLine = 46;

  static List<List<RuledLineItem>> paginateDoc(AssignmentDoc doc, PaperMetrics metrics) {
    final List<RuledLineItem> allLines = [];

    if (doc.docType == 'general') {
      final paragraphs = doc.generalContent.split('\n');
      for (final para in paragraphs) {
        if (para.trim().isEmpty) {
          allLines.add(RuledLineItem.blank());
          continue;
        }
        final wrapped = _wrapWords(para, maxCharsPerLine);
        for (final line in wrapped) {
          allLines.add(RuledLineItem(text: line, isQuestion: false));
        }
      }
    } else {
      // Q&A document
      for (int i = 0; i < doc.items.length; i++) {
        final item = doc.items[i];
        if (item.question.trim().isNotEmpty) {
          final wrappedQ = _wrapWords(item.question, maxCharsPerLine);
          for (final line in wrappedQ) {
            allLines.add(RuledLineItem(text: line, isQuestion: true));
          }
        }
        if (item.answer.trim().isNotEmpty) {
          allLines.add(RuledLineItem.blank());
          final wrappedA = _wrapWords(item.answer, maxCharsPerLine);
          for (final line in wrappedA) {
            allLines.add(RuledLineItem(text: line, isQuestion: false));
          }
        }
        // Spacer between questions
        allLines.add(RuledLineItem.blank());
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
          // Hard split very long words
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
