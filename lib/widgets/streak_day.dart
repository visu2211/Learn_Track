import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class StreakDay extends StatelessWidget {
  final String day;
  final bool isCompleted;

  const StreakDay({
    Key? key,
    required this.day,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          day,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
            color: isCompleted ? colors.accent : colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: isCompleted ? colors.accentSurface : Colors.transparent,
            border: Border.all(
              color: isCompleted ? colors.accent : colors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: colors.accent,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
