import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription.dart';

class SubscriptionService {
  // Vyplň po vytvoření aplikace v RevenueCat dashboardu
  static const _iosApiKey = 'appl_ExrHqdcMLwCdbVgslgBfABoATwN';
  static const _androidApiKey = 'goog_YOUR_ANDROID_KEY_HERE';

  // Entitlement identifikátory v RevenueCat dashboardu
  static const String entitlementBasic = 'basic';
  static const String entitlementPro = 'pro';

  // Identifikátory balíčků v RevenueCat offering "default"
  static const String pkgBasicMonthly = 'basic_monthly';
  static const String pkgBasicSixMonth = 'basic_halfyear';
  static const String pkgBasicAnnual = 'basic_yearly';
  static const String pkgProMonthly = 'pro_monthly';
  static const String pkgProSixMonth = 'pro_halfyear';
  static const String pkgProAnnual = 'pro_yearly';

  static Future<void> configure() async {
    final config = PurchasesConfiguration(
      Platform.isIOS ? _iosApiKey : _androidApiKey,
    );
    await Purchases.configure(config);
  }

  static Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  static Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  static Future<SubscriptionStatus> getStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return statusFromInfo(info);
    } catch (_) {
      return SubscriptionStatus.none;
    }
  }

  static SubscriptionStatus statusFromInfo(CustomerInfo info) {
    final active = info.entitlements.active;
    if (active.containsKey(entitlementPro)) {
      return SubscriptionStatus(
        plan: SubscriptionPlan.pro,
        isTrialing: active[entitlementPro]!.periodType == PeriodType.trial,
      );
    }
    if (active.containsKey(entitlementBasic)) {
      return SubscriptionStatus(
        plan: SubscriptionPlan.basic,
        isTrialing: active[entitlementBasic]!.periodType == PeriodType.trial,
      );
    }
    return SubscriptionStatus.none;
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo> purchasePackage(Package package) =>
      Purchases.purchasePackage(package);

  static Future<CustomerInfo> restorePurchases() =>
      Purchases.restorePurchases();
}
