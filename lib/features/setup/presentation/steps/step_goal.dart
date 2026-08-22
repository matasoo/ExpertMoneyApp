import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/setup_provider.dart';

class StepGoal extends ConsumerWidget {
  final VoidCallback onNext;

  const StepGoal({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final selectedGoal = setupState.mainGoal;

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What are you\nsaving for first?",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.2),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          SizedBox(height: 12),
          Text(
            "Pick one — you can add more later.",
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 48),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildGoalCard(context, ref, 'Emergency fund', Icons.shield_outlined, 'Recommended', selectedGoal).animate().fadeIn(delay: 200.ms),
                _buildGoalCard(context, ref, 'Vacation', Icons.flight_takeoff, 'Trip fund', selectedGoal).animate().fadeIn(delay: 300.ms),
                _buildGoalCard(context, ref, 'New car', Icons.directions_car_outlined, 'Down payment', selectedGoal).animate().fadeIn(delay: 400.ms),
                _buildGoalCard(context, ref, 'Home Deposit', Icons.home_outlined, '', selectedGoal).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(setupProvider.notifier).setMainGoal('None');
                  onNext();
                },
                child: Text('Skip for now', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: onNext,
                child: Text('Continue'),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, String title, IconData icon, String subtitle, String currentGoal) {
    final isSelected = title == currentGoal;
    
    return InkWell(
      onTap: () => ref.read(setupProvider.notifier).setMainGoal(title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
