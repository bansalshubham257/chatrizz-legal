import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:chatrizz/domain/entities/match.dart';
import 'package:chatrizz/domain/repositories/match_repository.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/core/constants/app_constants.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/services/api_service.dart';

class MatchListController extends ChangeNotifier {
  final MatchRepository _matchRepository;
  final LocalDataSource _localDataSource;
  final AdService _adService;
  final ApiService _apiService;
  StreamSubscription? _subscription;
  StreamSubscription? _apiSub;
  List<MatchEntity> _matches = [];
  bool _isLoading = true;
  int _credits = AppConstants.freeCredits;
  int _pendingAdRewards = 0;

  MatchListController(this._matchRepository, this._localDataSource, this._adService, this._apiService) {
    _init();
  }

  List<MatchEntity> get matches => _matches;
  bool get isLoading => _isLoading;
  int get matchCount => _matches.length;
  int get credits => _credits;
  int get pendingAdRewards => _pendingAdRewards;

  void _init() {
    _loadCredits();
    _apiSub = _apiService.addListener(_loadCredits);
    _localDataSource.changeNotifier.addListener(_onDataChanged);
    _subscription = _matchRepository.getMatches().listen((matches) {
      _matches = matches;
      _isLoading = false;
      notifyListeners();
    });
  }

  void _onDataChanged() {
    _loadCredits();
  }

  void _loadCredits() {
    _credits = _apiService.credits;
    notifyListeners();
  }

  void refreshCredits() {
    _apiService.refreshCredits();
    _loadCredits();
  }

  Future<int> watchAdForCredits() async {
    final earned = await _adService.showRewardedAd();
    if (!earned) return 0;

    _pendingAdRewards++;
    if (_pendingAdRewards >= AppConstants.rewardedAdsForTopUp) {
      final ok = await _apiService.addCredits(AppConstants.creditTopUpAmount);
      if (ok) _credits = _apiService.credits;
      _pendingAdRewards = 0;
      notifyListeners();
      return AppConstants.creditTopUpAmount;
    }
    notifyListeners();
    return -_pendingAdRewards;
  }

  Future<void> deleteMatch(String id) async {
    await _matchRepository.deleteMatch(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _apiSub?.cancel();
    _localDataSource.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }
}
