import 'package:chatrizz/core/constants/app_constants.dart';

enum SubscriptionTier { free, plus, pro }

class UserEntity {
  final String id;
  final String name;
  final int credits;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final bool darkMode;
  final bool notificationsEnabled;
  final String language;
  final List<String> categories;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    this.credits = AppConstants.freeCredits,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.darkMode = true,
    this.notificationsEnabled = true,
    this.language = 'English',
    this.categories = const ['Funny', 'Flirty', 'Bold', 'General', 'Casual'],
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    int? credits,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    bool? darkMode,
    bool? notificationsEnabled,
    String? language,
    List<String>? categories,
    DateTime? createdAt,
  }) {
    return UserEntity(
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
}
