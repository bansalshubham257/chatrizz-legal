import 'package:chatrizz/domain/entities/user.dart';
import 'package:chatrizz/domain/repositories/subscription_repository.dart';
import 'package:chatrizz/services/payment_service.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final PaymentService _paymentService;

  SubscriptionRepositoryImpl(this._paymentService);

  @override
  Stream<SubscriptionTier> getSubscriptionStatus() async* {
    yield SubscriptionTier.free;
    yield* _paymentService.tierStream;
  }

  @override
  Future<void> purchasePlus() async {
    await _paymentService.purchasePlus();
  }

  @override
  Future<void> purchasePro() async {
    await _paymentService.purchasePro();
  }

  @override
  Future<void> restorePurchase() async {
    await _paymentService.restorePurchase();
  }

  @override
  Future<bool> hasActiveSubscription() async {
    return false;
  }
}
