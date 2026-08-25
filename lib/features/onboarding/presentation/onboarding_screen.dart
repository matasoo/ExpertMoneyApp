import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/currency_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import 'widgets/onboarding_slide.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    ref.read(hasSeenOnboardingProvider.notifier).set(true);
    ref.read(sharedPreferencesProvider).setBool('hasSeenOnboarding', true);
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: Theme.of(context).primaryColor,
                      dotColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      dotHeight: 4,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  TextButton(
                    onPressed: _onSkip,
                    child: Text('Skip', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  OnboardingSlide(
                    topWidget: Row(
                      children: [
                        Text(
                          'Expert',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Money',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                    titleWidget: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              height: 1.1,
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                            ),
                        children: [
                          TextSpan(text: 'Plan.\nSave.\n'),
                          TextSpan(text: 'Grow.', style: TextStyle(color: Theme.of(context).primaryColor)),
                        ],
                      ),
                    ),
                    subtitle: 'The financial planner that turns your income into goals you actually reach.',
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                  OnboardingSlide(
                    title: 'Budgets that keep\nyou on track',
                    subtitle: 'Set limits for food, fuel and fun. We nudge you before you overspend.',
                    graphic: _buildBudgetsMockup(),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                  OnboardingSlide(
                    title: 'Reach every\nsavings goal',
                    subtitle: 'From an emergency fund to a dream trip — see your progress grow week by week.',
                    graphic: _buildSavingsMockup(),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _onNext,
                child: Text(_currentPage == 2 ? 'Get started' : 'Next'),
              ).animate(target: _currentPage == 2 ? 1 : 0).shimmer(duration: 1000.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetsMockup() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildBudgetBar('Food', '\$120 / \$180', 0.66, Theme.of(context).primaryColor),
          SizedBox(height: 24),
          _buildBudgetBar('Fuel', '\$170 / \$200', 0.85, Theme.of(context).primaryColor),
          SizedBox(height: 24),
          _buildBudgetBar('Fun', '\$20 / \$150', 0.13, Theme.of(context).primaryColor),
        ],
      ),
    );
  }

  Widget _buildBudgetBar(String title, String amounts, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(amounts, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSavingsMockup() {
    return SizedBox(
      width: 200,
      height: 200,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 0.75),
        duration: Duration(seconds: 2),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                color: Theme.of(context).primaryColor,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${ref.watch(currencyProvider)} ${(6000 * value).toInt()}', style: Theme.of(context).textTheme.headlineSmall),
                  Text('of ${ref.watch(currencyProvider)}6,000 · Vacation', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
