import 'dart:convert';

class QAItem {
  String question;
  String answer;

  QAItem({required this.question, required this.answer});

  Map<String, dynamic> toMap() => {
    'question': question,
    'answer': answer,
  };

  factory QAItem.fromMap(Map<String, dynamic> map) => QAItem(
    question: map['question'] ?? '',
    answer: map['answer'] ?? '',
  );
}

class AssignmentDoc {
  final String id;
  String title;
  String docType; // 'qa' or 'general'
  String heading;
  List<QAItem> items; // For Question & Answers
  String generalContent; // For General small document
  String fontFamily;
  double fontSize;
  double lineSpacing;
  int questionColorValue;
  int answerColorValue;
  String paperAsset;
  bool hasMobileShadow;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;

  AssignmentDoc({
    required this.id,
    required this.title,
    this.docType = 'qa',
    this.heading = '',
    List<QAItem>? items,
    this.generalContent = '',
    this.fontFamily = 'intentlyR1',
    this.fontSize = 17.0,
    this.lineSpacing = 1.6,
    this.questionColorValue = 0xFF0D47A1, // Deep Blue
    this.answerColorValue = 0xFF1A237E,   // Navy / Ink
    this.paperAsset = 'assets/images/ruled1.jpg',
    this.hasMobileShadow = false,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'docType': docType,
    'heading': heading,
    'items': items.map((i) => i.toMap()).toList(),
    'generalContent': generalContent,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineSpacing': lineSpacing,
    'questionColorValue': questionColorValue,
    'answerColorValue': answerColorValue,
    'paperAsset': paperAsset,
    'hasMobileShadow': hasMobileShadow,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static List<QAItem> _parseItems(dynamic rawItems) {
    if (rawItems is! List) return [];

    bool isLegacy = rawItems.any((e) =>
        e is Map && (e.containsKey('from') || e.containsKey('value')));

    if (isLegacy) {
      final List<QAItem> parsed = [];
      String pendingQuestion = '';

      for (final e in rawItems) {
        if (e is! Map) continue;
        final from = (e['from'] ?? '').toString().toLowerCase();
        final val = (e['value'] ?? '').toString().replaceAll(RegExp(r'<[^>]*>'), '').trim();

        if (from == 'human' || from == 'user') {
          if (pendingQuestion.isNotEmpty) {
            parsed.add(QAItem(question: pendingQuestion, answer: ''));
          }
          pendingQuestion = val;
        } else if (from == 'gpt' || from == 'assistant') {
          parsed.add(QAItem(question: pendingQuestion.isEmpty ? 'Question' : pendingQuestion, answer: val));
          pendingQuestion = '';
        } else {
          // General entry
          if (pendingQuestion.isNotEmpty) {
            parsed.add(QAItem(question: pendingQuestion, answer: val));
            pendingQuestion = '';
          } else {
            parsed.add(QAItem(question: 'Question', answer: val));
          }
        }
      }
      if (pendingQuestion.isNotEmpty) {
        parsed.add(QAItem(question: pendingQuestion, answer: ''));
      }
      return parsed;
    }

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map((i) => QAItem.fromMap(i))
        .toList();
  }

  factory AssignmentDoc.fromMap(Map<String, dynamic> rawMap) {
    final Map<String, dynamic> map = (rawMap['assignment'] is Map<String, dynamic>)
        ? rawMap['assignment'] as Map<String, dynamic>
        : rawMap;

    return AssignmentDoc(
      id: (map['id'] != null && map['id'].toString().isNotEmpty)
          ? map['id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? 'Untitled Assignment',
      docType: map['docType'] ?? 'qa',
      heading: map['heading'] ?? (map['title'] ?? ''),
      items: _parseItems(map['items']),
      generalContent: map['generalContent'] ?? '',
      fontFamily: map['fontFamily'] ?? 'intentlyR1',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 17.0,
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.6,
      questionColorValue: map['questionColorValue'] ?? 0xFF0D47A1,
      answerColorValue: map['answerColorValue'] ?? 0xFF1A237E,
      paperAsset: map['paperAsset'] ?? 'assets/images/ruled1.jpg',
      hasMobileShadow: map['hasMobileShadow'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory AssignmentDoc.fromJson(String source) =>
      AssignmentDoc.fromMap(json.decode(source));
}
