import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: unused_import — v0.3 で AppSku.allSkus を使用予定
import '../constants/sku.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  /// IAP 初期化（v0.3で実装）
  Future<void> initialize() async {
    // TODO: InAppPurchase.instance.isAvailable() チェック
    // TODO: purchaseStream のリスン開始
    // TODO: 商品情報の取得（AppSku.allSkus を使用）
  }

  /// 購入フロー開始（v0.3で実装）
  Future<void> buyProduct(String skuId) async {
    // TODO: InAppPurchase.instance.buyNonConsumable / buyConsumable
  }

  /// 購入復元（v0.3で実装）
  Future<void> restorePurchases() async {
    // TODO: InAppPurchase.instance.restorePurchases()
  }

  /// レシート検証（v0.3で実装）
  Future<bool> verifyPurchase(PurchaseDetails details) async {
    // TODO: ローカル検証 or サーバー検証
    return false;
  }

  /// リソース解放
  void dispose() {
    // TODO: StreamSubscription のキャンセル
  }
}
