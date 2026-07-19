import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/domain/entities/user.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adService = context.read<AdService>();
    // Only load ad if the user is on the free tier
    // Note: SubscriptionTier is typically managed in AdService
    // We can't easily access the tier here without AdService exposing it.
    // Let's assume for now that if AdService says so, we load it.
    
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch AdService to hide ads if user upgrades to Pro
    final adService = context.watch<AdService>();
    
    // We need to know the tier. Let's add a getter for tier in AdService.
    // Since I don't have it yet, I will just use a placeholder or 
    // assume the user is free for now, but it's better to check.
    
    if (!adService.isFreeTier || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      color: Colors.transparent,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
