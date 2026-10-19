import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../goals/providers/goals_provider.dart';
import '../../../security/providers/privacy_provider.dart';
import '../../../wallet/providers/accounts_provider.dart';
import '../../../wallet/providers/credits_provider.dart';
import '../../../wallet/providers/recurring_payments_provider.dart';
import '../../providers/daily_budget_provider.dart';
import '../../providers/transactions_provider.dart';
import '../transactions_history_screen.dart';
import 'home_view.dart';
import 'money_overview_bottom_sheet.dart';
import 'transaction_bottom_sheet.dart';

/// Home tab: reads the app state and hands plain data to [HomeView].
class HomeTab extends ConsumerWidget {
  final Map<String, dynamic>? userProfile;

  /// Switches the dashboard to another tab (3 = goals, 4 = wallet).
  final void Function(int tabIndex) onOpenTab;

  const HomeTab({super.key, required this.userProfile, required this.onOpenTab});

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final recurring = ref.watch(recurringPaymentsProvider);
    final credits = ref.watch(creditsProvider);
    final dailyBudget = ref.watch(dailyBudgetProvider);
    final accounts = ref.watch(accountsProvider);
    final goals = ref.watch(goalsProvider);
    final currency = ref.watch(currencyProvider);
    final hide = ref.watch(privacyProvider);

    final now = DateTime.now();
    final todayExpenses = ref.read(transactionsProvider.notifier).getTotalExpensesForToday();

    double monthChange = 0;
    for (final t in transactions) {
      if (t.date.year == now.year && t.date.month == now.month) {
        monthChange += t.isExpense ? -t.amount : t.amount;
      }
    }

    // Recurring payments and credit instalments share one "upcoming" list.
    final cutoff = now.subtract(const Duration(days: 1));
    final upcoming = <HomeUpcomingItem>[
      ...recurring.map((p) => HomeUpcomingItem(name: p.name, amount: p.amount, date: p.nextPaymentDate, icon: p.icon)),
      ...credits.map((c) => HomeUpcomingItem(name: c.name, amount: c.monthlyContribution, date: c.nextPaymentDate, icon: c.icon)),
    ].where((p) => p.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Show the goal that is still being worked on.
    HomeGoalSummary? goal;
    if (goals.isNotEmpty) {
      final g = goals.firstWhere((g) => g.currentAmount < g.targetAmount, orElse: () => goals.first);
      goal = HomeGoalSummary(title: g.title, current: g.currentAmount, target: g.targetAmount);
    }

    final authName = FirebaseAuth.instance.currentUser?.displayName;
    final name = (userProfile?['displayName'] as String?) ?? authName ?? 'User';

    return HomeView(
      userName: name,
      avatarUrl: userProfile?['avatarUrl'] as String?,
      currency: currency,
      hideAmounts: hide,
      totalBalance: accounts.fold(0.0, (sum, a) => sum + a.balance),
      accountsCount: accounts.length,
      monthChange: monthChange,
      monthName: _months[now.month - 1],
      dailyBudget: dailyBudget,
      todayExpenses: todayExpenses,
      goal: goal,
      upcoming: upcoming.take(2).toList(),
      recent: transactions.take(4).toList(),
      showOverviewBanner: accounts.isNotEmpty,
      onProfile: () => context.push('/profile'),
      onTogglePrivacy: () => ref.read(privacyProvider.notifier).togglePrivacy(),
      onAddExpense: () => _openTransactionSheet(context, isExpense: true),
      onAddIncome: () => _openTransactionSheet(context, isExpense: false),
      onEditBudget: () => _showSetBudgetDialog(context, ref),
      onOverview: () => _openOverview(context, transactions),
      onOpenGoals: () => onOpenTab(3),
      onOpenWallet: () => onOpenTab(4),
      onSeeAllTransactions: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionsHistoryScreen())),
    );
  }

  void _openTransactionSheet(BuildContext context, {required bool isExpense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionBottomSheet(isExpenseDefault: isExpense),
    );
  }

  void _openOverview(BuildContext context, List transactions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: MoneyOverviewBottomSheet(transactions: List.from(transactions)),
        ),
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Daily Budget', style: GoogleFonts.manrope(color: scheme.onSurface, fontWeight: FontWeight.w800)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.manrope(color: scheme.onSurface, fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '${ref.read(currencyProvider)}  ',
              hintStyle: GoogleFonts.manrope(color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.manrope(color: scheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () {
                final val = double.tryParse(controller.text.replaceAll(',', '.'));
                if (val != null && val > 0) {
                  ref.read(dailyBudgetProvider.notifier).setBudget(val);
                }
                Navigator.pop(context);
              },
              child: Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }
}
