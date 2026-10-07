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
    this.questionColorValue = 0xFF0D47A1, // Blue
    this.answerColorValue = 0xFF1A237E,   // Navy / Ink
    this.paperAsset = 'assets/images/ruled.jpg',
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
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AssignmentDoc.fromMap(Map<String, dynamic> map) => AssignmentDoc(
    id: map['id'] ?? '',
    title: map['title'] ?? 'Untitled Assignment',
    docType: map['docType'] ?? 'qa',
    heading: map['heading'] ?? '',
    items: (map['items'] as List<dynamic>?)
            ?.map((i) => QAItem.fromMap(i as Map<String, dynamic>))
            .toList() ??
        [],
    generalContent: map['generalContent'] ?? '',
    fontFamily: map['fontFamily'] ?? 'intentlyR1',
    fontSize: (map['fontSize'] as num?)?.toDouble() ?? 17.0,
    lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.6,
    questionColorValue: map['questionColorValue'] ?? 0xFF0D47A1,
    answerColorValue: map['answerColorValue'] ?? 0xFF1A237E,
    paperAsset: map['paperAsset'] ?? 'assets/images/ruled.jpg',
    isCompleted: map['isCompleted'] ?? false,
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
        : DateTime.now(),
  );

  String toJson() => json.encode(toMap());
  factory AssignmentDoc.fromJson(String source) =>
      AssignmentDoc.fromMap(json.decode(source));
}
