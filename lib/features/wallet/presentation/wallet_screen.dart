import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_ui.dart';
import '../../security/providers/privacy_provider.dart';
import '../domain/models/account.dart';
import '../domain/models/credit_model.dart';
import '../domain/models/recurring_payment.dart';
import '../providers/accounts_provider.dart';
import '../providers/credits_provider.dart';
import '../providers/recurring_payments_provider.dart';
import 'widgets/add_account_bottom_sheet.dart';
import 'widgets/add_credit_bottom_sheet.dart';
import 'widgets/add_recurring_payment_bottom_sheet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _selectedSegment = 0; // 0: Subscriptions, 1: Loans
  int _cardPage = 0;
  late final PageController _cardsController;

  static const _pad = EdgeInsets.symmetric(horizontal: 20);

  @override
  void initState() {
    super.initState();
    _cardsController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _cardsController.dispose();
    super.dispose();
  }

  void _openSheet(Widget sheet) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => sheet);
  }

  /// Everything shown per month, whatever the billing interval is.
  double _monthlyCost(List<RecurringPaymentModel> payments) {
    return payments.fold(0.0, (sum, p) {
      switch (p.interval) {
        case PaymentInterval.weekly:
          return sum + p.amount * 52 / 12;
        case PaymentInterval.monthly:
          return sum + p.amount;
        case PaymentInterval.yearly:
          return sum + p.amount / 12;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final accounts = ref.watch(accountsProvider);
    final recurring = ref.watch(recurringPaymentsProvider);
    final credits = ref.watch(creditsProvider);
    final hide = ref.watch(privacyProvider);

    final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);
    final totalDebt = credits.fold(0.0, (sum, c) => sum + (c.totalAmount - c.paidAmount));
    final netWorth = totalBalance - totalDebt;

    return SafeArea(
      bottom: false,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: _pad, child: _buildHeader()).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 18),
              Padding(
                padding: _pad,
                child: _buildNetWorth(currency, hide, netWorth, totalBalance, totalDebt),
              ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
              const SizedBox(height: 22),
              _buildCards(accounts, currency, hide).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
              const SizedBox(height: 26),
              Padding(padding: _pad, child: _buildSegments(recurring.length, credits.length)).animate().fadeIn(delay: 240.ms, duration: 400.ms),
              const SizedBox(height: 18),
              Padding(
                padding: _pad,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _selectedSegment == 0 ? _buildSubscriptions(recurring, currency, hide) : _buildLoans(credits, currency, hide),
                ),
              ),
              const SizedBox(height: 130), // room to scroll past the floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header + net worth
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Wallet', style: GoogleFonts.manrope(color: appInk(context), fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
        GestureDetector(
          onTap: () => _openSheet(const AddAccountBottomSheet()),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: appIsDark(context) ? AppTheme.lime : AppTheme.ink, shape: BoxShape.circle),
            child: Icon(Icons.add_rounded, color: appIsDark(context) ? AppTheme.ink : AppTheme.lime, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildNetWorth(String currency, bool hide, double netWorth, double assets, double debt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Net worth', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 14.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppMoney(
            amount: netWorth,
            currency: currency,
            hide: hide,
            sign: netWorth < 0 ? '-' : '',
            decimalsAlpha: 0.28,
            style: GoogleFonts.manrope(color: appInk(context), fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.5),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatPill(icon: Icons.north_east_rounded, iconBg: AppTheme.lime, iconFg: AppTheme.ink, label: 'Assets', value: _short(assets, currency, hide)),
            const SizedBox(width: 10),
            _StatPill(
              icon: Icons.south_east_rounded,
              iconBg: Theme.of(context).colorScheme.error.withValues(alpha: 0.14),
              iconFg: Theme.of(context).colorScheme.error,
              label: 'Debt',
              value: _short(debt, currency, hide),
            ),
          ],
        ),
      ],
    );
  }

  String _short(double amount, String currency, bool hide) => hide ? '${MoneyFormat.prefix(currency)}••••' : '${MoneyFormat.prefix(currency)}${MoneyFormat.rounded(amount)}';

  // ---------------------------------------------------------------------------
  // Accounts carousel
  // ---------------------------------------------------------------------------

  Widget _buildCards(List<AccountModel> accounts, String currency, bool hide) {
    final pages = accounts.length + 1; // last page is always "add account"
    return Column(
      children: [
        SizedBox(
          height: 204,
          child: PageView.builder(
            controller: _cardsController,
            padEnds: false,
            physics: const ClampingScrollPhysics(),
            itemCount: pages,
            onPageChanged: (i) => setState(() => _cardPage = i),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 20, right: 0),
              child: index == accounts.length ? _buildAddAccountCard() : _buildAccountCard(accounts[index], currency, hide),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < pages; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _cardPage ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _cardPage ? appInk(context) : appInk(context).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountCard(AccountModel account, String currency, bool hide) {
    final base = account.colorValue != null ? Color(account.colorValue!) : AppTheme.ink;
    final hsl = HSLColor.fromColor(base);
    final deep = hsl.withLightness((hsl.lightness * 0.82).clamp(0.0, 1.0)).toColor();
    final fg = appOnColor(base);
    final isDefault = account.colorValue == null;

    return GestureDetector(
      onLongPress: () => _showAccountOptions(account),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, deep])),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                bottom: -70,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: (isDefault ? AppTheme.lime : fg).withValues(alpha: isDefault ? 0.2 : 0.14), width: 24)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: isDefault ? AppTheme.lime : fg.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                          child: Icon(IconUtils.getIconData(account.icon ?? ''), color: isDefault ? AppTheme.ink : fg, size: 21),
                        ),
                        IconButton(
                          onPressed: () => _showAccountOptions(account),
                          icon: Icon(Icons.more_horiz_rounded, color: fg.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: fg.withValues(alpha: 0.72), fontSize: 14.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AppMoney(
                            amount: account.balance.abs(),
                            currency: currency,
                            hide: hide,
                            sign: account.balance < 0 ? '-' : '',
                            decimalsAlpha: 0.5,
                            style: GoogleFonts.manrope(color: fg, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddAccountCard() {
    return GestureDetector(
      onTap: () => _openSheet(const AddAccountBottomSheet()),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: appIsDark(context) ? 0.5 : 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: appInk(context).withValues(alpha: 0.14), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppTheme.lime, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: AppTheme.ink, size: 30),
              ),
              const SizedBox(height: 14),
              Text('Add account', style: GoogleFonts.manrope(color: appInk(context), fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Cash, card or savings', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountOptions(AccountModel account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: appInk(context).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 22),
            Text(account.name, style: GoogleFonts.manrope(color: appInk(context), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 18),
            _OptionRow(
              icon: Icons.edit_outlined,
              label: 'Edit account',
              onTap: () {
                Navigator.pop(sheetContext);
                _openSheet(AddAccountBottomSheet(accountToEdit: account));
              },
            ),
            const SizedBox(height: 10),
            _OptionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete account',
              danger: true,
              onTap: () {
                Navigator.pop(sheetContext);
                ref.read(accountsProvider.notifier).removeAccount(account.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segments + lists
  // ---------------------------------------------------------------------------

  Widget _buildSegments(int subsCount, int loansCount) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: appIsDark(context) ? const Color(0xFF2A2A2D) : AppTheme.ink, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          _segment('Subscriptions', subsCount, 0, Icons.autorenew_rounded),
          _segment('Loans', loansCount, 1, Icons.account_balance_outlined),
        ],
      ),
    );
  }

  Widget _segment(String title, int count, int index, IconData icon) {
    final selected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: selected ? AppTheme.lime : Colors.transparent, borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? AppTheme.ink : Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.manrope(color: selected ? AppTheme.ink : Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w800)),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: selected ? AppTheme.ink : Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                  child: Text('$count', style: GoogleFonts.manrope(color: selected ? AppTheme.lime : Colors.white.withValues(alpha: 0.8), fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "Monthly cost  $25.98" on the left, a lime "+ Add" on the right.
  Widget _summaryRow({required String label, required double amount, required String currency, required bool hide, required String addLabel, required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.manrope(color: appMuted(context), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            AppMoney(amount: amount, currency: currency, hide: hide, style: GoogleFonts.manrope(color: appInk(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          ],
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.lime, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 18, color: AppTheme.ink),
                const SizedBox(width: 4),
                Text(addLabel, style: GoogleFonts.manrope(color: AppTheme.ink, fontSize: 13.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptions(List<RecurringPaymentModel> payments, String currency, bool hide) {
    if (payments.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('subs-empty'),
        icon: Icons.autorenew_rounded,
        title: 'No subscriptions yet',
        desc: 'Keep track of Netflix, Spotify and every bill that repeats.',
        button: 'Add subscription',
        onAdd: () => _openSheet(const AddRecurringPaymentBottomSheet()),
      );
    }

    return Column(
      key: const ValueKey('subs'),
      children: [
        _summaryRow(
          label: 'Monthly cost',
          amount: _monthlyCost(payments),
          currency: currency,
          hide: hide,
          addLabel: 'Add',
          onAdd: () => _openSheet(const AddRecurringPaymentBottomSheet()),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: appCardDecoration(context),
            child: Column(
              children: [
                for (int i = 0; i < payments.length; i++) _buildSubscriptionRow(payments[i], currency, hide, divider: i != payments.length - 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionRow(RecurringPaymentModel payment, String currency, bool hide, {required bool divider}) {
    final soon = payment.nextPaymentDate.difference(DateTime.now()).inDays <= 2;
    final interval = payment.interval.name[0].toUpperCase() + payment.interval.name.substring(1);

    return Dismissible(
      key: Key(payment.id),
      direction: DismissDirection.endToStart,
      background: _dismissBackground(radius: 0),
      onDismissed: (_) => ref.read(recurringPaymentsProvider.notifier).removePayment(payment.id),
      child: Column(
        children: [
          InkWell(
            onTap: () => _openSheet(AddRecurringPaymentBottomSheet(paymentToEdit: payment)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AppIconTile(icon: IconUtils.getIconData(payment.icon), lime: soon, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: appInk(context), fontSize: 15.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('Next ${DateFormat('MMM d').format(payment.nextPaymentDate)} · $interval', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppMoney(amount: payment.amount, currency: currency, hide: hide, style: GoogleFonts.manrope(color: appInk(context), fontSize: 15.5, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          if (divider) Divider(height: 1, indent: 76, endIndent: 16, color: appHairline(context)),
        ],
      ),
    );
  }

  Widget _buildLoans(List<CreditModel> credits, String currency, bool hide) {
    if (credits.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('loans-empty'),
        icon: Icons.verified_outlined,
        title: 'Debt-free',
        desc: 'No active loans. Add one to follow your payments and what is left to pay.',
        button: 'Add loan',
        onAdd: () => _openSheet(const AddCreditBottomSheet()),
      );
    }

    final monthly = credits.fold(0.0, (sum, c) => sum + c.monthlyContribution);
    return Column(
      key: const ValueKey('loans'),
      children: [
        _summaryRow(
          label: 'Monthly payments',
          amount: monthly,
          currency: currency,
          hide: hide,
          addLabel: 'Add',
          onAdd: () => _openSheet(const AddCreditBottomSheet()),
        ),
        const SizedBox(height: 14),
        for (final credit in credits) _buildLoanCard(credit, currency, hide),
      ],
    );
  }

  Widget _buildLoanCard(CreditModel credit, String currency, bool hide) {
    final progress = credit.progress;
    final dark = appIsDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(credit.id),
        direction: DismissDirection.endToStart,
        background: _dismissBackground(radius: 24),
        onDismissed: (_) => ref.read(creditsProvider.notifier).removeCredit(credit.id),
        child: GestureDetector(
          onTap: () => _openSheet(AddCreditBottomSheet(creditToEdit: credit)),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: appCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIconTile(icon: IconUtils.getIconData(credit.icon), size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(credit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: appInk(context), fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('Next payment ${DateFormat('MMM d').format(credit.nextPaymentDate)}', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppMoney(amount: credit.monthlyContribution, currency: currency, hide: hide, style: GoogleFonts.manrope(color: appInk(context), fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('per month', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppProgressBar(value: progress, fill: dark ? AppTheme.lime : AppTheme.ink),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hide ? '${(progress * 100).floor()}% paid' : '${MoneyFormat.prefix(currency)}${MoneyFormat.compact(credit.paidAmount)} paid · ${(progress * 100).floor()}%',
                      style: GoogleFonts.manrope(color: appInk(context), fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      hide ? '' : 'of ${MoneyFormat.prefix(currency)}${MoneyFormat.compact(credit.totalAmount)}',
                      style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required Key key, required IconData icon, required String title, required String desc, required String button, required VoidCallback onAdd}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: appCardDecoration(context),
      child: Column(
        children: [
          AppIconTile(icon: icon, size: 64),
          const SizedBox(height: 18),
          Text(title, style: GoogleFonts.manrope(color: appInk(context), fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.manrope(color: appMuted(context), fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(color: AppTheme.lime, borderRadius: BorderRadius.circular(22)),
              child: Text(button, style: GoogleFonts.manrope(color: AppTheme.ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dismissBackground({required double radius}) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;

  const _StatPill({required this.icon, required this.iconBg, required this.iconFg, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(22), boxShadow: appIsDark(context) ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 5))]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconFg, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.manrope(color: appMuted(context), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text(value, style: GoogleFonts.manrope(color: appInk(context), fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _OptionRow({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : appInk(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: appCardDecoration(context, radius: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: danger ? color.withValues(alpha: 0.12) : AppTheme.lime, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: danger ? color : AppTheme.ink, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.manrope(color: color, fontSize: 15.5, fontWeight: FontWeight.w800))),
            Icon(Icons.chevron_right_rounded, color: appMuted(context)),
          ],
        ),
      ),
    );
  }
}
