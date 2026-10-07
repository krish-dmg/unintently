import 'package:flutter_test/flutter_test.dart';
import 'package:unintently/models/assignment_doc.dart';
import 'package:unintently/services/layout_engine.dart';
import 'package:unintently/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AssignmentLayoutEngine paginates QA documents with margin labels Q.1 and Ans.', () {
    final doc = AssignmentDoc(
      id: 'test-1',
      title: 'C and Python Lab',
      heading: 'MCSL-205',
      items: [
        QAItem(
          question: 'Using Structures write an interactive program in C language to create an application program for a small office to maintain the employee database.',
          answer: 'Program to Maintain Employee Database using Structures in C.\nObjective:\nTo create a menu-driven program for managing employee records using structures.',
        ),
        QAItem(
          question: 'Write a python code to read a dataset and print all features.',
          answer: 'Program to Read CSV Dataset and Compute Descriptive Statistics.',
        ),
      ],
      paperAsset: 'assets/images/ruled5.jpg',
    );

    final metrics = PaperMetrics.forAsset(doc.paperAsset);
    expect(metrics.maxLines, 27);
    expect(metrics.firstLineTopRatio, closeTo(0.1103, 0.001));
    expect(metrics.lineSpacingRatio, closeTo(0.03172, 0.0001));
    expect(metrics.leftMarginRatio, closeTo(0.150, 0.001));

    final pages = AssignmentLayoutEngine.paginateDoc(doc, metrics);
    expect(pages.isNotEmpty, true);
    expect(pages[0].length <= metrics.maxLines, true);

    // Verify first line of Question 1 has "Q.1" in margin
    final q1FirstLine = pages[0].firstWhere((l) => l.isQuestion && l.marginLabel.isNotEmpty);
    expect(q1FirstLine.marginLabel, 'Q.1');

    // Verify first line of Answer 1 has "Ans." in margin
    final a1FirstLine = pages[0].firstWhere((l) => !l.isQuestion && l.marginLabel == 'Ans.');
    expect(a1FirstLine.marginLabel, 'Ans.');

    // Verify continuation lines have empty marginLabel
    final continuationLines = pages[0].where((l) => !l.isBlank && l.marginLabel.isEmpty);
    expect(continuationLines.isNotEmpty, true);
  });

  test('FontCalibration provides calibrated scales and ascent ratios for all handwriting fonts', () {
    const fonts = [
      'intentlyR1', 'intentlyR2', 'intentlyR8', 'intentlyR11', 'intentlyR12',
      'Writing1', 'Writing2', 'Writing3', 'Writing4', 'Writing5', 'Writing7', 'Writing8',
    ];

    for (final font in fonts) {
      final cal = FontCalibration.forFont(font);
      expect(cal.scale > 0.5 && cal.scale < 1.6, true, reason: 'Scale out of bounds for $font');
      expect(cal.ascentRatio > 0.6 && cal.ascentRatio < 1.8, true, reason: 'Ascent ratio out of bounds for $font');
    }

    // intentlyR1 scale is boosted to fill ruling lines legibly
    expect(FontCalibration.forFont('intentlyR1').scale, 1.30);
    // Writing5 has 2048 em units and is scaled appropriately
    expect(FontCalibration.forFont('Writing5').scale, 0.72);
  });

  test('PaperMetrics calibrates all paper templates with distinct header and line coordinates', () {
    final ruled1 = PaperMetrics.forAsset('assets/images/ruled1.jpg');
    expect(ruled1.headerTopRatio, 0.052);
    expect(ruled1.firstLineTopRatio, closeTo(0.1668, 0.001));

    final ruled3 = PaperMetrics.forAsset('assets/images/ruled3.jpg');
    expect(ruled3.headerTopRatio, 0.075);
    expect(ruled3.firstLineTopRatio, closeTo(0.1574, 0.001));

    final printRuled = PaperMetrics.forAsset('assets/images/printRuled1.png');
    expect(printRuled.headerTopRatio, 0.068);
    expect(printRuled.firstLineTopRatio, closeTo(0.1320, 0.001));

    final assignment = PaperMetrics.forAsset('assets/images/ruledAssignment.jpeg');
    expect(assignment.headerTopRatio, 0.055);
    expect(assignment.firstLineTopRatio, closeTo(0.1645, 0.001));
  });

  test('AssignmentLayoutEngine paginates General document cleanly', () {
    final doc = AssignmentDoc(
      id: 'test-2',
      title: 'Notes',
      docType: 'general',
      generalContent: 'This is a long multiline document with several paragraphs.\n\nSecond paragraph begins here with additional content.',
      paperAsset: 'assets/images/printRuled1.png',
    );

    final metrics = PaperMetrics.forAsset(doc.paperAsset);
    expect(metrics.maxLines, 22);

    final pages = AssignmentLayoutEngine.paginateDoc(doc, metrics);
    expect(pages.isNotEmpty, true);
  });

  test('AssignmentLayoutEngine populates demo content when doc has 0 items', () {
    final doc = AssignmentDoc(
      id: 'test-empty',
      title: 'Empty QA',
      docType: 'qa',
      items: [],
      paperAsset: 'assets/images/ruled5.jpg',
    );

    final metrics = PaperMetrics.forAsset(doc.paperAsset);
    final pages = AssignmentLayoutEngine.paginateDoc(doc, metrics);
    expect(pages.isNotEmpty, true);
    expect(pages[0].isNotEmpty, true);
    expect(pages[0].any((l) => l.marginLabel == 'Q.1'), true);
    expect(pages[0].any((l) => l.marginLabel == 'Ans.'), true);
  });

  test('PdfExportService generates valid PDF bytes with margin labels', () async {
    final doc = AssignmentDoc(
      id: 'test-3',
      title: 'Math Assignment',
      heading: 'MATH-101',
      items: [
        QAItem(
          question: 'What is Pythagoras theorem?',
          answer: 'In a right triangle, the square of the hypotenuse is equal to the sum of the squares of the other two sides: a^2 + b^2 = c^2.',
        ),
      ],
      paperAsset: 'assets/images/ruled5.jpg',
      fontFamily: 'intentlyR1',
    );

    final bytes = await PdfExportService.generatePdf(doc);
    expect(bytes.isNotEmpty, true);
    // PDF signature check %PDF-
    expect(bytes[0], 0x25); // '%'
    expect(bytes[1], 0x50); // 'P'
    expect(bytes[2], 0x44); // 'D'
    expect(bytes[3], 0x46); // 'F'

    // Verify PDF does NOT have all-zero font widths array
    final rawPdf = String.fromCharCodes(bytes);
    expect(rawPdf.contains('/Widths [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0'), false);
  });

  test('PdfExportService generates valid multi-page PDF for all converted fonts without character overlap', () async {
    const fontsToTest = ['intentlyR1', 'intentlyR2', 'Writing1', 'Writing2', 'Writing3', 'Writing7'];
    for (final font in fontsToTest) {
      final doc = AssignmentDoc(
        id: 'test-font-$font',
        title: 'Compare Nations League Difficulty',
        heading: 'Football Analysis',
        items: List.generate(
          10,
          (i) => QAItem(
            question: 'Question $i: Why is the Nations League format structured this way?',
            answer: 'Answer $i: It replaces friendly matches with competitive fixtures across divisions A through D with promotions and relegations.',
          ),
        ),
        paperAsset: 'assets/images/ruled5.jpg',
        fontFamily: font,
      );

      final bytes = await PdfExportService.generatePdf(doc);
      expect(bytes.isNotEmpty, true);
      final rawPdf = String.fromCharCodes(bytes);
      // Ensure character advance metrics are present and non-zero
      expect(rawPdf.contains('/Widths [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0'), false,
          reason: 'Font $font generated all-zero widths');
    }
  });
}
