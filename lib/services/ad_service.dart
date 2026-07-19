import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:chatrizz/core/utils/logger.dart';
import 'package:chatrizz/domain/entities/user.dart';

class AdService extends ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInitialized = false;
  bool _bannerAdLoaded = false;
  SubscriptionTier _tier = SubscriptionTier.free;
  int _sessionActions = 0;

  static const String bannerAdUnitId = 'ca-app-pub-1394062189372273/9743401291'; // production
  static const String interstitialAdUnitId = 'ca-app-pub-1394062189372273/1881644605'; // production
  static const String rewardedAdUnitId = 'ca-app-pub-1394062189372273/5950927723'; // production

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadBannerAd();
      _loadInterstitialAd();
    } catch (e) {
      Logger.e('AdMob init error', error: e);
    }
  }

  void updateTier(SubscriptionTier tier) {
    _tier = tier;
    if (tier != SubscriptionTier.free) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _bannerAdLoaded = false;
    } else {
      loadBannerAd();
    }
    notifyListeners();
  }

  bool get isFreeTier => _tier == SubscriptionTier.free;

  BannerAd? get bannerAd => _tier == SubscriptionTier.free && _bannerAdLoaded ? _bannerAd : null;

  Future<void> loadBannerAd() async {
    if (_tier != SubscriptionTier.free) return;
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerAdLoaded = true;
          Logger.d('Banner ad loaded');
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          _bannerAdLoaded = false;
          Logger.e('Banner ad failed: $error');
          ad.dispose();
          _bannerAd = null;
          notifyListeners();
        },
      ),
    )..load();
  }

  Future<bool> showInterstitialIfNeeded() async {
    if (_tier != SubscriptionTier.free) return false;
    _sessionActions++;
    if (_sessionActions < 5) return false;

    _sessionActions = 0;
    if (_interstitialAd == null) return false;

    await _interstitialAd!.show();
    _loadInterstitialAd();
    return true;
  }

  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => _loadInterstitialAd(),
            onAdFailedToShowFullScreenContent: (ad, _) => _loadInterstitialAd(),
          );
        },
        onAdFailedToLoad: (error) => Logger.e('Interstitial load failed: $error'),
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: AdService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {
            completer.complete(true);
          });
        },
        onAdFailedToLoad: (error) {
          Logger.e('Rewarded ad failed: $error');
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
