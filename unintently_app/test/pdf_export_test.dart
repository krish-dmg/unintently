import 'package:flutter_test/flutter_test.dart';
import 'package:unintently/models/assignment_doc.dart';
import 'package:unintently/services/layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AssignmentLayoutEngine paginates QA documents cleanly', () {
    final doc = AssignmentDoc(
      id: 'test-1',
      title: 'C and Python Lab',
      heading: 'MCSL-205',
      items: [
        QAItem(
          question: 'Using Structures write an interactive program in C language to create an application program for a small office to maintain the employee database.',
          answer: 'Program to Maintain Employee Database using Structures in C. Objective: To create a menu-driven program for managing employee records using structures.',
        ),
        QAItem(
          question: 'Write a python code to read a dataset and print all features.',
          answer: 'Program to Read CSV Dataset and Compute Descriptive Statistics.',
        ),
      ],
      paperAsset: 'assets/images/ruled1.jpg',
    );

    final metrics = PaperMetrics.forAsset(doc.paperAsset);
    expect(metrics.maxLines, 25);
    expect(metrics.firstLineTopRatio, closeTo(0.1731, 0.001));

    final pages = AssignmentLayoutEngine.paginateDoc(doc, metrics);
    expect(pages.isNotEmpty, true);
    expect(pages[0].length <= metrics.maxLines, true);
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
}
