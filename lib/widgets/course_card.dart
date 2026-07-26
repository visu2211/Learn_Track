import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String details;
  final double progress;
  final VoidCallback? onTap;

  const CourseCard({
    Key? key,
    required this.title,
    required this.details,
    this.progress = 0.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (progress > 0)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.accentSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar. FractionallySizedBox sizes the filled portion as
            // a fraction of ITS OWN parent's width - a previous version
            // computed the fill as `MediaQuery screen width * 0.7 * progress`,
            // which meant a "100%" bar only ever filled to whatever fraction
            // of the actual card width 0.7*screenWidth happened to be, never
            // the full bar. Sizing relative to the real container instead of
            // guessing from screen size is the general fix for this class of bug.
            if (progress > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  height: 4,
                  color: colors.border,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: colors.accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
