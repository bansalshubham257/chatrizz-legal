class MemoryEntity {
  final String id;
  final String matchId;
  final String content;
  final MemoryCategory category;
  final DateTime createdAt;
  final bool isImportant;

  const MemoryEntity({
    required this.id,
    required this.matchId,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isImportant = false,
  });
}

enum MemoryCategory {
  interest,
  job,
  hobby,
  travel,
  pet,
  favorite,
  personal,
  other;

  String get label {
    switch (this) {
      case MemoryCategory.interest:
        return 'Interest';
      case MemoryCategory.job:
        return 'Job';
      case MemoryCategory.hobby:
        return 'Hobby';
      case MemoryCategory.travel:
        return 'Travel';
      case MemoryCategory.pet:
        return 'Pet';
      case MemoryCategory.favorite:
        return 'Favorite';
      case MemoryCategory.personal:
        return 'Personal';
      case MemoryCategory.other:
        return 'Other';
    }
  }
}
