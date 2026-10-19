import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/models/transaction.dart';

class HomeUpcomingItem {
  final String name;
  final double amount;
  final DateTime date;
  final String icon;

  const HomeUpcomingItem({required this.name, required this.amount, required this.date, required this.icon});
}

class HomeGoalSummary {
  final String title;
  final double current;
  final double target;

  const HomeGoalSummary({required this.title, required this.current, required this.target});

  double get progress => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

/// The redesigned home tab. Pure presentation: everything comes in as plain data
/// and every interaction goes out through a callback.
class HomeView extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final String currency;
  final bool hideAmounts;

  final double totalBalance;
  final int accountsCount;
  final double monthChange;
  final String monthName;

  final double? dailyBudget;
  final double todayExpenses;

  final HomeGoalSummary? goal;
  final List<HomeUpcomingItem> upcoming;
  final List<TransactionModel> recent;
  final bool showOverviewBanner;

  final VoidCallback onProfile;
  final VoidCallback onTogglePrivacy;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onEditBudget;
  final VoidCallback onOverview;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenWallet;
  final VoidCallback onSeeAllTransactions;

  const HomeView({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.currency,
    required this.hideAmounts,
    required this.totalBalance,
    required this.accountsCount,
    required this.monthChange,
    required this.monthName,
    required this.dailyBudget,
    required this.todayExpenses,
    required this.goal,
    required this.upcoming,
    required this.recent,
    required this.showOverviewBanner,
    required this.onProfile,
    required this.onTogglePrivacy,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onEditBudget,
    required this.onOverview,
    required this.onOpenGoals,
    required this.onOpenWallet,
    required this.onSeeAllTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(userName: userName, avatarUrl: avatarUrl, hideAmounts: hideAmounts, onProfile: onProfile, onTogglePrivacy: onTogglePrivacy)
                .animate()
                .fadeIn(duration: 350.ms),
            const SizedBox(height: 20),
            _BalanceCard(
              currency: currency,
              hide: hideAmounts,
              total: totalBalance,
              accountsCount: accountsCount,
              monthChange: monthChange,
              monthName: monthName,
              onTap: onOpenWallet,
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
            const SizedBox(height: 22),
            _QuickActions(
              onExpense: onAddExpense,
              onIncome: onAddIncome,
              onBudget: onEditBudget,
              onOverview: onOverview,
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
            const SizedBox(height: 22),
            _DailyBudgetCard(
              currency: currency,
              hide: hideAmounts,
              budget: dailyBudget,
              spent: todayExpenses,
              onSet: onEditBudget,
            ).animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
            if (goal != null) ...[
              const SizedBox(height: 14),
              _GoalCard(goal: goal!, currency: currency, hide: hideAmounts, onTap: onOpenGoals)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOutCubic),
            ],
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 28),
              AppSectionHeader(title: 'Upcoming payments', action: 'Manage', onAction: onOpenWallet),
              const SizedBox(height: 12),
              _UpcomingCard(items: upcoming, currency: currency, hide: hideAmounts)
                  .animate()
                  .fadeIn(delay: 360.ms, duration: 400.ms),
            ],
            const SizedBox(height: 28),
            AppSectionHeader(title: 'Recent activity', action: 'See all', onAction: onSeeAllTransactions),
            const SizedBox(height: 12),
            _ActivityCard(transactions: recent, currency: currency, hide: hideAmounts)
                .animate()
                .fadeIn(delay: 420.ms, duration: 400.ms),
            if (showOverviewBanner) ...[
              const SizedBox(height: 20),
              _OverviewBanner(onTap: onOverview).animate().fadeIn(delay: 480.ms, duration: 400.ms),
            ],
            const SizedBox(height: 130), // room to scroll past the floating nav bar
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final bool hideAmounts;
  final VoidCallback onProfile;
  final VoidCallback onTogglePrivacy;

  const _Header({required this.userName, required this.avatarUrl, required this.hideAmounts, required this.onProfile, required this.onTogglePrivacy});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      children: [
        GestureDetector(
          onTap: onProfile,
          // CircleAvatar clips the photo to a true circle; a clipped Container + Image.network
          // rendered a squared, off-round edge on web. The white ring is the outer padding.
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, color: surface),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppTheme.lime,
              foregroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: const Icon(Icons.person, color: AppTheme.ink),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 13, fontWeight: FontWeight.w600)),
              Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: appInk(context), fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTogglePrivacy,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: surface, boxShadow: appIsDark(context) ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Icon(hideAmounts ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: appInk(context), size: 21),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Balance card
// ---------------------------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  final String currency;
  final bool hide;
  final double total;
  final int accountsCount;
  final double monthChange;
  final String monthName;
  final VoidCallback onTap;

