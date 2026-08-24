import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/expert_money_logo.dart';
import '../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/accounts_provider.dart';
import '../domain/models/account.dart';
import '../providers/recurring_payments_provider.dart';
import '../domain/models/recurring_payment.dart';
import '../providers/credits_provider.dart';
import '../domain/models/credit_model.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../dashboard/providers/transactions_provider.dart';
import 'widgets/add_account_bottom_sheet.dart';
import 'widgets/add_recurring_payment_bottom_sheet.dart';
import 'widgets/add_credit_bottom_sheet.dart';
import 'widgets/dynamic_balance_card.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../core/widgets/tutorial_slider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isManaging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasSeen = ref.read(hasSeenWalletTutorialProvider);
      if (!hasSeen) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TutorialSlider(
        slides: [
          TutorialSlide(
            title: 'Bank Accounts',
            description: 'Manage all your accounts in one place. Add cash, cards, and savings.',
            icon: Icons.account_balance,
          ),
          TutorialSlide(
            title: 'Subscriptions & Bills',
            description: 'Never miss a payment again. Keep track of all your recurring expenses.',
            icon: Icons.live_tv,
            color: Colors.orange,
          ),
          TutorialSlide(
            title: 'Active Credits & Loans',
            description: 'Monitor your active credits, track payments, and see remaining balances.',
            icon: Icons.credit_card,
            color: Colors.purple,
          ),
        ],
        onDismiss: () {
          ref.read(hasSeenWalletTutorialProvider.notifier).set(true);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final accounts = ref.watch(accountsProvider);
    final recurringPayments = ref.watch(recurringPaymentsProvider);
    final credits = ref.watch(creditsProvider);
    final transactions = ref.watch(transactionsProvider);
    final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);
    final totalDebt = credits.fold(0.0, (sum, credit) => sum + (credit.totalAmount - credit.paidAmount));
    final netWorth = totalBalance - totalDebt;

    final now = DateTime.now();
    final monthlyChange = transactions
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => t.isExpense ? sum - t.amount : sum + t.amount);

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = monthNames[now.month - 1];

    return SafeArea(
      bottom: false,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ExpertMoneyLogo(),
                    SizedBox(),
                  ],
                ),
                SizedBox(height: 32),
                
                Text(
                  'Wallet',
                  style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -1.0),
                ),
                SizedBox(height: 16),
                
                // --- TOTAL BALANCE CARD ---
                DynamicBalanceCard(
                  accountsCount: accounts.length,
                  totalBalance: totalBalance,
                  monthlyChange: monthlyChange,
                  currentMonthName: currentMonthName,
                ),
                SizedBox(height: 32),

                // --- ACCOUNTS LIST HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accounts',
                          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Total: $currency${totalBalance.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                        Text(
                          'Net Worth: $currency${netWorth.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isManaging = !_isManaging;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          _isManaging ? 'Done' : 'Manage >',
                          style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // --- ACCOUNTS LIST ---
                if (accounts.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No accounts yet. Add your first bank account or wallet.', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16)),
                    ),
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildAccountCard(context, ref, accounts[index])
                          .animate(key: ValueKey('${accounts[index].id}_$_isManaging'))
                          .fade(duration: 400.ms, delay: (50 * index).ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                    },
                  ),

                SizedBox(height: 24),

                // --- ADD NEW ACCOUNT BUTTON ---
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddAccountBottomSheet(),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2), // Subtle border
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Theme.of(context).primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text('Add bank account', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 48),

                // --- SUBSCRIPTIONS & BILLS HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subscriptions & Bills',
                      style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isManaging = !_isManaging;
                            });
                          },
                          child: Text(
                            _isManaging ? 'Done' : 'Manage >',
                            style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddRecurringPaymentBottomSheet(),
                            );
                          },
                          child: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // --- SUBSCRIPTIONS LIST ---
                if (recurringPayments.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No subscriptions added yet. Keep track of your fixed costs here.', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16)),
                    ),
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: recurringPayments.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildRecurringPaymentCard(context, ref, recurringPayments[index])
                          .animate()
                          .fade(duration: 400.ms, delay: (50 * index).ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                    },
                  ),

                SizedBox(height: 48),

                // --- ACTIVE CREDITS HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Credits / Loans',
                      style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isManaging = !_isManaging;
                            });
                          },
                          child: Text(
                            _isManaging ? 'Done' : 'Manage >',
                            style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddCreditBottomSheet(),
                            );
                          },
                          child: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // --- CREDITS LIST ---
                if (credits.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No active credits. Great job staying debt-free!', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16)),
                    ),
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: credits.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCreditCard(context, ref, credits[index])
                          .animate()
                          .fade(duration: 400.ms, delay: (50 * index).ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                    },
                  ),

                SizedBox(height: 120), // Padding for floating nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, WidgetRef ref, AccountModel account) {
    final color = account.colorValue != null ? Color(account.colorValue!) : Theme.of(context).primaryColor;
    final isNegative = account.balance < 0;
    
    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Account?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
            content: Text('Are you sure you want to delete ${account.name}?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(accountsProvider.notifier).removeAccount(account.id);
      },
      child: GestureDetector(
        onTap: () {
          if (_isManaging) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddAccountBottomSheet(accountToEdit: account),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(IconUtils.getIconData(account.icon ?? ''), color: Theme.of(context).primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            
            // Name and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manual · · · ·', // Placeholder for subtitle as requested
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            // Balance and Status
            if (_isManaging)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddAccountBottomSheet(accountToEdit: account),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Delete Account?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
                          content: Text('Are you sure you want to delete ${account.name}?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                            TextButton(
                              onPressed: () {
                                ref.read(accountsProvider.notifier).removeAccount(account.id);
                                Navigator.pop(context);
                              },
                              child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isNegative ? '- ' : ''}${ref.watch(currencyProvider)} ${account.balance.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                      color: isNegative ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Active', // Placeholder for status
                    style: GoogleFonts.manrope(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildRecurringPaymentCard(BuildContext context, WidgetRef ref, RecurringPaymentModel payment) {
    return Dismissible(
      key: Key(payment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Subscription?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
            content: Text('Are you sure you want to delete ${payment.name}?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(recurringPaymentsProvider.notifier).removePayment(payment.id);
      },
      child: GestureDetector(
        onTap: () {
          if (_isManaging) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddRecurringPaymentBottomSheet(paymentToEdit: payment),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(IconUtils.getIconData(payment.icon), color: Theme.of(context).primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            
            // Name and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.name,
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Next: ${DateFormat('MMM d').format(payment.nextPaymentDate)}',
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            // Balance and Status
            if (_isManaging)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddRecurringPaymentBottomSheet(paymentToEdit: payment),
                      );
                    },
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ref.watch(currencyProvider)} ${payment.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    payment.interval.name[0].toUpperCase() + payment.interval.name.substring(1),
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _showMakePaymentDialog(CreditModel credit) async {
    final currency = ref.read(currencyProvider);
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Make Payment', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter payment amount for ${credit.name}:', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixText: ref.watch(currencyProvider),
                prefixStyle: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                final newPaid = (credit.paidAmount + amount).clamp(0.0, credit.totalAmount);
                final newCredit = CreditModel(
                  id: credit.id,
                  name: credit.name,
                  totalAmount: credit.totalAmount,
                  paidAmount: newPaid,
                  monthlyContribution: credit.monthlyContribution,
                  icon: credit.icon,
                  nextPaymentDate: credit.nextPaymentDate,
                  accountId: credit.accountId,
                );
                ref.read(creditsProvider.notifier).updateCredit(newCredit);
              }
              Navigator.pop(context);
            },
            child: Text('Pay', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context, WidgetRef ref, CreditModel credit) {
    return Dismissible(
      key: Key(credit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Credit?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
            content: Text('Are you sure you want to delete ${credit.name}?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(creditsProvider.notifier).removeCredit(credit.id);
      },
      child: GestureDetector(
        onTap: () {
          if (_isManaging) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddCreditBottomSheet(creditToEdit: credit),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(IconUtils.getIconData(credit.icon), color: Theme.of(context).primaryColor, size: 24),
                  ),
                  SizedBox(width: 16),
                  
                  // Name and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credit.name,
                          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Next: ${DateFormat('MMM d').format(credit.nextPaymentDate)}',
                          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  
                  // Monthly rate and editing
                  if (_isManaging)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddCreditBottomSheet(creditToEdit: credit),
                            );
                          },
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ref.watch(currencyProvider)} ${credit.monthlyContribution.toStringAsFixed(2)}',
                          style: GoogleFonts.manrope(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '/ mo',
                          style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
              if (!_isManaging && credit.totalAmount > 0) ...[
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${ref.watch(currencyProvider)}${credit.paidAmount.toStringAsFixed(0)} paid',
                          style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showMakePaymentDialog(credit),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add, size: 12, color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${ref.watch(currencyProvider)}${credit.totalAmount.toStringAsFixed(0)} total',
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: credit.progress,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    color: Theme.of(context).primaryColor,
                    minHeight: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
