import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import './settings_screen.dart';

class LearnTrackPomodoro extends StatefulWidget {
  const LearnTrackPomodoro({Key? key}) : super(key: key);

  @override
  State<LearnTrackPomodoro> createState() => _LearnTrackPomodoroState();
}

class _LearnTrackPomodoroState extends State<LearnTrackPomodoro> {
  // Timer states
  bool _isRunning = false;
  int _minutes = 25;
  int _seconds = 0;
  Timer? _timer;
  String _currentMode = "Work";

  // Pomodoro session durations (in minutes)
  final Map<String, int> _durations = {
    "Work": 25,
    "Short Break": 5,
    "Long Break": 10,
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          } else {
            _timer?.cancel();
            _isRunning = false;
            // Here you would add code to play a sound or notification
          }
        }
      });
    });

    setState(() {
      _isRunning = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _minutes = _durations[_currentMode]!;
      _seconds = 0;
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Color _timerColor(AppColorsExt colors) {
    final percent = _getProgressValue();
    if (percent > 0.75) return colors.accentGradientStart;
    if (percent > 0.5) return colors.accent;
    if (percent > 0.25) return const Color(0xFFF5A623);
    return colors.error;
  }

  void _changeMode(String mode) {
    _timer?.cancel();
    setState(() {
      _currentMode = mode;
      _minutes = _durations[mode]!;
      _seconds = 0;
      _isRunning = false;
    });
  }

  double _getProgressValue() {
    int totalSeconds = 0;
    int remainingSeconds = (_minutes * 60) + _seconds;

    if (_currentMode == "Work") {
      totalSeconds = _durations["Work"]! * 60;
    } else if (_currentMode == "Short Break") {
      totalSeconds = _durations["Short Break"]! * 60;
    } else {
      totalSeconds = _durations["Long Break"]! * 60;
    }

    return remainingSeconds / totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final timerColor = _timerColor(colors);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Focus Timer',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selection buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeButton("Work", _currentMode == "Work", colors),
                _buildModeButton(
                    "Short Break", _currentMode == "Short Break", colors),
                _buildModeButton(
                    "Long Break", _currentMode == "Long Break", colors),
              ],
            ),
          ),

          // Timer Display
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: _getProgressValue(),
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                      strokeWidth: 12,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentMode,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Timer Controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors.accentGradientStart,
                        colors.accentGradientEnd,
                      ],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isRunning ? _stopTimer : _startTimer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentSurface,
                    border: Border.all(color: colors.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _resetTimer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.refresh,
                          size: 28,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Help text
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Text(
                "Focus on your work for a set time, then take a short break. Repeat as needed.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, bool isActive, AppColorsExt colors) {
    return ElevatedButton(
      onPressed: () => _changeMode(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? colors.accent : colors.accentSurface,
        foregroundColor: isActive ? Colors.white : colors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        mode,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
