import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../security/providers/privacy_provider.dart';

class DynamicBalanceCard extends ConsumerStatefulWidget {
  final int accountsCount;
  final double totalBalance;
  final double monthlyChange;
  final String currentMonthName;
  
  const DynamicBalanceCard({
    super.key,
    required this.accountsCount,
    required this.totalBalance,
    required this.monthlyChange,
    required this.currentMonthName,
  });

  @override
  ConsumerState<DynamicBalanceCard> createState() => _DynamicBalanceCardState();
}

class _DynamicBalanceCardState extends ConsumerState<DynamicBalanceCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.15), // Dark green
            Theme.of(context).primaryColor.withValues(alpha: 0.25), // Very dark green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10b981).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Animated Particles Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlesPainter(animationValue: _controller.value),
                  );
                },
              ),
            ),
            
            // Card Content
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total balance · ${widget.accountsCount} accounts',
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final isPrivacyOn = ref.watch(privacyProvider);
                      final currency = ref.watch(currencyProvider);
                      final displayBalance = isPrivacyOn ? '****' : widget.totalBalance.toStringAsFixed(2);
                      return Text(
                        '${ref.watch(currencyProvider)} $displayBalance',
                        style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                      );
                    }
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        widget.monthlyChange >= 0 ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                        color: widget.monthlyChange >= 0 ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.error, 
                        size: 16
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${widget.monthlyChange >= 0 ? '+' : '-'} ${ref.watch(currencyProvider)}${widget.monthlyChange.abs().toStringAsFixed(2)} in ${widget.currentMonthName}',
                        style: GoogleFonts.manrope(
                          color: widget.monthlyChange >= 0 ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.error, 
                          fontSize: 13, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Random random = Random(42); // Fixed seed for consistent particles

  _ParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20); // Glowing effect

    final particleCount = 6;
    
    for (int i = 0; i < particleCount; i++) {
      // Generate somewhat random parameters for each particle based on its index
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      
      final radius = 20.0 + random.nextDouble() * 40.0;
      
      final speedX = (random.nextDouble() - 0.5) * 2;
      final speedY = (random.nextDouble() - 0.5) * 2;
      
      // Calculate current position based on animation loop (0.0 to 1.0)
      // Multiply by a large number so they move across the screen and loop smoothly
      // Using sine/cosine to make them drift in organic paths
      final x = startX + sin((animationValue * 2 * pi) + i) * 50 * speedX;
      final y = startY + cos((animationValue * 2 * pi) + i) * 50 * speedY;
      
      // Varying opacity
      final opacity = 0.1 + (sin(animationValue * 2 * pi + i) + 1) * 0.1;
      paint.color = Color(0xFF10B981).withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
