import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/setup_provider.dart';

class StepCosts extends ConsumerWidget {
  final VoidCallback onNext;

  const StepCosts({super.key, required this.onNext});

  Future<void> _showCostDialog(BuildContext context, WidgetRef ref, {FixedCost? existingCost}) async {
    final nameController = TextEditingController(text: existingCost?.name ?? '');
    final amountController = TextEditingController(text: existingCost != null && existingCost.amount > 0 ? existingCost.amount.toInt().toString() : '');
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(existingCost == null ? 'Add Fixed Cost' : 'Edit Cost'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: 'Cost name (e.g. Rent)'),
                autofocus: existingCost == null,
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Amount', prefixText: ref.watch(currencyProvider)),
                autofocus: existingCost != null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final val = double.tryParse(amountController.text);
                if (name.isNotEmpty && val != null) {
                  if (existingCost == null) {
                    ref.read(setupProvider.notifier).addFixedCost(FixedCost(name, val));
                  } else {
                    ref.read(setupProvider.notifier).editFixedCost(existingCost, val);
                  }
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
    final costs = setupState.fixedCosts;

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your typical fixed\nmonthly costs?",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.2),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          SizedBox(height: 12),
          Text(
            "Rent, bills, subscriptions — we'll budget the rest.",
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.swipe_left, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 16),
              SizedBox(width: 8),
              Text('Swipe left to delete', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ).animate().fadeIn(delay: 200.ms),
          
          SizedBox(height: 16),
          
          Expanded(
            child: ListView.separated(
              itemCount: costs.length + 1, // +1 for "Add another" button
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == costs.length) {
                  // Add button
                  return InkWell(
                    onTap: () => _showCostDialog(context, ref),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('+ Add another', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms);
                }

                final cost = costs[index];
                return Dismissible(
                  key: ValueKey(cost.name + cost.amount.toString() + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(setupProvider.notifier).removeFixedCost(cost);
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 24),
                    child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  child: InkWell(
                    onTap: () => _showCostDialog(context, ref, existingCost: cost),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cost.amount == 0 ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5) : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cost.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          if (cost.amount == 0)
                            Text('Tap to set ${ref.watch(currencyProvider)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
                          else
                            Text('${ref.watch(currencyProvider)} ${cost.amount.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 100))).slideX(begin: 0.1, end: 0),
                );
              },
            ),
          ),
          
          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total fixed', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                Text(
                  '${ref.watch(currencyProvider)} ${setupState.totalFixedCosts.toInt()}',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          
          SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: costs.any((c) => c.amount == 0) ? null : onNext,
            child: Text('Continue'),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}
