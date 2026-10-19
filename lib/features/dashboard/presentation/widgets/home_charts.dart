import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/transaction.dart';
import 'dart:math' as math;

class HomeWeeklyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const HomeWeeklyBarChart({super.key, required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Calculate spending per day of the current week (Monday - Sunday)
    final now = DateTime.now();
    // Monday is 1, Sunday is 7 in Dart's DateTime.weekday
    final int currentWeekday = now.weekday;
    final DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));

    List<double> dailySpending = List.filled(7, 0.0);
    double maxSpending = 0;

    for (var t in transactions) {
      if (t.isExpense && t.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && t.date.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        // Calculate difference in days from start of week
        final diff = t.date.difference(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)).inDays;
        if (diff >= 0 && diff < 7) {
          dailySpending[diff] += t.amount;
          if (dailySpending[diff] > maxSpending) {
            maxSpending = dailySpending[diff];
          }
        }
      }
    }

    if (maxSpending == 0) maxSpending = 100; // default to avoid zero division

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.manrope(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpending * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '$currency ${CurrencyFormatter.format(rod.toY)}',
                        GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('M', style: style); break;
                          case 1: text = const Text('T', style: style); break;
                          case 2: text = const Text('W', style: style); break;
                          case 3: text = const Text('T', style: style); break;
                          case 4: text = const Text('F', style: style); break;
                          case 5: text = const Text('S', style: style); break;
                          case 6: text = const Text('S', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return Padding(padding: const EdgeInsets.only(top: 8), child: text);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dailySpending[index],
                        color: index == currentWeekday - 1 ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        width: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeCategoriesChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const HomeCategoriesChart({super.key, required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    Map<String, double> categoryTotals = {};
    double totalMonthExpenses = 0;

    for (var t in transactions) {
      if (t.isExpense && t.date.month == now.month && t.date.year == now.year) {
        categoryTotals[t.category.name] = (categoryTotals[t.category.name] ?? 0) + t.amount;
        totalMonthExpenses += t.amount;
      }
    }

    // Sort and get top 3
    var sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(3).toList();
    final List<Color> colors = [Colors.purpleAccent, Colors.orangeAccent, Colors.blueAccent];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.manrope(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          if (topCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No expenses this month', style: GoogleFonts.manrope(color: Colors.grey)),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          startDegreeOffset: 180,
                          sections: List.generate(topCategories.length, (i) {
                            return PieChartSectionData(
                              color: colors[i],
                              value: topCategories[i].value,
                              title: '',
                              radius: 12,
                            );
                          }),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                          Text(
                            CurrencyFormatter.format(totalMonthExpenses),
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(topCategories.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[i],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topCategories[i].key[0].toUpperCase() + topCategories[i].key.substring(1),
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$currency ${CurrencyFormatter.format(topCategories[i].value)}',
                                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
