import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/theme/theme_provider.dart';

class StepProfile extends ConsumerWidget {
  final VoidCallback onNext;

  const StepProfile({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's personalize\nyour experience",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.2),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          Text(
            "Set your currency and preferred theme.",
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 48),
          
          Text("Main Currency", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600)).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          
          // Currency selection
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCurrencyChip(context, ref, '\$', 'USD', currentCurrency),
              _buildCurrencyChip(context, ref, '€', 'EURO', currentCurrency),
              _buildCurrencyChip(context, ref, '£', 'GBP', currentCurrency),
              _buildCurrencyChip(context, ref, 'RON', 'RON', currentCurrency),
            ],
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 48),
          
          Text("App Theme", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600)).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          
          // Theme selection
          Row(
            children: [
              Expanded(
                child: _buildThemeCard(
                  context: context,
                  title: 'Light',
                  icon: Icons.light_mode,
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildThemeCard(
                  context: context,
                  title: 'Dark',
                  icon: Icons.dark_mode,
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(BuildContext context, WidgetRef ref, String symbol, String name, String currentCurrency) {
    final isSelected = currentCurrency == symbol || currentCurrency == name; 
    
    return GestureDetector(
      onTap: () {
        print("Tapped currency: $symbol");
        ref.read(currencyProvider.notifier).setCurrency(symbol);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(symbol, style: GoogleFonts.manrope(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface
            )),
            const SizedBox(width: 8),
            Text(name, style: GoogleFonts.manrope(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context, 
    required String title, 
    required IconData icon, 
    required bool isSelected, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.1), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
            )),
          ],
        ),
      ),
    );
  }
}
