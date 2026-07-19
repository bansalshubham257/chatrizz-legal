import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:chatrizz/core/constants/app_constants.dart';
import 'package:chatrizz/core/utils/logger.dart';
import 'package:chatrizz/domain/entities/user.dart';

class PaymentService {
  final InAppPurchase _purchase = InAppPurchase.instance;
  StreamSubscription? _subscription;
  final StreamController<SubscriptionTier> _tierController =
      StreamController<SubscriptionTier>.broadcast();

  Stream<SubscriptionTier> get tierStream => _tierController.stream;

  Future<void> init() async {
    final available = await _purchase.isAvailable();
    if (!available) {
      Logger.w('In-app purchases not available');
      return;
    }
    _subscription = _purchase.purchaseStream.listen(_handlePurchase);
  }

  Future<void> purchasePlus() async {
    await _buyProduct(AppConstants.plusProductId);
  }

  Future<void> purchasePro() async {
    await _buyProduct(AppConstants.proProductId);
  }

  Future<void> _buyProduct(String productId) async {
    try {
      final productDetails = await _purchase.queryProductDetails({productId});
      if (productDetails.productDetails.isEmpty) {
        Logger.e('Product not found: $productId');
        return;
      }
      final purchaseParam = PurchaseParam(
        productDetails: productDetails.productDetails.first,
      );
      await _purchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      Logger.e('Purchase error', error: e);
    }
  }

  void _handlePurchase(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        _verifyAndDeliver(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        Logger.e('Purchase error: ${purchase.error}');
      }
      if (purchase.pendingCompletePurchase) {
        _purchase.completePurchase(purchase);
      }
    }
  }

  void _verifyAndDeliver(PurchaseDetails purchase) {
    final tier = switch (purchase.productID) {
      AppConstants.plusProductId => SubscriptionTier.plus,
      AppConstants.proProductId => SubscriptionTier.pro,
      _ => SubscriptionTier.free,
    };
    _tierController.add(tier);
  }

  Future<void> restorePurchase() async {
    try {
      await _purchase.restorePurchases();
    } catch (e) {
      Logger.e('Restore error', error: e);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _tierController.close();
  }
}
