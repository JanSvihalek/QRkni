enum SubscriptionPlan { none, basic, pro }

class SubscriptionStatus {
  final SubscriptionPlan plan;
  final bool isTrialing;

  const SubscriptionStatus({required this.plan, required this.isTrialing});

  static const none = SubscriptionStatus(
    plan: SubscriptionPlan.none,
    isTrialing: false,
  );

  bool get hasAccess => plan != SubscriptionPlan.none;
  bool get isPro => plan == SubscriptionPlan.pro;

  // -1 = neomezeno
  int get workerLimit => isPro ? -1 : 3;

  // Měsíční limit QR kódů; -1 = neomezeno
  int get monthlyQrLimit => hasAccess ? -1 : 10;

  String get displayName => switch (plan) {
        SubscriptionPlan.none => 'Free',
        SubscriptionPlan.basic => 'Basic',
        SubscriptionPlan.pro => 'Pro',
      };
}
