import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_page_screen.dart';
import 'login_page_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class LearnTrackPage extends StatelessWidget {
  const LearnTrackPage({Key? key}) : super(key: key);

  static const _brainSvg =
      '''<svg width="68" height="56" viewBox="0 0 68 56" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M24.4375 0C28.5414 0 31.875 2.74531 31.875 6.125V49.875C31.875 53.2547 28.5414 56 24.4375 56C20.5992 56 17.4383 53.6047 17.0398 50.5203C16.3492 50.6734 15.6187 50.75 14.875 50.75C10.1867 50.75 6.375 47.6109 6.375 43.75C6.375 42.9406 6.54766 42.1531 6.85312 41.4312C2.84219 40.1844 0 36.9906 0 33.25C0 29.7609 2.48359 26.7422 6.08281 25.3422C4.92734 24.15 4.25 22.6406 4.25 21C4.25 17.6422 7.11875 14.8422 10.9438 14.1531C10.7312 13.5516 10.625 12.9062 10.625 12.25C10.625 8.97969 13.3609 6.22344 17.0398 5.45781C17.4383 2.39531 20.5992 0 24.4375 0ZM43.5625 0C47.4008 0 50.5484 2.39531 50.9602 5.45781C54.6523 6.22344 57.375 8.96875 57.375 12.25C57.375 12.9062 57.2687 13.5516 57.0563 14.1531C60.8813 14.8312 63.75 17.6422 63.75 21C63.75 22.6406 63.0727 24.15 61.9172 25.3422C65.5164 26.7422 68 29.7609 68 33.25C68 36.9906 65.1578 40.1844 61.1469 41.4312C61.4523 42.1531 61.625 42.9406 61.625 43.75C61.625 47.6109 57.8133 50.75 53.125 50.75C52.3812 50.75 51.6508 50.6734 50.9602 50.5203C50.5617 53.6047 47.4008 56 43.5625 56C39.4586 56 36.125 53.2547 36.125 49.875V6.125C36.125 2.74531 39.4586 0 43.5625 0Z" fill="white"/>
      </svg>''';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              colors.accentGradientStart.withValues(alpha: 0.16),
              colors.background,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth <= 640;

            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 24.0,
                    vertical: isSmallScreen ? 32.0 : 64.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Column(
                      children: [
                        SizedBox(height: isSmallScreen ? 12 : 24),
                        // Logo mark
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.accentGradientStart,
                                colors.accentGradientEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colors.accentGradientStart.withValues(alpha: 0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: SvgPicture.string(_brainSvg),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'LearnTrack',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 32.0 : 36.0,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your Study Plan, Simplified.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 16.0 : 18.0,
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 48 : 64),

                        // Feature highlights
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureChip(
                              icon: Icons.stars,
                              label: 'AI paths',
                              colors: colors,
                            ),
                            _FeatureChip(
                              icon: Icons.timer_outlined,
                              label: 'Focus timer',
                              colors: colors,
                            ),
                            _FeatureChip(
                              icon: Icons.whatshot,
                              label: 'Streaks',
                              colors: colors,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 48 : 64),

                        // Buttons
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colors.accentGradientStart,
                                      colors.accentGradientEnd,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.accentGradientStart
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen()),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Center(
                                      child: Text(
                                        'Log In',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  border: Border.all(
                                    color: colors.accent,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SignUpScreen()),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Center(
                                      child: Text(
                                        'Sign Up',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: colors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColorsExt colors;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.accentSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colors.accent, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
