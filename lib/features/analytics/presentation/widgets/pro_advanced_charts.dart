import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../dashboard/domain/models/transaction.dart';

class ProCategoriesChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const ProCategoriesChart({super.key, required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    // 1. Filter to expenses only
    final expenses = transactions.where((t) => t.isExpense).toList();
    
    // 2. Group by category
    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      final catName = t.customCategoryName ?? t.category.name.toString().split('.').last;
      final displayCat = catName[0].toUpperCase() + catName.substring(1);
      categoryTotals[displayCat] = (categoryTotals[displayCat] ?? 0) + t.amount;
    }

    final totalExpense = categoryTotals.values.fold(0.0, (s, a) => s + a);

    // 3. Sort descending
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 4. Take top 5, rest to "Other"
    final List<MapEntry<String, double>> topCategories = [];
    double otherTotal = 0;
    for (int i = 0; i < sortedCategories.length; i++) {
      if (i < 5) {
        topCategories.add(sortedCategories[i]);
      } else {
        otherTotal += sortedCategories[i].value;
      }
    }
    if (otherTotal > 0) {
      topCategories.add(MapEntry('Other', otherTotal));
    }

    final colors = [
      const Color(0xFF4ADE80),
      const Color(0xFF6EE7B7),
      const Color(0xFFA7F3D0),
      const Color(0xFF4B5563),
      const Color(0xFF374151),
      const Color(0xFF1F2937),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.transparent, // Slightly darker surface
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORIES',
            style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (totalExpense == 0)
            Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('No expenses this period', style: GoogleFonts.manrope(color: Colors.grey[500])),
            ))
          else
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 60,
                            startDegreeOffset: -90,
                            sections: List.generate(topCategories.length, (i) {
                              final value = topCategories[i].value;
                              final percentage = (value / totalExpense) * 100;
                              return PieChartSectionData(
                                color: colors[i % colors.length],
                                value: value,
                                title: '',
                                radius: 14, // Thicker ring
                              );
                            }),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$currency${totalExpense.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            Text('this period', style: GoogleFonts.manrope(color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: List.generate(topCategories.length, (i) {
                      final item = topCategories[i];
                      final percentage = (item.value / totalExpense * 100).toStringAsFixed(0);
                      return _buildLegendItem(colors[i % colors.length], item.key, '$percentage%');
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String name, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Text(percentage, style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class ProIncomeExpensesChart extends StatelessWidget {
  final List<TransactionModel> allTransactions;
  final String currency;

  const ProIncomeExpensesChart({super.key, required this.allTransactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Generate last 6 months
    final now = DateTime.now();
    final List<DateTime> months = [];
    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    double maxAmount = 100;
    final List<Map<String, double>> monthlyData = [];

    for (var m in months) {
      double income = 0;
      double expense = 0;
      final txs = allTransactions.where((t) => t.date.year == m.year && t.date.month == m.month);
      for (var t in txs) {
        if (t.isExpense) expense += t.amount;
        else income += t.amount;
      }
      monthlyData.add({'income': income, 'expense': expense});
      if (income > maxAmount) maxAmount = income;
      if (expense > maxAmount) maxAmount = expense;
    }

    // Add some padding to maxY
    maxAmount = maxAmount * 1.2;

    // Current month stats (last in array)
    final currentIncome = monthlyData.last['income'] ?? 0;
    final currentExpense = monthlyData.last['expense'] ?? 0;
    final saved = currentIncome - currentExpense;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INCOME VS EXPENSES',
                style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Income', style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 11)),
                  const SizedBox(width: 12),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4B5563), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Expenses', style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= months.length) return const SizedBox();
                        final m = months[value.toInt()];
                        final title = DateFormat('MMM').format(m);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months.length, (i) {
                  return _buildGroup(i, monthlyData[i]['income']!, monthlyData[i]['expense']!);
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF27272A)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Income', '$currency${currentIncome.toStringAsFixed(0)}', Colors.white),
              _buildSummaryItem('Expenses', '$currency${currentExpense.toStringAsFixed(0)}', Colors.white),
              _buildSummaryItem('Saved', '${saved >= 0 ? '+' : '-'}$currency${saved.abs().toStringAsFixed(0)}', saved >= 0 ? const Color(0xFF4ADE80) : Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildGroup(int x, double income, double expense) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(toY: income, color: const Color(0xFF4ADE80), width: 12, borderRadius: BorderRadius.circular(2)),
        BarChartRodData(toY: expense, color: const Color(0xFF4B5563), width: 12, borderRadius: BorderRadius.circular(2)),
      ],
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 11)),
        const SizedBox(height: 4),
        Text(amount, style: GoogleFonts.manrope(color: amountColor, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class ProTopMerchantsChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const ProTopMerchantsChart({super.key, required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    final Map<String, double> merchantTotals = {};

    for (var t in expenses) {
      final name = t.storeName.isNotEmpty ? t.storeName : t.title;
      merchantTotals[name] = (merchantTotals[name] ?? 0) + t.amount;
    }

    final sorted = merchantTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMerchants = sorted.take(5).toList();
    final double maxAmount = topMerchants.isNotEmpty ? topMerchants.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP MERCHANTS',
            style: GoogleFonts.manrope(color: Colors.grey[400], fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (topMerchants.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('No expenses this period', style: GoogleFonts.manrope(color: Colors.grey[500])),
            ))
          else
            ...topMerchants.map((m) {
              final percentage = (m.value / maxAmount).clamp(0.0, 1.0);
              return _buildMerchantItem(m.key, '$currency${m.value.toStringAsFixed(2)}', percentage);
            }),
        ],
      ),
    );
  }

  Widget _buildMerchantItem(String name, String amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(amount, style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6, // Slightly thicker
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(3)),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFF4ADE80), borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