  const _BalanceCard({required this.currency, required this.hide, required this.total, required this.accountsCount, required this.monthChange, required this.monthName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = monthChange >= 0;
    final flat = monthChange == 0;
    final changeColor = flat ? appMuted(context) : (positive ? scheme.secondary : scheme.error);
    final accountsLabel = accountsCount == 0 ? 'No accounts yet' : (accountsCount == 1 ? '1 account' : '$accountsCount accounts');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total balance', style: GoogleFonts.manrope(color: appMuted(context), fontSize: 14.5, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: appIsDark(context) ? const Color(0xFF2A2A2D) : AppTheme.ink, borderRadius: BorderRadius.circular(20)),
                child: Text(accountsLabel, style: GoogleFonts.manrope(color: AppTheme.lime, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppMoney(
              amount: total,
              currency: currency,
              hide: hide,
              sign: total < 0 ? '-' : '',
              decimalsAlpha: 0.28,
              style: GoogleFonts.manrope(color: appInk(context), fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.5),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(flat ? Icons.remove_rounded : (positive ? Icons.north_east_rounded : Icons.south_east_rounded), color: changeColor, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  hide ? 'in $monthName' : (flat ? 'No activity in $monthName' : '${positive ? '+' : '-'}${MoneyFormat.prefix(currency)}${MoneyFormat.compact(monthChange.abs())} in $monthName'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(color: changeColor, fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onBudget;
  final VoidCallback onOverview;

  const _QuickActions({required this.onExpense, required this.onIncome, required this.onBudget, required this.onOverview});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(icon: Icons.arrow_upward_rounded, label: 'Expense', primary: true, onTap: onExpense),
        _QuickAction(icon: Icons.arrow_downward_rounded, label: 'Income', onTap: onIncome),
        _QuickAction(icon: Icons.speed_rounded, label: 'Budget', onTap: onBudget),
        _QuickAction(icon: Icons.pie_chart_outline_rounded, label: 'Overview', onTap: onOverview),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary ? AppTheme.lime : Theme.of(context).colorScheme.surface,
                boxShadow: primary || appIsDark(context) ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: Icon(icon, color: primary ? AppTheme.ink : appInk(context), size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.manrope(color: appInk(context), fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily budget + goal cards
// ---------------------------------------------------------------------------

class _DailyBudgetCard extends StatelessWidget {
  final String currency;
  final bool hide;
  final double? budget;
  final double spent;
  final VoidCallback onSet;

  const _DailyBudgetCard({required this.currency, required this.hide, required this.budget, required this.spent, required this.onSet});

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget != null && budget! > 0;
    final ratio = hasBudget ? spent / budget! : 0.0;
    final over = hasBudget && ratio >= 1.0;
    final prefix = MoneyFormat.prefix(currency);

    return GestureDetector(
      onTap: onSet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: appCardDecoration(context),
        child: hasBudget
            ? Column(
                children: [
                  Row(
                    children: [
                      const AppIconTile(icon: Icons.speed_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily budget', style: GoogleFonts.manrope(color: appInk(context), fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              hide ? 'spent today' : '$prefix${MoneyFormat.compact(spent)} of $prefix${MoneyFormat.compact(budget!)} spent today',
                              style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Text('${(ratio * 100).floor()}%', style: GoogleFonts.manrope(color: over ? Theme.of(context).colorScheme.error : appInk(context), fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppProgressBar(value: ratio, fill: over ? Theme.of(context).colorScheme.error : (appIsDark(context) ? AppTheme.lime : AppTheme.ink)),
                ],
              )
            : Row(
                children: [
                  const AppIconTile(icon: Icons.speed_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set a daily budget', style: GoogleFonts.manrope(color: appInk(context), fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text("Know what's safe to spend", style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: AppTheme.lime, borderRadius: BorderRadius.circular(20)),
                    child: Text('Set', style: GoogleFonts.manrope(color: AppTheme.ink, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final HomeGoalSummary goal;
  final String currency;
  final bool hide;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.currency, required this.hide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final prefix = MoneyFormat.prefix(currency);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: appCardDecoration(context),
        child: Column(
          children: [
            Row(
              children: [
                const AppIconTile(icon: Icons.flag_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: appInk(context), fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        hide ? 'saved' : '$prefix${MoneyFormat.compact(goal.current)} of $prefix${MoneyFormat.compact(goal.target)}',
                        style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text('${(goal.progress * 100).floor()}%', style: GoogleFonts.manrope(color: appInk(context), fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            AppProgressBar(value: goal.progress, fill: appIsDark(context) ? AppTheme.lime : AppTheme.ink),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming + activity lists
// ---------------------------------------------------------------------------

class _ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool divider;

  const _ListRow({required this.leading, required this.title, required this.subtitle, required this.trailing, required this.divider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: appInk(context), fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: appMuted(context), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
        if (divider) Divider(height: 1, indent: 76, endIndent: 16, color: appHairline(context)),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final List<HomeUpcomingItem> items;
  final String currency;
  final bool hide;

  const _UpcomingCard({required this.items, required this.currency, required this.hide});

  String _when(DateTime date) {
    final today = DateTime.now();
    final days = DateTime(date.year, date.month, date.day).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (days <= 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(context),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _ListRow(
              leading: AppIconTile(
                icon: IconUtils.getIconData(items[i].icon),
                lime: items[i].date.difference(DateTime.now()).inDays <= 2,
                size: 44,
              ),
              title: items[i].name,
              subtitle: _when(items[i].date),
              trailing: AppMoney(
                amount: items[i].amount,
                currency: currency,
                hide: hide,
                sign: '-',
                style: GoogleFonts.manrope(color: appInk(context), fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
              divider: i != items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;
  final bool hide;

  const _ActivityCard({required this.transactions, required this.currency, required this.hide});

  String _subtitle(TransactionModel t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    final diff = today.difference(day).inDays;
    final time = '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}';
    final when = diff == 0
        ? time
        : diff == 1
            ? 'Yesterday'
            : '${t.date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][t.date.month - 1]}';
    final label = t.storeName.isNotEmpty ? t.storeName : (t.customCategoryName ?? t.category.name[0].toUpperCase() + t.category.name.substring(1));
    return '$label · $when';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
        decoration: appCardDecoration(context),
        child: Text('No transactions yet.\nTap + to add one.', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: appMuted(context), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
      );
    }

    return Container(
      decoration: appCardDecoration(context),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++)
            _ListRow(
              leading: AppIconTile(icon: transactions[i].icon, lime: !transactions[i].isExpense, size: 44),
              title: transactions[i].title,
              subtitle: _subtitle(transactions[i]),
              trailing: AppMoney(
                amount: transactions[i].amount,
                currency: currency,
                hide: hide,
                sign: transactions[i].isExpense ? '-' : '+',
                style: GoogleFonts.manrope(
                  color: transactions[i].isExpense ? appInk(context) : Theme.of(context).colorScheme.secondary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              divider: i != transactions.length - 1,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview banner
// ---------------------------------------------------------------------------

class _OverviewBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _OverviewBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(color: AppTheme.lime, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Expert Money Overview', style: GoogleFonts.manrope(color: AppTheme.ink, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text('Tap to see your income breakdown', style: GoogleFonts.manrope(color: AppTheme.ink.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppTheme.ink, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.lime, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
