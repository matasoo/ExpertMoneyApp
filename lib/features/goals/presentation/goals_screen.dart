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

  Widget _buildHeroCard(double totalSaved, String currency) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_rounded, color: Colors.white.withValues(alpha: 0.8), size: 24),
              SizedBox(width: 8),
              Text(
                'Total Saved',
                style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '$currency${totalSaved.toStringAsFixed(0)}',
            style: GoogleFonts.manrope(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildGoalCard(GoalModel goal, String currency) {
    double percentage = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0;
    if (percentage > 1.0) percentage = 1.0;
    final color = goal.colorValue != null ? Color(goal.colorValue!) : Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddGoalBottomSheet(goalToEdit: goal),
        );
      },
      child: Container(
        width: 240,
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag_rounded, color: color, size: 24),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: GoogleFonts.manrope(color: color, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text('$currency${goal.currentAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget, String currency) {
    double percentage = budget.limitAmount > 0 ? budget.currentSpent / budget.limitAmount : 0;
    if (percentage > 1.0) percentage = 1.0;
    final isOverBudget = budget.currentSpent > budget.limitAmount;
    final barColor = isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
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
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
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
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(IconUtils.getIconData(budget.icon), size: 24, color: Theme.of(context).primaryColor),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(budget.category, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('${budget.resetPeriod} limit', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$currency${budget.currentSpent.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('of $currency${budget.limitAmount.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 10,
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
    final totalSaved = goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);

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
              
              // --- HERO CARD ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildHeroCard(totalSaved, currency),
              ),
              SizedBox(height: 40),
              
              // --- SAVINGS GOALS (Horizontal Gallery) ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Goals',
                      style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 28),
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
              SizedBox(height: 16),
              
              if (goals.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.savings_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), size: 48),
                          SizedBox(height: 16),
                          Text('No goals yet', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(goals[index], currency)
                          .animate()
                          .fade(duration: 400.ms, delay: (50 * index).ms)
                          .slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                    },
                  ),
                ),
                
              SizedBox(height: 40),

              // --- BUDGETS LIST ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budgets',
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 28),
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
                    SizedBox(height: 16),
                    
                    if (budgets.isEmpty)
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 1),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.pie_chart_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), size: 48),
                              SizedBox(height: 16),
                              Text('No budgets yet', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: budgets.length,
                        itemBuilder: (context, index) {
                          return _buildBudgetCard(budgets[index], currency)
                              .animate()
                              .fade(duration: 400.ms, delay: (50 * index).ms)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
                        },
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 120), // Padding for floating nav bar
            ],
          ),
        ),
      ),
    );
  }
}
