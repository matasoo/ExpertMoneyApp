import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';

// Shared building blocks of the redesigned screens (Home, Wallet).

bool appIsDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

Color appInk(BuildContext context) => Theme.of(context).colorScheme.onSurface;

Color appMuted(BuildContext context) => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

Color appHairline(BuildContext context) => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07);

/// Black (ink) or white text for [background]. The threshold sits above the strict contrast
/// crossover (~0.19) so saturated blues/reds/purples keep white text, which reads better on them.
Color appOnColor(Color background) => background.computeLuminance() > 0.3 ? AppTheme.ink : Colors.white;

/// Cards: white on the light theme, the regular surface on dark.
BoxDecoration appCardDecoration(BuildContext context, {double radius = 24}) {
  final dark = appIsDark(context);
  return BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.06)) : null,
    boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6))],
  );
}

/// "$24,560" + dim ".40". `hide` masks the digits (privacy mode).
class AppMoney extends StatelessWidget {
  final double amount;
  final String currency;
  final bool hide;
  final TextStyle style;
  final String sign;
  final double decimalsAlpha;

  const AppMoney({
    super.key,
    required this.amount,
    required this.currency,
    required this.hide,
    required this.style,
    this.sign = '',
    this.decimalsAlpha = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    if (hide) {
      return Text('$sign${MoneyFormat.prefix(currency)}••••', style: style, maxLines: 1);
    }
    final parts = MoneyFormat.split(amount);
    final base = style.color ?? appInk(context);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: '$sign${MoneyFormat.prefix(currency)}${parts.whole}'),
          TextSpan(text: '.${parts.decimals}', style: TextStyle(color: base.withValues(alpha: decimalsAlpha))),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const AppSectionHeader({super.key, required this.title, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.manrope(color: appInk(context), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(action, style: GoogleFonts.manrope(color: appMuted(context), fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double value;
  final Color fill;

  const AppProgressBar({super.key, required this.value, required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 10,
        color: appInk(context).withValues(alpha: 0.08),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5))),
          ),
        ),
      ),
    );
  }
}

class AppIconTile extends StatelessWidget {
  final IconData icon;
  final bool lime;
  final double size;

  const AppIconTile({super.key, required this.icon, this.lime = true, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final dark = appIsDark(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: lime ? AppTheme.lime : (dark ? Colors.white.withValues(alpha: 0.08) : AppTheme.lightBackground),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: lime ? AppTheme.ink : appInk(context), size: size * 0.46),
    );
  }
}
