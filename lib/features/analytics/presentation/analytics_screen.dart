import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/pro_advanced_charts.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../../core/widgets/expert_money_logo.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../dashboard/domain/models/transaction.dart';
import '../../dashboard/providers/transactions_provider.dart';
import '../../goals/providers/budgets_provider.dart';
import '../../goals/domain/models/budget.dart';
import '../../wallet/providers/recurring_payments_provider.dart';
import '../../wallet/providers/credits_provider.dart';

import '../../../../core/providers/premium_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _mainTabIndex = 0; // 0 = Overview, 1 = Subscriptions, 2 = Credits
  int _selectedPeriodIndex = 1; // 0 = Week, 1 = Month, 2 = Year
  DateTime _selectedDate = DateTime.now();

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTransactions) {
    return allTransactions.where((t) {
      if (!t.isExpense) return false;
      
      final d = t.date;
      if (_selectedPeriodIndex == 0) {
        final diff = _selectedDate.difference(d).inDays;
        return diff >= 0 && diff < 7;
      } else if (_selectedPeriodIndex == 1) {
        return d.year == _selectedDate.year && d.month == _selectedDate.month;
      } else {
        return d.year == _selectedDate.year;
      }
    }).toList();
  }

  List<TransactionModel> _getPreviousFilteredTransactions(List<TransactionModel> allTransactions) {
    DateTime prevDate;
    if (_selectedPeriodIndex == 0) {
      prevDate = _selectedDate.subtract(Duration(days: 7));
    } else if (_selectedPeriodIndex == 1) {
      prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
    } else {
      prevDate = DateTime(_selectedDate.year - 1, _selectedDate.month, _selectedDate.day);
    }
    
    return allTransactions.where((t) {
      if (!t.isExpense) return false;
      
      final d = t.date;
      if (_selectedPeriodIndex == 0) {
        final diff = prevDate.difference(d).inDays;
        return diff >= 0 && diff < 7;
      } else if (_selectedPeriodIndex == 1) {
        return d.year == prevDate.year && d.month == prevDate.month;
      } else {
        return d.year == prevDate.year;
      }
    }).toList();
  }

  Map<String, double> _calculateCategoryTotals(List<TransactionModel> transactions) {
    final Map<String, double> totals = {};
    for (var t in transactions) {
      String catName = t.category == TransactionCategory.other && t.customCategoryName != null && t.customCategoryName!.isNotEmpty
          ? t.customCategoryName!
          : t.category.name.substring(0, 1).toUpperCase() + t.category.name.substring(1);
      totals[catName] = (totals[catName] ?? 0) + t.amount;
    }
    return totals;
  }

  List<double> _calculateLast7Days(List<TransactionModel> allTransactions) {
    final today = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final List<double> weekly = List.filled(7, 0.0);
    
    for (var t in allTransactions) {
      if (!t.isExpense) continue;
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final diff = today.difference(tDate).inDays;
      if (diff >= 0 && diff < 7) {
        weekly[6 - diff] += t.amount;
      }
    }
    return weekly;
  }

  List<FlSpot> _calculateLineChartData(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return [FlSpot(0, 0), FlSpot(1, 0)];
    }

    final sorted = List<TransactionModel>.from(transactions)..sort((a, b) => a.date.compareTo(b.date));
    final List<FlSpot> spots = [];
    double cumulative = 0.0;
    
    if (_selectedPeriodIndex == 0) {
      // Week
      final start = _selectedDate.subtract(Duration(days: 6));
      Map<int, double> dailyTotals = {};
      for (var t in sorted) {
        final dayIndex = t.date.difference(start).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyTotals[dayIndex] = (dailyTotals[dayIndex] ?? 0) + t.amount;
        }
      }
      for (int i = 0; i < 7; i++) {
        cumulative += dailyTotals[i] ?? 0;
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
    } else if (_selectedPeriodIndex == 1) {
      // Month
      final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      Map<int, double> dailyTotals = {};
      for (var t in sorted) {
        dailyTotals[t.date.day] = (dailyTotals[t.date.day] ?? 0) + t.amount;
      }
      for (int i = 1; i <= daysInMonth; i++) {
        cumulative += dailyTotals[i] ?? 0;
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
    } else {
      // Year
      Map<int, double> monthlyTotals = {};
      for (var t in sorted) {
        monthlyTotals[t.date.month] = (monthlyTotals[t.date.month] ?? 0) + t.amount;
      }
      for (int i = 1; i <= 12; i++) {
        cumulative += monthlyTotals[i] ?? 0;
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
    }
    
    return spots;
  }

  String _getShortWeekday(DateTime date) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  Future<void> _pickDate() async {
    if (_selectedPeriodIndex == 2) {
      // Pick Year
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Select Year', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
                itemCount: 15, // 10 years in the past, 5 years in the future
                itemBuilder: (context, index) {
                  final year = DateTime.now().year - 10 + index;
                  final isSelected = year == _selectedDate.year;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(year, _selectedDate.month, _selectedDate.day);
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text('$year', style: GoogleFonts.manrope(color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          );
        }
      );
    } else if (_selectedPeriodIndex == 1) {
      // Pick Month
      int tempYear = _selectedDate.year;
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface), onPressed: () => setDialogState(() => tempYear--)),
                    Text('$tempYear', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface), onPressed: () => setDialogState(() => tempYear++)),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 250,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final isSelected = tempYear == _selectedDate.year && (index + 1) == _selectedDate.month;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(tempYear, index + 1, 1);
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(monthNames[index], style: GoogleFonts.manrope(color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          );
        }
      );
    } else {
      // Pick Week (Normal Date Picker)
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: Theme.of(context).primaryColor,
                onPrimary: Theme.of(context).colorScheme.onSurface,
                surface: Theme.of(context).colorScheme.surface,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
            ),
            child: child!,
          );
        },
      );
      if (date != null) {
        setState(() => _selectedDate = date);
      }
    }
  }

  String _getPeriodLabel() {
    if (_selectedPeriodIndex == 0) {
      final start = _selectedDate.subtract(Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(_selectedDate)}';
    } else if (_selectedPeriodIndex == 1) {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    } else {
      return '${_selectedDate.year}';
    }
  }

  String _getComparisonLabel() {
    if (_selectedPeriodIndex == 0) return 'vs last week';
    if (_selectedPeriodIndex == 1) return 'vs ${DateFormat('MMM').format(DateTime(_selectedDate.year, _selectedDate.month - 1))}';
    return 'vs ${_selectedDate.year - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);
    final budgets = ref.watch(budgetsProvider);
    final isPremium = ref.watch(premiumProvider);
    final currency = ref.watch(currencyProvider);
    
    final currentTransactions = _getFilteredTransactions(allTransactions);
    final previousTransactions = _getPreviousFilteredTransactions(allTransactions);

    final currentTotal = currentTransactions.fold(0.0, (s, t) => s + t.amount);
    final previousTotal = previousTransactions.fold(0.0, (s, t) => s + t.amount);

    double percentChange = 0;
    if (previousTotal > 0) {
      percentChange = ((currentTotal - previousTotal) / previousTotal) * 100;
    } else if (currentTotal > 0) {
      percentChange = 100; // Infinity in reality, but display 100%
    }

    final categoryTotals = _calculateCategoryTotals(currentTransactions);
    final weeklyData = _calculateLast7Days(allTransactions); // Always last 7 days from selected date
    final lineChartSpots = _calculateLineChartData(currentTransactions);
    
    int divisor = 30;
    if (_selectedPeriodIndex == 0) {
      divisor = 7;
    } else if (_selectedPeriodIndex == 1) divisor = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    else divisor = 365;

    Widget activeTab;
    if (_mainTabIndex == 0) {
      activeTab = Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SEGMENTED CONTROL ---
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildPeriodTab('Week', 0),
                _buildPeriodTab('Month', 1),
                _buildPeriodTab('Year', 2),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          SizedBox(height: 32),

          // --- SPENDING OVERVIEW (LINE CHART) ---
          _buildSpendingOverviewCard(currentTotal, percentChange, divisor, lineChartSpots)
              .animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          SizedBox(height: 24),

          // --- BUDGETS CARD ---
          if (budgets.isNotEmpty)
            _buildBudgetsCard(budgets).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0)
          else
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No budgets created yet.', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              ),
            ).animate().fadeIn(delay: 200.ms),
            
          SizedBox(height: 24),

          // --- LAST 7 DAYS (BAR CHART) ---
          Text(
            '7-Day Breakdown',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
          ).animate().fadeIn(delay: 300.ms),
          SizedBox(height: 16),
          _buildWeeklyBarChart(weeklyData).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 32),
          _buildPremiumProjections(isPremium, currentTransactions, allTransactions, currency)
              .animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      );
    } else if (_mainTabIndex == 1) {
      activeTab = Container(
        key: const ValueKey(1),
        width: double.infinity,
        child: _buildSubscriptionsAnalyticsTab(),
      );
    } else {
      activeTab = Container(
        key: const ValueKey(2),
        width: double.infinity,
        child: _buildCreditsAnalyticsTab(),
      );
    }

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
                  ],
                ),
                SizedBox(height: 32),
                
                Text(
                  'Statistics',
                  style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -1.0),
                ),
                SizedBox(height: 24),

                // --- MAIN TABS ---
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildMainTab('Overview', 0),
                      _buildMainTab('Subscriptions', 1),
                      _buildMainTab('Credits', 2),
                    ],
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                        child: child,
                      ),
                    );
                  },
                  child: activeTab,
                ),

                SizedBox(height: 120), // Padding for floating nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String title, int index) {
    final isActive = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.9) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.manrope(
              color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingOverviewCard(double totalExpenses, double percentChange, int divisor, List<FlSpot> spots) {
    final isIncrease = percentChange > 0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending Overview', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: _pickDate,
                child: Row(
                  children: [
                    Text(_getPeriodLabel(), style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 16),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text('Total Spent', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(
            '\$ ${totalExpenses.toStringAsFixed(2)}',
            style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1.0),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward, 
                color: isIncrease ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor, 
                size: 14
              ),
              SizedBox(width: 4),
              Text('${percentChange.abs().toStringAsFixed(1)}% ', style: GoogleFonts.manrope(color: isIncrease ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(_getComparisonLabel(), style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 32),
          
          // Line Chart
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          
          // AVG Daily Spend
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              'AVG Daily Spend: \$${(totalExpenses / divisor).toStringAsFixed(0)}',
              style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsCard(List<BudgetModel> budgets) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budgets', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 24),
          ...budgets.map((budget) {
            double target = budget.limitAmount;
            double current = budget.currentSpent;
            
            double percentage = target > 0 ? current / target : 0;
            if (percentage > 1.0) percentage = 1.0;
            
            final isOverBudget = current > target;
            final barColor = isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;

            return Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(budget.icon, style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(budget.category, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Text('(${budget.resetPeriod})', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      // Progress Bar
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(6)),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(color: barColor.withValues(alpha: 0.5), blurRadius: 8, offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Value texts
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '\$${current.toStringAsFixed(0)} ', style: GoogleFonts.manrope(color: isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w800)),
                            TextSpan(text: '/ \$${target.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${(percentage * 100).toInt()}%',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.manrope(color: barColor, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  Widget _buildWeeklyBarChart(List<double> weeklyData) {
    double maxVal = weeklyData.isEmpty ? 100 : weeklyData.reduce(max);
    if (maxVal == 0) maxVal = 100;

    return Container(
      height: 200,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final dayDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).subtract(Duration(days: 6 - value.toInt()));
                  return Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(_getShortWeekday(dayDate), style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
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
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weeklyData[i],
                  color: Theme.of(context).primaryColor,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.2,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMainTab(String title, int index) {
    final isActive = _mainTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mainTabIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.manrope(
              color: isActive ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionsAnalyticsTab() {
    final subscriptions = ref.watch(recurringPaymentsProvider);
    final totalLifetime = subscriptions.fold(0.0, (sum, sub) => sum + sub.totalPaidSoFar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Paid on Subscriptions', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('\$${totalLifetime.toStringAsFixed(2)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
            ],
          ),
        ),
        SizedBox(height: 24),
        Text('Lifetime Costs', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        SizedBox(height: 16),
        if (subscriptions.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No subscriptions to analyze.', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
          )
        else
          ...subscriptions.map((sub) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(sub.icon, style: TextStyle(fontSize: 20)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub.name, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Started ${DateFormat('MMM yyyy').format(sub.startDate)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${sub.totalPaidSoFar.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('total paid', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCreditsAnalyticsTab() {
    final credits = ref.watch(creditsProvider);
    final totalRemaining = credits.fold(0.0, (sum, credit) => sum + (credit.totalAmount - credit.paidAmount).clamp(0, double.infinity));
    final totalPaid = credits.fold(0.0, (sum, credit) => sum + credit.paidAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Debt', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('\$${totalRemaining.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Paid', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('\$${totalPaid.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Text('Debt Timeline', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        SizedBox(height: 16),
        if (credits.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('You have no active credits!', textAlign: TextAlign.center, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
          )
        else
          ...credits.map((credit) {
            double remaining = credit.totalAmount - credit.paidAmount;
            if (remaining < 0) remaining = 0;
            
            int monthsLeft = 0;
            if (credit.monthlyContribution > 0) {
              monthsLeft = (remaining / credit.monthlyContribution).ceil();
            }

            return Container(
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
                    children: [
                      Text(credit.icon, style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(credit.name, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          monthsLeft > 0 ? '$monthsLeft months left' : 'Paid Off 🎉',
                          style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${credit.paidAmount.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('\$${credit.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: credit.progress,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      color: Theme.of(context).primaryColor,
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Rate:', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                      Text('\$${credit.monthlyContribution.toStringAsFixed(2)}', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (monthsLeft > 0) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Est. Payoff Date:', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                         Text(DateFormat('MMMM yyyy').format(DateTime.now().add(Duration(days: 30 * monthsLeft))), style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ]
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPremiumChartWrapper(Widget child, bool isPremium, BuildContext context) {
    if (isPremium) return child;

    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: child,
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.onSurface, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'PRO Feature',
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to unlock',
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/paywall'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text('Upgrade to PRO', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumProjections(bool isPremium, List<TransactionModel> currentTransactions, List<TransactionModel> allTransactions, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Analytics',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
        ),
        SizedBox(height: 16),
        _buildPremiumChartWrapper(
          ProCategoriesChart(transactions: currentTransactions, currency: currency),
          isPremium,
          context,
        ),
        const SizedBox(height: 16),
        _buildPremiumChartWrapper(
          ProIncomeExpensesChart(allTransactions: allTransactions, currency: currency),
          isPremium,
          context,
        ),
        const SizedBox(height: 16),
        _buildPremiumChartWrapper(
          ProTopMerchantsChart(transactions: currentTransactions, currency: currency),
          isPremium,
          context,
        ),
      ],
    );
  }
}
