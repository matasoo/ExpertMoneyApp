import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String subtitle;
  final Widget? graphic;
  final Widget? topWidget;

  const OnboardingSlide({
    super.key,
    this.title,
    this.titleWidget,
    required this.subtitle,
    this.graphic,
    this.topWidget,
  }) : assert(title != null || titleWidget != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topWidget != null) ...[
            const SizedBox(height: 32),
            topWidget!,
          ],
          const Spacer(),
          if (graphic != null) ...[
            Center(child: graphic!),
            const SizedBox(height: 48),
          ],
          if (titleWidget != null)
            titleWidget!
          else
            Text(
              title!,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    height: 1.2,
                  ),
            ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
