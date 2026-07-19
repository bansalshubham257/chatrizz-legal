class MatchEntity {
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

  const MatchEntity({
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

  MatchEntity copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    String? imageUrl,
    String? location,
    List<String>? interests,
    String? notes,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastActivityDate,
  }) {
    return MatchEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      notes: notes ?? this.notes,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}
