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

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final goals = ref.watch(goalsProvider);
    final budgets = ref.watch(budgetsProvider);
    final totalSaved = goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);

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
                  'Savings Goals',
                  style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -1.0),
                ),
                SizedBox(height: 4),
                Text(
                  '${ref.watch(currencyProvider)}${totalSaved.toStringAsFixed(0)} saved across ${goals.length} goals',
                  style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 32),

                // --- GOALS LIST ---
                if (goals.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No goals yet. Set one up!', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16)),
                    ),
                  )
                else
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(context, ref, goals[index])
                          .animate()
                          .fade(duration: 400.ms, delay: (50 * index).ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                    },
                  ),

                // --- ADD NEW GOAL BUTTON ---
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddGoalBottomSheet(),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2), // Solid thin border as fallback for dashed
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Theme.of(context).primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text('New savings goal', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 48),

                // --- BUDGETS HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budgets',
                      style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -1.0),
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddBudgetBottomSheet(),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('+ Add', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // --- BUDGETS LIST ---
                if (budgets.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No budgets yet.', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16)),
                    ),
                  )
                else
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      return _buildBudgetCard(context, ref, budgets[index])
                          .animate()
                          .fade(duration: 400.ms, delay: (50 * index).ms)
                          .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
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

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, GoalModel goal) {
    double percentage = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0;
    if (percentage > 1.0) percentage = 1.0;
    final color = goal.colorValue != null ? Color(goal.colorValue!) : Theme.of(context).primaryColor;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Color(0xFF3b82f6).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 24),
        child: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddGoalBottomSheet(goalToEdit: goal),
          );
          return false; // Prevent dismissing
        }
        
        // Delete action
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Goal?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
            content: Text('Are you sure you want to delete this savings goal?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(goalsProvider.notifier).removeGoal(goal.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Circular Progress Indicator
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(percentage * 100).toInt()}%',
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
            // Goal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('${ref.watch(currencyProvider)}${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('+${ref.watch(currencyProvider)}${goal.monthlyContribution.toStringAsFixed(0)} / month', style: GoogleFonts.manrope(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref, BudgetModel budget) {
    double percentage = budget.limitAmount > 0 ? budget.currentSpent / budget.limitAmount : 0;
    if (percentage > 1.0) percentage = 1.0;
    final isOverBudget = budget.currentSpent > budget.limitAmount;
    final barColor = isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Color(0xFF3b82f6).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 24),
        child: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddBudgetBottomSheet(budgetToEdit: budget),
          );
          return false; // Prevent dismissing
        }
        
        // Delete action
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Budget?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
            content: Text('Are you sure you want to delete this budget?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(budgetsProvider.notifier).removeBudget(budget.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(IconUtils.getIconData(budget.icon), size: 24, color: Theme.of(context).primaryColor),
                ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.category, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${budget.resetPeriod} limit', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${ref.watch(currencyProvider)}${budget.currentSpent.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('of \$${budget.limitAmount.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Progress Bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
