import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import 'steps/step_profile.dart';
import 'steps/step_income.dart';
import 'steps/step_savings.dart';
import 'steps/step_costs.dart';
import 'steps/step_all_set.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int get _totalSteps => 5;

  void _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      try {
        await ref.read(hasCompletedSetupProvider.notifier).completeSetup();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error in completeSetup: $e')));
        }
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(), // Prevent swipe to enforce step logic
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  StepProfile(onNext: _nextStep),
                  StepIncome(onNext: _nextStep),
                  StepSavings(onNext: _nextStep),
                  StepCosts(onNext: _nextStep),
                  StepAllSet(onNext: _nextStep),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 14),
              onPressed: _prevStep,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: (_currentStep + 1) / _totalSteps),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 16),
          Text('${_currentStep + 1}/$_totalSteps', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
