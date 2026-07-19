import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chatrizz/domain/entities/user.dart';
import 'package:chatrizz/domain/repositories/subscription_repository.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';

class SettingsController extends ChangeNotifier {
  final SubscriptionRepository _subscriptionRepository;
  final LocalDataSource _localDataSource;

  SubscriptionTier _tier = SubscriptionTier.free;
  bool _isLoading = true;
  String _language = 'English';
  ThemeMode _themeMode = ThemeMode.system;

  StreamSubscription? _subSub;

  SettingsController(this._subscriptionRepository, this._localDataSource) {
    _init();
  }

  SubscriptionTier get tier => _tier;
  bool get isLoading => _isLoading;
  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get isFree => _tier == SubscriptionTier.free;
  bool get isPlus => _tier == SubscriptionTier.plus;
  bool get isPro => _tier == SubscriptionTier.pro;

  void _init() {
    _subSub = _subscriptionRepository.getSubscriptionStatus().listen((tier) {
      _tier = tier;
      _isLoading = false;
      notifyListeners();
    });

    final user = _localDataSource.getUser();
    if (user != null) {
      _language = user.language;
    }

    final themeModeString = _localDataSource.getThemeMode();
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> updateLanguage(String lang) async {
    _language = lang;
    notifyListeners();

    final user = _localDataSource.getUser();
    if (user != null) {
      final updated = user.copyWith(language: lang);
      await _localDataSource.saveUser(updated);
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _localDataSource.saveThemeMode(mode.name);
  }

  Future<void> subscribePlus() async {
    await _subscriptionRepository.purchasePlus();
  }

  Future<void> subscribePro() async {
    await _subscriptionRepository.purchasePro();
  }

  @override
  void dispose() {
    _subSub?.cancel();
    super.dispose();
  }
}
