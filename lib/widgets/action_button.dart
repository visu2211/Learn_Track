import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  }) : super(key: key);

  String _iconSvg(Color fill) {
    final hex = '#${fill.toARGB32().toRadixString(16).substring(2)}';
    if (icon == 'timer') {
      return '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 0C15.1826 0 18.2348 1.26428 20.4853 3.51472C22.7357 5.76516 24 8.8174 24 12C24 15.1826 22.7357 18.2348 20.4853 20.4853C18.2348 22.7357 15.1826 24 12 24C8.8174 24 5.76516 22.7357 3.51472 20.4853C1.26428 18.2348 0 15.1826 0 12C0 8.8174 1.26428 5.76516 3.51472 3.51472C5.76516 1.26428 8.8174 0 12 0ZM10.875 5.625V12C10.875 12.375 11.0625 12.7266 11.3766 12.9375L15.8766 15.9375C16.3922 16.2844 17.0906 16.1437 17.4375 15.6234C17.7844 15.1031 17.6437 14.4094 17.1234 14.0625L13.125 11.4V5.625C13.125 5.00156 12.6234 4.5 12 4.5C11.3766 4.5 10.875 5.00156 10.875 5.625Z" fill="$hex"/>
      </svg>''';
    } else {
      return '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M24 4.5C24 6.85313 21.2297 10.3641 20.0344 11.7656C19.8562 11.9719 19.5938 12.0516 19.3547 12H15C14.1703 12 13.5 12.6703 13.5 13.5C13.5 14.3297 14.1703 15 15 15H19.5C21.9844 15 24 17.0156 24 19.5C24 21.9844 21.9844 24 19.5 24H6.54375C6.95156 23.5359 7.44844 22.9406 7.95 22.275C8.24531 21.8813 8.55 21.45 8.84063 21H19.5C20.3297 21 21 20.3297 21 19.5C21 18.6703 20.3297 18 19.5 18H15C12.5156 18 10.5 15.9844 10.5 13.5C10.5 11.0156 12.5156 9 15 9H16.8656C15.8812 7.52344 15 5.82656 15 4.5C15 2.01562 17.0156 0 19.5 0C21.9844 0 24 2.01562 24 4.5ZM5.48906 22.9266C5.31094 23.1281 5.15156 23.3062 5.01562 23.4562L4.93125 23.55L4.92188 23.5406C4.64062 23.7563 4.2375 23.7281 3.98438 23.4562C2.80312 22.1719 0 18.8672 0 16.5C0 14.0156 2.01562 12 4.5 12C6.98438 12 9 14.0156 9 16.5C9 17.9062 8.01094 19.6406 6.96094 21.0891C6.45937 21.7781 5.94375 22.4016 5.51719 22.8937L5.48906 22.9266Z" fill="$hex"/>
      </svg>''';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [colors.accentGradientStart, colors.accentGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: colors.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              _iconSvg(isActive ? Colors.white : colors.textPrimary),
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isActive ? Colors.white : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
