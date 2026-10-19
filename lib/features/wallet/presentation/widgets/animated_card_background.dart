import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedCardBackground extends StatefulWidget {
  final Widget child;
  final Color baseColor;

  const AnimatedCardBackground({super.key, required this.child, required this.baseColor});

  @override
  State<AnimatedCardBackground> createState() => _AnimatedCardBackgroundState();
}

class _AnimatedCardBackgroundState extends State<AnimatedCardBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color1 = widget.baseColor.withValues(alpha: 0.5);
    final color2 = widget.baseColor.withValues(alpha: 0.2);
    final color3 = widget.baseColor.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_controller.value * 2 * math.pi),
                math.sin(_controller.value * 2 * math.pi),
              ),
              end: Alignment(
                math.cos(_controller.value * 2 * math.pi + math.pi),
                math.sin(_controller.value * 2 * math.pi + math.pi),
              ),
              colors: [color1, color2, color3, color2],
              stops: const [0.0, 0.4, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
