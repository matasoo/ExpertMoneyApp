import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/tutorial_slider.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import 'widgets/dashboard_nav_bar.dart';
import 'widgets/home_tab.dart';
import 'widgets/transaction_bottom_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _getPageIndexFromTab(_currentIndex));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial(_getPageIndexFromTab(_currentIndex));
    });
  }

  void _checkAndShowTutorial(int pageIndex) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      // Only show if the user actually stayed on this page (didn't just swipe through it)
      if (_pageController.page?.round() != pageIndex) return;

      if (pageIndex == 1) {
        if (!ref.read(hasSeenAnalyticsTutorialProvider)) {
          _showAnalyticsTutorial();
        }
      } else if (pageIndex == 2) {
        if (!ref.read(hasSeenGoalsTutorialProvider)) {
          _showGoalsTutorial();
        }
      } else if (pageIndex == 3) {
        if (!ref.read(hasSeenWalletTutorialProvider)) {
          _showWalletTutorial();
        }
      }
    });
  }

  void _showAnalyticsTutorial() {
    ref.read(hasSeenAnalyticsTutorialProvider.notifier).set(true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TutorialSlider(
        slides: [
          TutorialSlide(title: 'Expense Breakdown', description: 'See exactly where your money goes with clear categories and visual charts.', icon: Icons.pie_chart_outline),
          TutorialSlide(title: 'Cashflow Analysis', description: 'Track your income vs expenses over time to ensure you stay positive.', icon: Icons.auto_graph, color: Colors.green),
          TutorialSlide(title: 'Trend Tracking', description: 'Compare current spending with past periods to identify habits and improve.', icon: Icons.timeline, color: Colors.purple),
        ],
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showGoalsTutorial() {
    ref.read(hasSeenGoalsTutorialProvider.notifier).set(true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TutorialSlider(
        slides: [
          TutorialSlide(title: 'Smart Budgets', description: 'Set spending limits by category and track how much you have left.', icon: Icons.track_changes),
          TutorialSlide(title: 'Savings Goals', description: 'Save for your dreams. Create goals and add contributions.', icon: Icons.savings, color: Colors.green),
          TutorialSlide(title: 'Automated Tracking', description: 'Set goals on autopilot with automatic monthly deductions.', icon: Icons.autorenew, color: Colors.blue),
        ],
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showWalletTutorial() {
    ref.read(hasSeenWalletTutorialProvider.notifier).set(true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TutorialSlider(
        slides: [
          TutorialSlide(title: 'Bank Accounts', description: 'Manage all your accounts in one place. Add cash, cards, and savings.', icon: Icons.account_balance),
          TutorialSlide(title: 'Subscriptions & Bills', description: 'Never miss a payment again. Keep track of all your recurring expenses.', icon: Icons.live_tv, color: Colors.orange),
          TutorialSlide(title: 'Active Credits & Loans', description: 'Monitor your active credits, track payments, and see remaining balances.', icon: Icons.credit_card, color: Colors.purple),
        ],
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getPageIndexFromTab(int tabIndex) {
    if (tabIndex == 0) return 0;
    if (tabIndex == 1) return 1;
    if (tabIndex == 3) return 2;
    if (tabIndex == 4) return 3;
    return 0;
  }

  int _getTabIndexFromPage(int pageIndex) {
    if (pageIndex == 0) return 0;
    if (pageIndex == 1) return 1;
    if (pageIndex == 2) return 3;
    if (pageIndex == 3) return 4;
    return 0;
  }

  void _openTab(int tabIndex) {
    setState(() => _currentIndex = tabIndex);
    _pageController.animateToPage(
      _getPageIndexFromTab(tabIndex),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true, // Allows body to scroll underneath the bottom navigation bar
        body: SafeArea(
          bottom: false,
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = _getTabIndexFromPage(index);
              });
              _checkAndShowTutorial(index);
            },
            children: [
              StreamBuilder<Map<String, dynamic>?>(
                stream: firestoreService.userProfileStream(),
                builder: (context, snapshot) => HomeTab(userProfile: snapshot.data, onOpenTab: _openTab),
              ),
              const AnalyticsScreen(),
              const GoalsScreen(),
              const WalletScreen(),
            ],
          ),
        ),
        bottomNavigationBar: DashboardNavBar(
          currentIndex: _currentIndex,
          onTab: _openTab,
          onAdd: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TransactionBottomSheet(),
          ),
        ),
      ),
    );
  }
}
