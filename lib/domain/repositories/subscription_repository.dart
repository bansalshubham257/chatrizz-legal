import 'package:chatrizz/domain/entities/user.dart';

abstract class SubscriptionRepository {
  Stream<SubscriptionTier> getSubscriptionStatus();
  Future<void> purchasePlus();
  Future<void> purchasePro();
  Future<void> restorePurchase();
  Future<bool> hasActiveSubscription();
}
