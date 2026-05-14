import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_scan_brackets.dart';

enum _Plan { basic, pro }

enum _Interval { monthly, sixMonth, annual }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  _Plan _plan = _Plan.basic;
  _Interval _interval = _Interval.annual;
  Offerings? _offerings;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _loading = true);
    Offerings? offerings;
    try {
      offerings = await Purchases.getOfferings();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _loading = false;
      });
    }
  }

  String _pkgId(_Plan plan, _Interval interval) => switch ((plan, interval)) {
    (_Plan.basic, _Interval.monthly) => SubscriptionService.pkgBasicMonthly,
    (_Plan.basic, _Interval.sixMonth) => SubscriptionService.pkgBasicSixMonth,
    (_Plan.basic, _Interval.annual) => SubscriptionService.pkgBasicAnnual,
    (_Plan.pro, _Interval.monthly) => SubscriptionService.pkgProMonthly,
    (_Plan.pro, _Interval.sixMonth) => SubscriptionService.pkgProSixMonth,
    (_Plan.pro, _Interval.annual) => SubscriptionService.pkgProAnnual,
  };

  Package? _getPackage(_Plan plan, _Interval interval) =>
      _offerings?.current?.getPackage(_pkgId(plan, interval));

  Package? get _selectedPackage => _getPackage(_plan, _interval);

  String _savingsLabel(_Interval interval) {
    if (interval == _Interval.monthly) return '';
    final monthly = _getPackage(_plan, _Interval.monthly);
    final target = _getPackage(_plan, interval);
    if (monthly == null || target == null) return '';
    final months = interval == _Interval.sixMonth ? 6.0 : 12.0;
    final savings =
        ((1 - target.storeProduct.price / months / monthly.storeProduct.price) *
                100)
            .round();
    return savings > 0 ? '-$savings%' : '';
  }

  Future<void> _purchase() async {
    final pkg = _selectedPackage;
    if (pkg == null) return;
    setState(() => _purchasing = true);
    try {
      await SubscriptionService.purchasePackage(pkg);
    } catch (e) {
      if (!mounted) return;
      final cancelled =
          e is PurchasesError &&
          e.code == PurchasesErrorCode.purchaseCancelledError;
      if (!cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nákup se nepodařil. Zkuste to znovu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      await SubscriptionService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nákupy obnoveny.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obnova nákupů se nepodařila.')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final pkg = _selectedPackage;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const LogoScanBrackets(size: 44, color: AppColors.primaryBlue),
                const SizedBox(height: 12),
                Text(
                  'QRkni',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vyzkoušejte 30 dní zdarma',
                  style: TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Výběr plánu ─────────────────────────────────────────────────────
          _PlanToggle(
            selected: _plan,
            onChanged: (p) => setState(() => _plan = p),
          ),
          const SizedBox(height: 14),

          // ── Funkce plánu ────────────────────────────────────────────────────
          _PlanFeatureList(plan: _plan),
          const SizedBox(height: 20),

          // ── Výběr intervalu ─────────────────────────────────────────────────
          _IntervalSelector(
            selected: _interval,
            onChanged: (i) => setState(() => _interval = i),
            savingsLabel: _savingsLabel,
          ),
          const SizedBox(height: 20),

          // ── Cena ────────────────────────────────────────────────────────────
          _PriceDisplay(package: pkg, plan: _plan, interval: _interval),
          const SizedBox(height: 24),

          // ── CTA tlačítko ─────────────────────────────────────────────────────
          FilledButton(
            onPressed: (_purchasing || pkg == null) ? null : _purchase,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _purchasing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Vyzkoušet 30 dní zdarma',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // ── Obnovit nákupy ──────────────────────────────────────────────────
          Center(
            child: TextButton(
              onPressed: _purchasing ? null : _restore,
              child: const Text(
                'Obnovit nákupy',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Právní texty (App Store requirement) ────────────────────────────
          const Text(
            'Předplatné se automaticky obnoví. Zrušit lze kdykoli v nastavení účtu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.label, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink(
                text: 'Podmínky použití',
                url: 'https://qrkni.app/terms',
              ),
              const Text(
                '  ·  ',
                style: TextStyle(color: AppColors.label, fontSize: 12),
              ),
              _LegalLink(
                text: 'Ochrana soukromí',
                url: 'https://qrkni.app/privacy',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Přepínač plánu ────────────────────────────────────────────────────────────

class _PlanToggle extends StatelessWidget {
  final _Plan selected;
  final ValueChanged<_Plan> onChanged;
  const _PlanToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _PlanTab(
            label: 'Basic',
            subtitle: 'Max 3 zaměstnanci',
            selected: selected == _Plan.basic,
            onTap: () => onChanged(_Plan.basic),
          ),
          _PlanTab(
            label: 'Pro',
            subtitle: 'Neomezeno',
            selected: selected == _Plan.pro,
            onTap: () => onChanged(_Plan.pro),
          ),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTab({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: selected ? AppColors.heading : AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.primaryBlue : AppColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Funkce plánu ──────────────────────────────────────────────────────────────

class _PlanFeatureList extends StatelessWidget {
  final _Plan plan;
  const _PlanFeatureList({required this.plan});

  @override
  Widget build(BuildContext context) {
    final features = plan == _Plan.pro
        ? [
            'Neomezení zaměstnanci/brigádníci',
            'Neomezené QR platby',
            'Katalog položek',
            'Historie transakcí',
          ]
        : [
            'Max 3 zaměstnanci/brigádníci',
            'Neomezené QR platby',
            'Katalog položek',
            'Historie transakcí',
          ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(plan),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryFaint,
          border: Border.all(color: AppColors.primaryTint),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: features
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        f,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Výběr intervalu ───────────────────────────────────────────────────────────

class _IntervalSelector extends StatelessWidget {
  final _Interval selected;
  final ValueChanged<_Interval> onChanged;
  final String Function(_Interval) savingsLabel;
  const _IntervalSelector({
    required this.selected,
    required this.onChanged,
    required this.savingsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IntervalPill(
          label: 'Měsíčně',
          savings: '',
          selected: selected == _Interval.monthly,
          onTap: () => onChanged(_Interval.monthly),
        ),
        const SizedBox(width: 8),
        _IntervalPill(
          label: 'Půlroční',
          savings: savingsLabel(_Interval.sixMonth),
          selected: selected == _Interval.sixMonth,
          onTap: () => onChanged(_Interval.sixMonth),
        ),
        const SizedBox(width: 8),
        _IntervalPill(
          label: 'Roční',
          savings: savingsLabel(_Interval.annual),
          selected: selected == _Interval.annual,
          onTap: () => onChanged(_Interval.annual),
        ),
      ],
    );
  }
}

class _IntervalPill extends StatelessWidget {
  final String label;
  final String savings;
  final bool selected;
  final VoidCallback onTap;
  const _IntervalPill({
    required this.label,
    required this.savings,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                savings.isNotEmpty ? savings : ' ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Zobrazení ceny ────────────────────────────────────────────────────────────

class _PriceDisplay extends StatelessWidget {
  final Package? package;
  final _Plan plan;
  final _Interval interval;
  const _PriceDisplay({
    required this.package,
    required this.plan,
    required this.interval,
  });

  // Záložní ceny pro případ, že RevenueCat není dostupný
  static const _fallback = {
    (_Plan.basic, _Interval.monthly): ('99 Kč', 'za měsíc'),
    (_Plan.basic, _Interval.sixMonth): ('549 Kč', 'za 6 měsíců  •  91 Kč/měs'),
    (_Plan.basic, _Interval.annual): ('999 Kč', 'za rok  •  83 Kč/měs'),
    (_Plan.pro, _Interval.monthly): ('149 Kč', 'za měsíc'),
    (_Plan.pro, _Interval.sixMonth): ('799 Kč', 'za 6 měsíců  •  133 Kč/měs'),
    (_Plan.pro, _Interval.annual): ('1 499 Kč', 'za rok  •  125 Kč/měs'),
  };

  @override
  Widget build(BuildContext context) {
    String price, sub;

    if (package != null) {
      price = package!.storeProduct.priceString;
      final months = interval == _Interval.sixMonth
          ? 6.0
          : interval == _Interval.annual
          ? 12.0
          : 1.0;
      final perMonth = package!.storeProduct.price / months;
      sub = switch (interval) {
        _Interval.monthly => 'za měsíc',
        _Interval.sixMonth =>
          'za 6 měsíců  •  ${perMonth.toStringAsFixed(0)} Kč/měs',
        _Interval.annual => 'za rok  •  ${perMonth.toStringAsFixed(0)} Kč/měs',
      };
    } else {
      final fb = _fallback[(plan, interval)]!;
      price = fb.$1;
      sub = fb.$2;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey('$plan-$interval'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              price,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Právní odkaz ──────────────────────────────────────────────────────────────

class _LegalLink extends StatelessWidget {
  final String text;
  final String url;
  const _LegalLink({required this.text, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.label,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.label,
        ),
      ),
    );
  }
}
