import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../../core/widgets/expert_money_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/icon_utils.dart';
import '../../wallet/providers/accounts_provider.dart';
import '../domain/models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../providers/daily_budget_provider.dart';
import 'widgets/transaction_bottom_sheet.dart';
import 'widgets/money_overview_bottom_sheet.dart';
import 'transactions_history_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../wallet/providers/recurring_payments_provider.dart';
import '../../wallet/domain/models/recurring_payment.dart';
import '../../wallet/providers/credits_provider.dart';
import '../../wallet/domain/models/credit_model.dart';
import '../../../core/widgets/animated_background.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final recurringPayments = ref.watch(recurringPaymentsProvider);
    final credits = ref.watch(creditsProvider);
    final dailyBudget = ref.watch(dailyBudgetProvider);
    final todayExpenses = ref.read(transactionsProvider.notifier).getTotalExpensesForToday();
    
    // Calculate daily budget percentage
    double percentage = 0.0;
    if (dailyBudget != null && dailyBudget > 0) {
      percentage = todayExpenses / dailyBudget;
      if (percentage < 0.0) percentage = 0.0;
    }

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // Allows body to scroll underneath the bottom navigation bar
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _getCurrentTab(percentage, dailyBudget, todayExpenses, transactions, recurringPayments, credits),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _getCurrentTab(double percentage, double? dailyBudget, double todayExpenses, List<TransactionModel> transactions, List<RecurringPaymentModel> recurringPayments, List<CreditModel> credits) {
    switch (_currentIndex) {
      case 0:
        return KeyedSubtree(
          key: ValueKey('tab_0'),
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: firestoreService.userProfileStream(),
            builder: (context, snapshot) {
              final userProfile = snapshot.data;
              return _buildHomeTab(percentage, dailyBudget, todayExpenses, transactions, recurringPayments, credits, userProfile);
            }
          ),
        );
      case 1:
        return KeyedSubtree(
          key: ValueKey('tab_1'),
          child: AnalyticsScreen(),
        );
      case 3:
        return KeyedSubtree(
          key: ValueKey('tab_3'),
          child: GoalsScreen(),
        );
      case 4:
        return KeyedSubtree(
          key: ValueKey('tab_4'),
          child: WalletScreen(),
        );
      default:
        return SizedBox.shrink(key: ValueKey('empty'));
    }
  }

  Widget _buildHomeTab(double percentage, double? dailyBudget, double todayExpenses, List<TransactionModel> transactions, List<RecurringPaymentModel> recurringPayments, List<CreditModel> credits, Map<String, dynamic>? userProfile) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(userProfile),
              SizedBox(height: 24),
              _buildGreeting(userProfile),
              SizedBox(height: 32),
              _buildDonutChart(percentage, dailyBudget, todayExpenses),
              SizedBox(height: 32),
              _buildMonthlySummary(transactions),
              if (recurringPayments.isNotEmpty || credits.isNotEmpty) ...[
                SizedBox(height: 40),
                _buildUpcomingPayments(recurringPayments, credits),
              ],
              SizedBox(height: 40),
              _buildTransactionsHeader(),
              SizedBox(height: 16),
              _buildTransactionsList(transactions),
              SizedBox(height: 24),
              if (ref.watch(accountsProvider).isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildMoneyOverviewBanner(transactions),
                const SizedBox(height: 16),
              ],
              SizedBox(height: 120), // Extra space to scroll past the floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic>? userProfile) {
    final avatarUrl = userProfile?['avatarUrl'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const ExpertMoneyLogo().animate().fadeIn(delay: 100.ms),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface) : null,
          ).animate().fadeIn(delay: 100.ms),
        ),
      ],
    );
  }

  Widget _buildGreeting(Map<String, dynamic>? userProfile) {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final date = '${now.day} ${months[now.month - 1]} ${now.year}';
    final String? authName = FirebaseAuth.instance.currentUser?.displayName;
    final displayName = userProfile?['displayName'] ?? authName ?? 'User';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date.toUpperCase(),
          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: 6),
        Text(
          'Hello, $displayName',
          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildDonutChart(double percentage, double? dailyBudget, double todayExpenses) {
    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percentage),
            duration: Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: 280,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: HalfGaugePainter(
                        percentage: dailyBudget == null ? 0 : value,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        progressColor: percentage >= 1.0 ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
                        strokeWidth: 26,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dailyBudget == null ? '0%' : '${(value * 100).toInt()}%',
                            style: GoogleFonts.manrope(color: percentage >= 1.0 && dailyBudget != null ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface, fontSize: 56, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.0),
                          ),
                          SizedBox(height: 8),
                          Text(
                            dailyBudget == null 
                                ? 'No Budget' 
                                : '${ref.watch(currencyProvider)}  ${todayExpenses.toStringAsFixed(0)} / ${ref.watch(currencyProvider)}  ${dailyBudget.toStringAsFixed(0)}',
                            style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Daily Budget',
                            style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ).animate().fadeIn(delay: 400.ms).scale(begin: Offset(0.9, 0.9)),
          SizedBox(height: 24),
          if (dailyBudget == null)
            ElevatedButton.icon(
              onPressed: _showSetBudgetDialog,
              icon: Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Set Daily Budget',
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface, // Darker color
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Increased padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Slightly rounder
                minimumSize: Size.zero,
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2)
          else
            TextButton.icon(
              onPressed: _showSetBudgetDialog,
              icon: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              label: Text(
                'Edit Budget',
                style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
    );
  }

  void _showSetBudgetDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Daily Budget', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '${ref.watch(currencyProvider)}  ',
              hintStyle: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: Size(80, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final val = double.tryParse(controller.text.replaceAll(',', '.'));
                if (val != null && val > 0) {
                  ref.read(dailyBudgetProvider.notifier).setBudget(val);
                }
                Navigator.pop(context);
              },
              child: Text('Save', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today Transactions',
          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransactionsHistoryScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All >',
            style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildMonthlySummary(List<TransactionModel> transactions) {
    final now = DateTime.now();
    double income = 0;
    double expense = 0;

    for (var t in transactions) {
      if (t.date.year == now.year && t.date.month == now.month) {
        if (t.isExpense) {
          expense += t.amount;
        } else {
          income += t.amount;
        }
      }
    }

    final currency = ref.watch(currencyProvider);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF10b981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_downward, color: Color(0xFF10b981), size: 14),
                    ),
                    SizedBox(width: 8),
                    Text('Income', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Text('$currency ${income.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.error, size: 14),
                    ),
                    SizedBox(width: 8),
                    Text('Expenses', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Text('$currency ${expense.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1);
  }

  Widget _buildUpcomingPayments(List<RecurringPaymentModel> recurringPayments, List<CreditModel> credits) {
    final now = DateTime.now();
    
    // Combine both lists into a unified list of dynamic items containing 'name', 'amount', 'nextPaymentDate', 'icon'
    final List<Map<String, dynamic>> combined = [
      ...recurringPayments.map((p) => {
        'name': p.name,
        'amount': p.amount,
        'nextPaymentDate': p.nextPaymentDate,
        'icon': p.icon,
      }),
      ...credits.map((c) => {
        'name': c.name,
        'amount': c.monthlyContribution,
        'nextPaymentDate': c.nextPaymentDate,
        'icon': c.icon,
      }),
    ];

    // Filter and sort (show all upcoming payments)
    final upcoming = combined
        .where((p) => (p['nextPaymentDate'] as DateTime).isAfter(now.subtract(Duration(days: 1))))
        .toList();
    upcoming.sort((a, b) => (a['nextPaymentDate'] as DateTime).compareTo(b['nextPaymentDate'] as DateTime));
    final topUpcoming = upcoming.take(2).toList();

    if (topUpcoming.isEmpty) return SizedBox.shrink();

    // Calculate total this month (from all remaining payments THIS MONTH)
    final totalThisMonth = combined.where((p) {
      final date = p['nextPaymentDate'] as DateTime;
      return date.isAfter(now.subtract(Duration(days: 1))) &&
             date.month == now.month &&
             date.year == now.year;
    }).fold(0.0, (sum, p) => sum + (p['amount'] as double));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Payments',
                style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 4),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Manage >',
                  style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: 'Total this month · ',
              style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: '${ref.watch(currencyProvider)}  ${totalThisMonth.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Column(
            children: topUpcoming.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              final nextDate = payment['nextPaymentDate'] as DateTime;
              final daysLeft = nextDate.difference(now).inDays;
              String timeLeft;
              if (daysLeft == 0) {
                timeLeft = 'Today';
              } else if (daysLeft == 1) timeLeft = 'Tomorrow';
              else timeLeft = 'in $daysLeft days';

              final amount = payment['amount'] as double;
              final amountParts = amount.toStringAsFixed(2).split('.');
              final wholePart = amountParts[0];
              final decimalPart = amountParts[1];

              final name = payment['name'] as String;
              final icon = payment['icon'] as String;

              final bool isUrgent = daysLeft <= 2;

              return Column(
                children: [
                  if (index > 0) SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Icon(IconUtils.getIconData(icon), color: Theme.of(context).primaryColor, size: 22),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                timeLeft,
                                style: GoogleFonts.manrope(
                                  color: isUrgent ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: '${ref.watch(currencyProvider)} $wholePart',
                          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(
                              text: '.$decimalPart',
                              style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1);
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Text(
            'No transactions yet.\nTap + to add one.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: transactions.take(2).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final t = entry.value;
          
          return Column(
            children: [
              if (index > 0) Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1, indent: 20, endIndent: 20),
              _buildTransactionItem(t),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final amount = t.isExpense ? '- ${ref.watch(currencyProvider)}  ${t.amount.toStringAsFixed(2)}' : '+ ${ref.watch(currencyProvider)}  ${t.amount.toStringAsFixed(2)}';
    final time = '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}';
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, // Slightly lighter than card
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(t.icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(t.storeName, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.manrope(color: t.isExpense ? Color(0xFFE74C3C) : Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(time, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyOverviewBanner(List<TransactionModel> transactions) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: MoneyOverviewBottomSheet(transactions: transactions),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.pie_chart_outline, color: Theme.of(context).primaryColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Your Expert ',
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Money', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor)),
                      TextSpan(text: ' Overview', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text('Tap to see your income breakdown', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor, size: 20),
          ),
        ],
      ),
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95), // Slight transparency for glass effect
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(Icons.home_filled, Icons.home_outlined, 0),
                _buildNavItem(Icons.insert_chart, Icons.insert_chart_outlined, 1),
                // Center + button (Just a raw green icon, no background)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TransactionBottomSheet(),
                    );
                  },
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
                _buildNavItem(Icons.track_changes, Icons.track_changes_outlined, 3), // Target
                _buildNavItem(Icons.account_balance_wallet, Icons.account_balance_wallet_outlined, 4), // Wallet
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData filledIcon, IconData outlinedIcon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        size: 28,
      ),
    );
  }
}

// Custom Painter for the exact Donut Chart look
class HalfGaugePainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  HalfGaugePainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - strokeWidth); // Center at the bottom
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc (Dark grey)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw from pi (left) to 0 (right) -> sweep is pi
    canvas.drawArc(rect, 3.14159265359, 3.14159265359, false, bgPaint);

    // Progress arc
    if (percentage > 0.0) {
      final sweepPercentage = percentage > 1.0 ? 1.0 : percentage;
      final sweepAngle = 3.14159265359 * sweepPercentage;
      
      final isOverBudget = percentage >= 1.0;

      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isOverBudget) {
        progressPaint.color = progressColor;
      } else {
        // Create a beautiful gradient for the progress
        progressPaint.shader = SweepGradient(
          startAngle: 3.14159265359,
          endAngle: 3.14159265359 * 2,
          colors: [
            progressColor.withValues(alpha: 0.6),
            progressColor,
          ],
        ).createShader(rect);
      }

      // Glow / Shadow effect
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.4)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(rect, 3.14159265359, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, 3.14159265359, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HalfGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
