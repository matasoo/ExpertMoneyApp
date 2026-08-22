import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/setup_provider.dart';

class StepSavings extends ConsumerWidget {
  final VoidCallback onNext;

  const StepSavings({super.key, required this.onNext});

  Future<void> _showCustomRateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Custom Savings Rate'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Enter percentage (e.g. 15)', suffixText: '%'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
            TextButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) {
                  ref.read(setupProvider.notifier).setSavingsRate(val / 100);
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final setupState = ref.watch(setupProvider);
    final rate = setupState.savingsRate;
    final amountToSave = setupState.monthlyIncome * rate;

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How much do you\nwant to save?",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.2),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          SizedBox(height: 12),
          Text(
            "A share of your income, set aside first.",
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          Spacer(),
          
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(rate), // Re-animate if rate changes
                tween: Tween<double>(begin: 0, end: rate),
                duration: Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 16,
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        color: Theme.of(context).primaryColor,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(value * 100).toInt()}%',
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$currency${(setupState.monthlyIncome * value).toInt()} / mo',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          
          SizedBox(height: 64),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetButton(context, ref, 0.10, rate),
              SizedBox(width: 16),
              _buildPresetButton(context, ref, 0.20, rate),
              SizedBox(width: 16),
              _buildPresetButton(context, ref, 0.30, rate),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 16),
          
          Center(
            child: TextButton(
              onPressed: () => _showCustomRateDialog(context, ref),
              child: Text('Custom %'),
            ),
          ).animate().fadeIn(delay: 450.ms),
          
          Spacer(),
          
          ElevatedButton(
            onPressed: onNext,
            child: Text('Continue'),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, WidgetRef ref, double targetRate, double currentRate) {
    final isSelected = targetRate == currentRate;
    return InkWell(
      onTap: () => ref.read(setupProvider.notifier).setSavingsRate(targetRate),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${(targetRate * 100).toInt()}%',
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
