import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chatrizz/core/utils/logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters?.cast<String, Object>());
    } catch (e) {
      Logger.e('Analytics error', error: e);
    }
  }

  Future<void> logMatchAdded() => logEvent('match_added');
  Future<void> logReplyGenerated({required int matchCount}) =>
      logEvent('reply_generated', parameters: {'match_count': matchCount});
  Future<void> logCreditsUsed() => logEvent('credits_used');
  Future<void> logAdsWatched() => logEvent('rewarded_ad_watched');
  Future<void> logSubscriptionPurchased({required String tier}) =>
      logEvent('subscription_purchased', parameters: {'tier': tier});
  Future<void> logScreenshotImported() => logEvent('screenshot_imported');
  Future<void> logProfileAnalyzed() => logEvent('profile_analyzed');

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}
