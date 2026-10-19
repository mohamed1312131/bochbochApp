/// Domain types for Customer Notes (Feature 8).
library;

class CustomerNote {
  const CustomerNote({
    required this.id,
    required this.customerId,
    required this.content,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerNote copyWith({
    String? content,
    bool? isPinned,
    DateTime? updatedAt,
  }) =>
      CustomerNote(
        id: id,
        customerId: customerId,
        content: content ?? this.content,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory CustomerNote.fromJson(Map<String, dynamic> json) => CustomerNote(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        content: json['content'] as String,
        isPinned: json['isPinned'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
