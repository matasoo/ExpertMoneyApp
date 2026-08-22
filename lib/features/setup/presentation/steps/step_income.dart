import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../providers/setup_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StepIncome extends ConsumerWidget {
  final VoidCallback onNext;

  const StepIncome({super.key, required this.onNext});

  Future<void> _showCustomAmountDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Custom Income'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Enter amount'),
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
                  ref.read(setupProvider.notifier).setIncome(val);
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
    final income = setupState.monthlyIncome;
    final isVariable = setupState.isVariableIncome;

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your monthly\nnet income?",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.2),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          SizedBox(height: 12),
          Text(
            "After taxes. You can change this anytime.",
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          Spacer(),
          
          Center(
            child: isVariable
                ? Text('Variable', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 48, fontWeight: FontWeight.bold))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.watch(currencyProvider), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(
                        income.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 64, fontWeight: FontWeight.bold, height: 1.0),
                      ),
                    ],
                  ),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          
          SizedBox(height: 48),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isVariable ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3) : Theme.of(context).primaryColor,
              inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              thumbColor: isVariable ? Colors.grey : Theme.of(context).primaryColor, // Green slider thumb
              overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 0),
            ),
            child: Slider(
              value: income > 8000 ? 8000 : income,
              min: 0,
              max: 8000,
              divisions: 80,
              onChanged: isVariable ? null : (val) {
                ref.read(setupProvider.notifier).setIncome(val);
              },
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${currency}0', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
              Text('${currency}8,000+', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
          
          SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetButton(context, ref, 2500, income, isVariable),
              SizedBox(width: 8),
              _buildPresetButton(context, ref, 3200, income, isVariable),
              SizedBox(width: 8),
              _buildPresetButton(context, ref, 4000, income, isVariable),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _showCustomAmountDialog(context, ref),
                child: Text('Custom amount'),
              ),
              Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
              TextButton(
                onPressed: () {
                  ref.read(setupProvider.notifier).setVariableIncome(!isVariable);
                },
                child: Text(isVariable ? 'Set fixed income' : "I don't have a fixed income"),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
          
          Spacer(),
          
          ElevatedButton(
            onPressed: (income > 0 || isVariable) ? onNext : null,
            child: Text('Continue'),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, WidgetRef ref, double amount, double currentIncome, bool isVariable) {
    final isSelected = amount == currentIncome && !isVariable;
    return InkWell(
      onTap: () => ref.read(setupProvider.notifier).setIncome(amount),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${ref.watch(currencyProvider)}${amount.toInt()}',
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
