import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Create subtle variations of the base color
    final color1 = baseColor;
    final color2 = isDark 
        ? Color.lerp(baseColor, Colors.white, 0.03)! 
        : Color.lerp(baseColor, Colors.black, 0.03)!;
    final color3 = isDark 
        ? Color.lerp(baseColor, Theme.of(context).primaryColor, 0.05)!
        : Color.lerp(baseColor, Theme.of(context).primaryColor, 0.03)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_controller.value * 2 * math.pi),
                math.sin(_controller.value * 2 * math.pi),
              ),
              end: Alignment(
                math.cos(_controller.value * 2 * math.pi + math.pi),
                math.sin(_controller.value * 2 * math.pi + math.pi),
              ),
              colors: [color1, color2, color3, color1],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
