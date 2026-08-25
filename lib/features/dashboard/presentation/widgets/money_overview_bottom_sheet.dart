import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../domain/models/transaction.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MoneyOverviewBottomSheet extends ConsumerWidget {
  final List<TransactionModel> transactions;

  const MoneyOverviewBottomSheet({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();

    // 1. Calculate Income & Expenses for current month
    double totalIncome = 0;
    final Map<String, double> categoryExpenses = {};

    for (var t in transactions) {
      if (t.date.year == now.year && t.date.month == now.month) {
        if (t.isExpense) {
          final catName = t.customCategoryName ?? t.category.name.toString().split('.').last;
          final displayCat = catName[0].toUpperCase() + catName.substring(1);
          categoryExpenses[displayCat] = (categoryExpenses[displayCat] ?? 0) + t.amount;
        } else {
          totalIncome += t.amount;
        }
      }
    }

    final totalExpense = categoryExpenses.values.fold(0.0, (s, a) => s + a);
    double remaining = totalIncome - totalExpense;
    if (remaining < 0) remaining = 0;

    // Sort categories by amount
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors for the breakdown bar
    final colors = [
      Color(0xFFE74C3C), // Red
      Color(0xFFF39C12), // Orange
      Color(0xFF9B59B6), // Purple
      Color(0xFF3498DB), // Blue
      Color(0xFF1ABC9C), // Teal
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Your Expert Money Overview',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text(
            'See where your money goes this month.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),

          if (totalIncome == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No income recorded this month.',
                  style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            )
          else ...[
            // The Breakdown Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 24,
                width: double.infinity,
                child: Row(
                  children: [
                    ...List.generate(sortedCategories.length, (i) {
                      final val = sortedCategories[i].value;
                      final flex = (val / totalIncome * 1000).toInt();
                      if (flex <= 0) return const SizedBox();
                      return Expanded(
                        flex: flex,
                        child: Container(
                          color: colors[i % colors.length],
                        ).animate().scaleX(begin: 0, alignment: Alignment.centerLeft, duration: 600.ms, delay: (100 * i).ms),
                      );
                    }),
                    if (remaining > 0)
                      Expanded(
                        flex: (remaining / totalIncome * 1000).toInt(),
                        child: Container(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        ).animate().scaleX(begin: 0, alignment: Alignment.centerLeft, duration: 600.ms, delay: (100 * sortedCategories.length).ms),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Legend / List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Income (100%)', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                Text('$currency ${totalIncome.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Items List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  ...List.generate(sortedCategories.length, (i) {
                    final cat = sortedCategories[i];
                    final percentage = (cat.value / totalIncome) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.key,
                              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$currency ${cat.value.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                              Text('${percentage.toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (200 + 100 * i).ms).slideY(begin: 0.1);
                  }),
                  if (remaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Remaining (Savings)',
                              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).primaryColor),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$currency ${remaining.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Theme.of(context).primaryColor)),
                              Text('${(remaining / totalIncome * 100).toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor.withValues(alpha: 0.7))),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (200 + 100 * sortedCategories.length).ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
