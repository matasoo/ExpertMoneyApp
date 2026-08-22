import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/premium_provider.dart';

class ExpertMoneyLogo extends ConsumerWidget {
  const ExpertMoneyLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Expert',
            style: GoogleFonts.manrope(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: 'Money',
                style: GoogleFonts.manrope(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
