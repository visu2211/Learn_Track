import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'login_page_screen.dart';
import 'learn_track_dash.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 24, 9, 94),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        // Logo and App Name
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 68,
                            vertical: 13,
                          ),
                          child: Column(
                            children: [
                              CustomPaint(
                                painter: LogoPainter(),
                                size: const Size(68, 56),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                'LearnTrack',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Container
                        Container(
                          margin: const EdgeInsets.only(top: 32),
                          padding: const EdgeInsets.fromLTRB(25, 25, 25, 41),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: colors.surface,
                            border: Border.all(
                              color: colors.border,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                CustomTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  hintText: 'Enter your name',
                                  validator: _validateName,
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hintText: 'Enter your email',
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hintText: 'Create a password',
                                  isPassword: true,
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _ageController,
                                  label: 'Age',
                                  hintText: 'Enter your age',
                                  keyboardType: TextInputType.number,
                                  validator: _validateAge,
                                ),
                                const SizedBox(height: 16),

                                if (authProvider.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      authProvider.error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                // Create Account Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              try {
                                                // First check if server is reachable
                                                final serverConnected =
                                                    await authProvider
                                                        .checkServerConnection();
                                                if (!serverConnected) {
                                                  if (!mounted) return;

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Cannot connect to server. Please make sure the backend is running on port 8000.',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      duration:
                                                          Duration(seconds: 5),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                await authProvider.signUp(
                                                  _emailController.text.trim(),
                                                  _passwordController.text,
                                                  _nameController.text.trim(),
                                                  int.parse(
                                                      _ageController.text),
                                                );

                                                if (!mounted) return;

                                                if (authProvider.error ==
                                                    null) {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const LearnTrackDash(),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        authProvider.error!,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      duration: const Duration(
                                                          seconds: 5),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error: ${e.toString()}',
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(
                                                        seconds: 5),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ).copyWith(
                                      backgroundBuilder:
                                          (context, states, child) => Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colors.accentGradientStart,
                                              colors.accentGradientEnd,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: child,
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Create Account',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Sign In Link
                        Padding(
                          padding: const EdgeInsets.fromLTRB(64, 24, 64, 3),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
