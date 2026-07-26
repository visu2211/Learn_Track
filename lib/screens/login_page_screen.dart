import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'signup_page_screen.dart';
import 'learn_track_dash.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: CustomPaint(
                          painter: LogoPainter(),
                          size: const Size(68, 56),
                        ),
                      ),
                      Text(
                        'LearnTrack',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: colors.shadow,
                          offset: const Offset(0, 10),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Log In',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Email Input
                        CustomInputField(
                          label: 'Email',
                          placeholder: 'Enter your email',
                          icon: Icons.mail_outline,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        CustomInputField(
                          label: 'Password',
                          placeholder: 'Enter your password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 16),

                        // Remember Me
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sign In Button
                        CustomButton(
                          text: 'Sign in',
                          onPressed: () async {
                            if (_emailController.text.trim().isEmpty ||
                                _passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please enter both email and password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);

                            try {
                              // First check if server is reachable
                              final serverConnected =
                                  await authProvider.checkServerConnection();
                              if (!serverConnected) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cannot connect to server. Please make sure the backend is running on port 8000.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                // Show loading indicator
                              });

                              await authProvider.signIn(
                                _emailController.text.trim(),
                                _passwordController.text,
                              );

                              if (!mounted) return;

                              if (authProvider.isAuthenticated) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LearnTrackDash()),
                                );
                              } else if (authProvider.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authProvider.error!,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                // This should not happen, but handle just in case
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Invalid email or password. Please try again.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: ${e.toString()}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Prompt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen()),
                                );
                              },
                              child: Text(
                                'Sign up',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final paint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.fill;

    path.moveTo(24.4375 * size.width / 68, 0);
    path.cubicTo(
      28.5414 * size.width / 68,
      0,
      31.875 * size.width / 68,
      2.74531 * size.height / 56,
      31.875 * size.width / 68,
      6.125 * size.height / 56,
    );
    path.lineTo(31.875 * size.width / 68, 49.875 * size.height / 56);
    path.cubicTo(
      31.875 * size.width / 68,
      53.2547 * size.height / 56,
      28.5414 * size.width / 68,
      56 * size.height / 56,
      24.4375 * size.width / 68,
      56 * size.height / 56,
    );
    path.cubicTo(
      20.5992 * size.width / 68,
      56 * size.height / 56,
      17.4383 * size.width / 68,
      53.6047 * size.height / 56,
      17.0398 * size.width / 68,
      50.5203 * size.height / 56,
    );
    path.cubicTo(
      16.3492 * size.width / 68,
      50.6734 * size.height / 56,
      15.6187 * size.width / 68,
      50.75 * size.height / 56,
      14.875 * size.width / 68,
      50.75 * size.height / 56,
    );
    path.cubicTo(
      10.1867 * size.width / 68,
      50.75 * size.height / 56,
      6.375 * size.width / 68,
      47.6109 * size.height / 56,
      6.375 * size.width / 68,
      43.75 * size.height / 56,
    );
    path.cubicTo(
      6.375 * size.width / 68,
      42.9406 * size.height / 56,
      6.54766 * size.width / 68,
      42.1531 * size.height / 56,
      6.85312 * size.width / 68,
      41.4312 * size.height / 56,
    );
    path.cubicTo(
      2.84219 * size.width / 68,
      40.1844 * size.height / 56,
      0,
      36.9906 * size.height / 56,
      0,
      33.25 * size.height / 56,
    );
    path.cubicTo(
      0,
      29.7609 * size.height / 56,
      2.48359 * size.width / 68,
      26.7422 * size.height / 56,
      6.08281 * size.width / 68,
      25.3422 * size.height / 56,
    );
    path.cubicTo(
      4.92734 * size.width / 68,
      24.15 * size.height / 56,
      4.25 * size.width / 68,
      22.6406 * size.height / 56,
      4.25 * size.width / 68,
      21 * size.height / 56,
    );
    path.cubicTo(
      4.25 * size.width / 68,
      17.6422 * size.height / 56,
      7.11875 * size.width / 68,
      14.8422 * size.height / 56,
      10.9438 * size.width / 68,
      14.1531 * size.height / 56,
    );
    path.cubicTo(
      10.7312 * size.width / 68,
      13.5516 * size.height / 56,
      10.625 * size.width / 68,
      12.9062 * size.height / 56,
      10.625 * size.width / 68,
      12.25 * size.height / 56,
    );
    path.cubicTo(
      10.625 * size.width / 68,
      8.97969 * size.height / 56,
      13.3609 * size.width / 68,
      6.22344 * size.height / 56,
      17.0398 * size.width / 68,
      5.45781 * size.height / 56,
    );
    path.cubicTo(
      17.4383 * size.width / 68,
      2.39531 * size.height / 56,
      20.5992 * size.width / 68,
      0,
      24.4375 * size.width / 68,
      0,
    );
    path.moveTo(43.5625 * size.width / 68, 0);
    path.cubicTo(
      47.4008 * size.width / 68,
      0,
      50.5484 * size.width / 68,
      2.39531 * size.height / 56,
      50.9602 * size.width / 68,
      5.45781 * size.height / 56,
    );
    path.cubicTo(
      54.6523 * size.width / 68,
      6.22344 * size.height / 56,
      57.375 * size.width / 68,
      8.96875 * size.height / 56,
      57.375 * size.width / 68,
      12.25 * size.height / 56,
    );
    path.cubicTo(
      57.375 * size.width / 68,
      12.9062 * size.height / 56,
      57.2687 * size.width / 68,
      13.5516 * size.height / 56,
      57.0563 * size.width / 68,
      14.1531 * size.height / 56,
    );
    path.cubicTo(
      60.8813 * size.width / 68,
      14.8312 * size.height / 56,
      63.75 * size.width / 68,
      17.6422 * size.height / 56,
      63.75 * size.width / 68,
      21 * size.height / 56,
    );
    path.cubicTo(
      63.75 * size.width / 68,
      22.6406 * size.height / 56,
      63.0727 * size.width / 68,
      24.15 * size.height / 56,
      61.9172 * size.width / 68,
      25.3422 * size.height / 56,
    );
    path.cubicTo(
      65.5164 * size.width / 68,
      26.7422 * size.height / 56,
      68 * size.width / 68,
      29.7609 * size.height / 56,
      68 * size.width / 68,
      33.25 * size.height / 56,
    );
    path.cubicTo(
      68 * size.width / 68,
      36.9906 * size.height / 56,
      65.1578 * size.width / 68,
      40.1844 * size.height / 56,
      61.1469 * size.width / 68,
      41.4312 * size.height / 56,
    );
    path.cubicTo(
      61.4523 * size.width / 68,
      42.1531 * size.height / 56,
      61.625 * size.width / 68,
      42.9406 * size.height / 56,
      61.625 * size.width / 68,
      43.75 * size.height / 56,
    );
    path.cubicTo(
      61.625 * size.width / 68,
      47.6109 * size.height / 56,
      57.8133 * size.width / 68,
      50.75 * size.height / 56,
      53.125 * size.width / 68,
      50.75 * size.height / 56,
    );
    path.cubicTo(
      52.3812 * size.width / 68,
      50.75 * size.height / 56,
      51.6508 * size.width / 68,
      50.6734 * size.height / 56,
      50.9602 * size.width / 68,
      50.5203 * size.height / 56,
    );
    path.cubicTo(
      50.5617 * size.width / 68,
      53.6047 * size.height / 56,
      47.4008 * size.width / 68,
      56 * size.height / 56,
      43.5625 * size.width / 68,
      56 * size.height / 56,
    );
    path.cubicTo(
      39.4586 * size.width / 68,
      56 * size.height / 56,
      36.125 * size.width / 68,
      53.2547 * size.height / 56,
      36.125 * size.width / 68,
      49.875 * size.height / 56,
    );
    path.lineTo(36.125 * size.width / 68, 6.125 * size.height / 56);
    path.cubicTo(
      36.125 * size.width / 68,
      2.74531 * size.height / 56,
      39.4586 * size.width / 68,
      0,
      43.5625 * size.width / 68,
      0,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
