import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/expert_money_logo.dart';
import '../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/goals_provider.dart';
import '../domain/models/goal.dart';
import 'widgets/add_goal_bottom_sheet.dart';
import '../domain/models/budget.dart';
import '../../../../core/utils/icon_utils.dart';
import '../providers/budgets_provider.dart';
import 'widgets/add_budget_bottom_sheet.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../core/widgets/tutorial_slider.dart';
import '../../wallet/providers/accounts_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasSeen = ref.read(hasSeenGoalsTutorialProvider);
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
            title: 'Smart Budgets',
            description: 'Set spending limits by category and track how much you have left.',
            icon: Icons.track_changes,
          ),
          TutorialSlide(
            title: 'Savings Goals',
            description: 'Save for your dreams. Create goals and add contributions.',
            icon: Icons.savings,
            color: Colors.green,
          ),
          TutorialSlide(
            title: 'Automated Tracking',
            description: 'Set goals on autopilot with automatic monthly deductions.',
            icon: Icons.autorenew,
            color: Colors.blue,
          ),
        ],
        onDismiss: () {
          ref.read(hasSeenGoalsTutorialProvider.notifier).set(true);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showAddFundsDialog(GoalModel goal) async {
    final currency = ref.read(currencyProvider);
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Add Funds', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter amount to add to ${goal.title}:', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14)),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
              decoration: InputDecoration(
                prefixText: ref.watch(currencyProvider),
                prefixStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                if (goal.linkedAccountId != null) {
                  try {
                    final accounts = ref.read(accountsProvider);
                    final account = accounts.firstWhere((a) => a.id == goal.linkedAccountId);
                    final updatedAccount = account.copyWith(balance: account.balance + amount);
                    ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
                  } catch (e) {
                    print('Linked account not found');
                  }
                } else {
                  final updatedGoal = goal.copyWith(currentAmount: goal.currentAmount + amount);
                  ref.read(goalsProvider.notifier).updateGoal(updatedGoal);
                }
              }
              Navigator.pop(context);
            },
            child: Text('Add', style: GoogleFonts.inter(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(GoalModel goal, String currency) {
    double currentAmount = goal.currentAmount;
    String linkedAccountName = '';
    
    if (goal.linkedAccountId != null) {
      final accounts = ref.watch(accountsProvider);
      try {
        final account = accounts.firstWhere((a) => a.id == goal.linkedAccountId);
        currentAmount = account.balance;
        linkedAccountName = account.name;
      } catch (e) {
        // Account deleted or not found
      }
    }

    double percentage = goal.targetAmount > 0 ? currentAmount / goal.targetAmount : 0;
    if (percentage > 1.0) percentage = 1.0;
    final color = goal.colorValue != null ? Color(goal.colorValue!) : Theme.of(context).primaryColor;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), // Minimalist sharp corners
            title: Text('Delete Goal', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 18)),
            content: Text('Delete this savings goal?', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(goalsProvider.notifier).removeGoal(goal.id);
      },
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddGoalBottomSheet(goalToEdit: goal),
          );
        },
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_outlined, color: color, size: 20),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.title, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500)),
                          if (linkedAccountName.isNotEmpty)
                            Text('Linked: $linkedAccountName', style: GoogleFonts.inter(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${(percentage * 100).toInt()}%',
                        style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showAddFundsDialog(goal),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, size: 14, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${ref.watch(currencyProvider)}${currentAmount.toStringAsFixed(0)} / ${ref.watch(currencyProvider)}${goal.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w400)),
                  Text('+${ref.watch(currencyProvider)}${goal.monthlyContribution.toStringAsFixed(0)}/mo', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              ),
              SizedBox(height: 12),
              // Minimal thin line
              Container(
                height: 2,
                width: double.infinity,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetItem(BudgetModel budget, String currency) {
    double percentage = budget.limitAmount > 0 ? budget.currentSpent / budget.limitAmount : 0;
    if (percentage > 1.0) percentage = 1.0;
    final isOverBudget = budget.currentSpent > budget.limitAmount;
    final barColor = isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: Text('Delete Budget', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 18)),
            content: Text('Delete this budget?', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(budgetsProvider.notifier).removeBudget(budget.id);
      },
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddBudgetBottomSheet(budgetToEdit: budget),
          );
        },
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(IconUtils.getIconData(budget.icon), size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                      SizedBox(width: 12),
                      Text(budget.category, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(
                    '${ref.watch(currencyProvider)}${budget.currentSpent.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(color: isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${budget.resetPeriod} limit', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w400)),
                  Text('of ${ref.watch(currencyProvider)}${budget.limitAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              ),
              SizedBox(height: 12),
              // Minimal thin line
              Container(
                height: 2,
                width: double.infinity,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(color: barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final goals = ref.watch(goalsProvider);
    final budgets = ref.watch(budgetsProvider);
    final accounts = ref.watch(accountsProvider);
    final totalSaved = goals.fold(0.0, (sum, goal) {
      if (goal.linkedAccountId != null) {
        try {
          final account = accounts.firstWhere((a) => a.id == goal.linkedAccountId);
          return sum + account.balance;
        } catch (_) {
          return sum + goal.currentAmount;
        }
      }
      return sum + goal.currentAmount;
    });

    return SafeArea(
      bottom: false,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ExpertMoneyLogo(),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // --- MINIMALIST HERO (Typography only) ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saved',
                      style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.0, textBaseline: TextBaseline.alphabetic),
                    ).animate().fadeIn(duration: 600.ms),
                    SizedBox(height: 8),
                    Text(
                      '${ref.watch(currencyProvider)}${totalSaved.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: -2.0),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
                  ],
                ),
              ),
              
              SizedBox(height: 56),
              
              // --- SAVINGS GOALS ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Goals',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface, size: 22),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddGoalBottomSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Divider line below header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), height: 1),
              ),
              
              if (goals.isEmpty)
                Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text('No goals yet', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w400)),
                  ),
                )
              else
                ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  separatorBuilder: (context, index) => Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  itemBuilder: (context, index) {
                    return _buildGoalItem(goals[index], currency)
                        .animate()
                        .fade(duration: 400.ms, delay: (50 * index).ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                  },
                ),
                
              SizedBox(height: 56),

              // --- BUDGETS ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budgets',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface, size: 22),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddBudgetBottomSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Divider line below header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), height: 1),
              ),
              
              if (budgets.isEmpty)
                Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text('No budgets yet', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w400)),
                  ),
                )
              else
                ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: budgets.length,
                  separatorBuilder: (context, index) => Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  itemBuilder: (context, index) {
                    return _buildBudgetItem(budgets[index], currency)
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
    );
  }
}
