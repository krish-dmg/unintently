import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:unintently/main.dart';
import 'package:unintently/models/assignment_doc.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UnintentlyApp());
  });

  test('AssignmentDoc parses modern native Q&A JSON', () {
    const jsonStr = '''
    {
      "id": "chatgpt_123",
      "title": "Data Structures Assignment",
      "docType": "qa",
      "items": [
        {"question": "Explain QuickSort", "answer": "QuickSort is a divide-and-conquer algorithm."}
      ]
    }
    ''';

    final doc = AssignmentDoc.fromJson(jsonStr);
    expect(doc.id, 'chatgpt_123');
    expect(doc.title, 'Data Structures Assignment');
    expect(doc.items.length, 1);
    expect(doc.items[0].question, 'Explain QuickSort');
    expect(doc.items[0].answer, 'QuickSort is a divide-and-conquer algorithm.');
  });

  test('AssignmentDoc parses legacy turn-by-turn format from extension', () {
    const legacyJsonStr = '''
    {
      "title": "Operating Systems Lab",
      "items": [
        {"from": "human", "value": "<p>What is a deadlock?</p>"},
        {"from": "gpt", "value": "<p>A deadlock is a situation where processes cannot proceed.</p>"},
        {"from": "human", "value": "List four conditions for deadlock"},
        {"from": "gpt", "value": "Mutual exclusion, Hold and wait, No preemption, Circular wait."}
      ]
    }
    ''';

    final doc = AssignmentDoc.fromJson(legacyJsonStr);
    expect(doc.title, 'Operating Systems Lab');
    expect(doc.items.length, 2);
    expect(doc.items[0].question, 'What is a deadlock?');
    expect(doc.items[0].answer, 'A deadlock is a situation where processes cannot proceed.');
    expect(doc.items[1].question, 'List four conditions for deadlock');
    expect(doc.items[1].answer, 'Mutual exclusion, Hold and wait, No preemption, Circular wait.');
  });

  test('AssignmentDoc parses wrapped worker payload', () {
    const wrappedJsonStr = '''
    {
      "success": true,
      "code": "UNIN-9X42A1",
      "assignment": {
        "id": "UNIN-9X42A1",
        "title": "Cloud Computing",
        "docType": "qa",
        "items": [
          {"question": "What is serverless?", "answer": "Serverless is execution on demand."}
        ]
      }
    }
    ''';

    final doc = AssignmentDoc.fromMap(json.decode(wrappedJsonStr));
    expect(doc.title, 'Cloud Computing');
    expect(doc.items.length, 1);
    expect(doc.items[0].question, 'What is serverless?');
  });
}
