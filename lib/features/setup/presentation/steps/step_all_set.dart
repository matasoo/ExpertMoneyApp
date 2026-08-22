import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/setup_provider.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../dashboard/providers/daily_budget_provider.dart';
import '../../../goals/providers/goals_provider.dart';
import '../../../goals/domain/models/goal.dart';

class StepAllSet extends ConsumerWidget {
  final VoidCallback onNext;

  const StepAllSet({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final state = ref.watch(setupProvider);

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 48),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Theme.of(context).primaryColor, size: 48),
          ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
          
          SizedBox(height: 32),
          
          Text(
            "You're all set",
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 12),
          
          Text(
            "Here's your starting plan. ExpertMoney will keep it updated in real time.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 48),
          
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildSummaryRow(context, 'Monthly income', '$currency${state.monthlyIncome.toInt()}', Theme.of(context).colorScheme.onSurface),
                Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), height: 1)),
                _buildSummaryRow(context, 'Auto-save (${(state.savingsRate * 100).toInt()}%)', '$currency${state.autoSaveAmount.toInt()}', Theme.of(context).primaryColor),
                Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), height: 1)),
                _buildSummaryRow(context, 'Fixed costs', '$currency${state.totalFixedCosts.toInt()}', Theme.of(context).colorScheme.onSurface),
                Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), height: 1)),
                _buildSummaryRow(context, 'Free to budget', '$currency${state.freeToBudget.toInt()}', Theme.of(context).primaryColor, isBold: true),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
          
          Spacer(),
          
          ElevatedButton(
            onPressed: () async {
              try {
                // Auto-set daily budget
                if (state.freeToBudget > 0) {
                  await ref.read(dailyBudgetProvider.notifier).setBudget(state.freeToBudget / 30);
                }
                
                // Auto-create savings goal
                if (state.mainGoal != 'None' && state.autoSaveAmount > 0) {
                  await ref.read(goalsProvider.notifier).addGoal(GoalModel(
                    id: '',
                    title: state.mainGoal,
                    targetAmount: state.autoSaveAmount * 12,
                    currentAmount: 0,
                    monthlyContribution: state.autoSaveAmount,
                    colorValue: 0xFF3b82f6,
                  ));
                }

                onNext();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error in saving goals: $e')));
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Go to dashboard'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
