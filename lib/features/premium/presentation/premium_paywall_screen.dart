import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/premium_provider.dart';

class PremiumPaywallScreen extends ConsumerStatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  ConsumerState<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends ConsumerState<PremiumPaywallScreen> {
  bool _isLoading = false;

  void _handleUpgrade() async {
    setState(() => _isLoading = true);
    
    // Trigger mock payment
    await ref.read(premiumProvider.notifier).upgradeToPremium();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Show beautiful success dialog WITHOUT awaiting it to block
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline, color: Theme.of(context).primaryColor, size: 64),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to PRO!',
                    style: GoogleFonts.manrope(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'All advanced features are now unlocked.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), 
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutQuart),
        ),
      );

      // Wait a little bit for the user to see the success message
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Close the success dialog
        Navigator.of(context).pop();
        
        // Close the paywall
        context.pop(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 32),
                  ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Unlock ExpertMoney',
                    style: GoogleFonts.manrope(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  
                  Text(
                    'PRO',
                    style: GoogleFonts.manrope(
                      color: Theme.of(context).primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Get access to advanced analytics and take full control of your wealth.',
                    style: GoogleFonts.manrope(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Features List
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFeatureRow(Icons.pie_chart_outline, 'Advanced Charts', 'Unlock all premium visual analytics.'),
                        const SizedBox(height: 24),
                        _buildFeatureRow(Icons.insights, 'Smart Insights', 'Get custom tips based on your spending habits.'),
                        const SizedBox(height: 24),
                        _buildFeatureRow(Icons.auto_graph, 'Predictive Analytics', 'See where your money is going before it happens.'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                          ? SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 3)
                            )
                          : Text(
                              'Upgrade for \$4.99 / mo',
                              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().scale(delay: 800.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 16),
                  
                  Center(
                    child: Text(
                      'Cancel anytime. No hidden fees.',
                      style: GoogleFonts.manrope(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), 
                        fontSize: 12,
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
