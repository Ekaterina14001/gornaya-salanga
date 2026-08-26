import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/salanga_colors.dart';

class SalangaBrandHeader extends StatelessWidget {
  const SalangaBrandHeader({
    super.key,
    this.compact = false,
    this.showSubtitle = true,
  });

  final bool compact;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            color: SalangaColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SalangaColors.sand, width: 2),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/logo_mark.png',
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'Горная Саланга',
          textAlign: TextAlign.center,
          style: GoogleFonts.ptSerif(
            fontSize: compact ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: SalangaColors.textDark,
            height: 1.1,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'таёжный курорт',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: SalangaColors.warmBrown,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
