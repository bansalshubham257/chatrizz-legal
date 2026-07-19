import 'package:chatrizz/domain/entities/memory.dart';

class MemoryModel {
  final String id;
  final String matchId;
  final String content;
  final String category; // MemoryCategory as string
  final DateTime createdAt;
  final bool isImportant;

  const MemoryModel({
    required this.id,
    required this.matchId,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isImportant = false,
  });

  factory MemoryModel.fromEntity(MemoryEntity entity) {
    return MemoryModel(
      id: entity.id,
      matchId: entity.matchId,
      content: entity.content,
      category: entity.category.name,
      createdAt: entity.createdAt,
      isImportant: entity.isImportant,
    );
  }

  MemoryEntity toEntity() {
    return MemoryEntity(
      id: id,
      matchId: matchId,
      content: content,
      category: MemoryCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => MemoryCategory.other,
      ),
      createdAt: createdAt,
      isImportant: isImportant,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchId': matchId,
    'content': content,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'isImportant': isImportant,
  };

  factory MemoryModel.fromJson(Map<String, dynamic> json) => MemoryModel(
    id: json['id'] as String,
    matchId: json['matchId'] as String,
    content: json['content'] as String,
    category: json['category'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isImportant: json['isImportant'] as bool? ?? false,
  );
}
