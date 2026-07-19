import 'package:chatrizz/domain/entities/match.dart';

class MatchModel {
  final String id;
  final String name;
  final int? age;
  final String? bio;
  final String? imageUrl;
  final String? location;
  final List<String> interests;
  final String? notes;
  final String? platform;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastActivityDate;

  const MatchModel({
    required this.id,
    required this.name,
    this.age,
    this.bio,
    this.imageUrl,
    this.location,
    this.interests = const [],
    this.notes,
    this.platform,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastActivityDate,
  });

  factory MatchModel.fromEntity(MatchEntity entity) {
    return MatchModel(
      id: entity.id,
      name: entity.name,
      age: entity.age,
      bio: entity.bio,
      imageUrl: entity.imageUrl,
      location: entity.location,
      interests: entity.interests,
      notes: entity.notes,
      platform: entity.platform,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastMessage: entity.lastMessage,
      lastActivityDate: entity.lastActivityDate,
    );
  }

  MatchEntity toEntity() {
    return MatchEntity(
      id: id,
      name: name,
      age: age,
      bio: bio,
      imageUrl: imageUrl,
      location: location,
      interests: interests,
      notes: notes,
      platform: platform,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessage: lastMessage,
      lastActivityDate: lastActivityDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'bio': bio,
    'imageUrl': imageUrl,
    'location': location,
    'interests': interests,
    'notes': notes,
    'platform': platform,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastMessage': lastMessage,
    'lastActivityDate': lastActivityDate?.toIso8601String(),
  };

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int?,
    bio: json['bio'] as String?,
    imageUrl: json['imageUrl'] as String?,
    location: json['location'] as String?,
    interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
    notes: json['notes'] as String?,
    platform: json['platform'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lastMessage: json['lastMessage'] as String?,
    lastActivityDate: json['lastActivityDate'] != null
        ? DateTime.parse(json['lastActivityDate'] as String)
        : null,
  );
}
