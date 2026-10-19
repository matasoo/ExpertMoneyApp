import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Floating pill navigation: the active tab is a lime circle, "+" is an action.
class DashboardNavBar extends StatelessWidget {
  /// Tab index: 0 home, 1 stats, 3 goals, 4 wallet (2 is the "+" action).
  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  const DashboardNavBar({super.key, required this.currentIndex, required this.onTab, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2D) : AppTheme.ink,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.22), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _item(Icons.home_rounded, Icons.home_outlined, 0),
              _item(Icons.insert_chart_rounded, Icons.insert_chart_outlined_rounded, 1),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, color: AppTheme.ink, size: 30),
                ),
              ),
              _item(Icons.track_changes_rounded, Icons.track_changes_outlined, 3),
              _item(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData filled, IconData outlined, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: isSelected ? AppTheme.lime : Colors.transparent, shape: BoxShape.circle),
        child: Icon(
          isSelected ? filled : outlined,
          color: isSelected ? AppTheme.ink : Colors.white.withValues(alpha: 0.62),
          size: 26,
        ),
      ),
    );
  }
}
