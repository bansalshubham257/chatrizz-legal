import 'package:chatrizz/domain/entities/user.dart';
import 'package:chatrizz/core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final int credits;
  final String subscriptionTier; // 'free', 'plus', 'pro'
  final DateTime? subscriptionExpiry;
  final bool darkMode;
  final bool notificationsEnabled;
  final String language;
  final List<String> categories;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.credits = AppConstants.freeCredits,

    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.darkMode = true,
    this.notificationsEnabled = true,
    this.language = 'English',
    this.categories = const ['Funny', 'Flirty', 'Bold', 'General', 'Casual'],
    required this.createdAt,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      credits: entity.credits,
      subscriptionTier: entity.subscriptionTier.name,
      subscriptionExpiry: entity.subscriptionExpiry,
      darkMode: entity.darkMode,
      notificationsEnabled: entity.notificationsEnabled,
      language: entity.language,
      categories: entity.categories,
      createdAt: entity.createdAt,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    int? credits,
    String? subscriptionTier,
    DateTime? subscriptionExpiry,
    bool? darkMode,
    bool? notificationsEnabled,
    String? language,
    List<String>? categories,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      credits: credits,
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (t) => t.name == subscriptionTier,
        orElse: () => SubscriptionTier.free,
      ),
      subscriptionExpiry: subscriptionExpiry,
      darkMode: darkMode,
      notificationsEnabled: notificationsEnabled,
      language: language,
      categories: categories,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'credits': credits,
    'subscriptionTier': subscriptionTier,
    'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
    'darkMode': darkMode,
    'notificationsEnabled': notificationsEnabled,
    'language': language,
    'categories': categories,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
     credits: json['credits'] as int? ?? AppConstants.freeCredits,

    subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
    subscriptionExpiry: json['subscriptionExpiry'] != null
        ? DateTime.parse(json['subscriptionExpiry'] as String)
        : null,
    darkMode: json['darkMode'] as bool? ?? true,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    language: json['language'] as String? ?? 'English',
    categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? const ['Funny', 'Flirty', 'Bold', 'General', 'Casual'],
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

