import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/learning_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/learn_track_home.dart';
import 'screens/learn_track_dash.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Root widget: wires up the three ChangeNotifier providers the whole app
// shares (auth session, learning data, theme mode) and feeds ThemeProvider's
// current mode straight into MaterialApp so switching themes in Settings
// re-themes every screen at once - no per-screen listening required.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ProxyProvider (not a plain provider) because LearningProvider needs
        // to react to AuthProvider changes: log in -> fetch this user's
        // courses/paths/streak, log out -> clear them. This is the wiring
        // that makes that automatic instead of every screen doing it manually.
        ChangeNotifierProxyProvider<AuthProvider, LearningProvider>(
          create: (_) => LearningProvider(),
          update: (_, authProvider, learningProvider) {
            learningProvider!.setAuthProvider(authProvider);
            return learningProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          return MaterialApp(
            title: 'LearnTrack',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const AuthenticationWrapper(),
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Delay to allow the auth provider to initialize
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500)); // Brief delay
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!_initialized) {
      // Show a loading indicator while initializing
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if user is authenticated
    if (authProvider.isAuthenticated) {
      return const LearnTrackDash();
    } else {
      return const LearnTrackPage();
    }
  }
}
