import 'dart:convert';

class AssignmentModel {
  final String id;
  String title;
  String heading;
  String content;
  String fontFamily;
  double fontSize;
  double lineSpacing;
  double letterSpacing;
  int fontColorValue; // ARGB
  String paperAsset;
  double topMargin;
  double bottomMargin;
  double leftMargin;
  double rightMargin;
  DateTime createdAt;
  DateTime updatedAt;

  AssignmentModel({
    required this.id,
    required this.title,
    this.heading = '',
    required this.content,
    this.fontFamily = 'intentlyR1',
    this.fontSize = 18.0,
    this.lineSpacing = 1.6,
    this.letterSpacing = 0.5,
    this.fontColorValue = 0xFF1A237E, // Classic royal blue ink
    this.paperAsset = 'assets/images/ruled.jpg',
    this.topMargin = 50.0,
    this.bottomMargin = 30.0,
    this.leftMargin = 45.0,
    this.rightMargin = 30.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'heading': heading,
      'content': content,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'letterSpacing': letterSpacing,
      'fontColorValue': fontColorValue,
      'paperAsset': paperAsset,
      'topMargin': topMargin,
      'bottomMargin': bottomMargin,
      'leftMargin': leftMargin,
      'rightMargin': rightMargin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Assignment',
      heading: map['heading'] ?? '',
      content: map['content'] ?? '',
      fontFamily: map['fontFamily'] ?? 'intentlyR1',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.6,
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.5,
      fontColorValue: map['fontColorValue'] ?? 0xFF1A237E,
      paperAsset: map['paperAsset'] ?? 'assets/images/ruled.jpg',
      topMargin: (map['topMargin'] as num?)?.toDouble() ?? 50.0,
      bottomMargin: (map['bottomMargin'] as num?)?.toDouble() ?? 30.0,
      leftMargin: (map['leftMargin'] as num?)?.toDouble() ?? 45.0,
      rightMargin: (map['rightMargin'] as num?)?.toDouble() ?? 30.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory AssignmentModel.fromJson(String source) =>
      AssignmentModel.fromMap(json.decode(source));
}
