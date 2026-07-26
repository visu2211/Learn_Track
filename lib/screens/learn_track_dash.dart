import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/course_card.dart';
import '../widgets/action_button.dart';
import '../widgets/streak_overview.dart';
import '../widgets/search_bar.dart';
import '../theme/app_colors.dart';
import './learn_track_pomodoro.dart';
import './learn_track_home.dart';
import './learning_paths_screen.dart';
import './settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_provider.dart';

class LearnTrackDash extends StatelessWidget {
  const LearnTrackDash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.accentGradientStart,
                            colors.accentGradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: SvgPicture.string(
                        '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M8.625 0C10.0734 0 11.25 1.17656 11.25 2.625V21.375C11.25 22.8234 10.0734 24 8.625 24C7.27031 24 6.15469 22.9734 6.01406 21.6516C5.77031 21.7172 5.5125 21.75 5.25 21.75C3.59531 21.75 2.25 20.4047 2.25 18.75C2.25 18.4031 2.31094 18.0656 2.41875 17.7562C1.00312 17.2219 0 15.8531 0 14.25C0 12.7547 0.876562 11.4609 2.14687 10.8609C1.73906 10.35 1.5 9.70312 1.5 9C1.5 7.56094 2.5125 6.36094 3.8625 6.06562C3.7875 5.80781 3.75 5.53125 3.75 5.25C3.75 3.84844 4.71563 2.66719 6.01406 2.33906C6.15469 1.02656 7.27031 0 8.625 0ZM15.375 0C16.7297 0 17.8406 1.02656 17.9859 2.33906C19.2891 2.66719 20.25 3.84375 20.25 5.25C20.25 5.53125 20.2125 5.80781 20.1375 6.06562C21.4875 6.35625 22.5 7.56094 22.5 9C22.5 9.70312 22.2609 10.35 21.8531 10.8609C23.1234 11.4609 24 12.7547 24 14.25C24 15.8531 22.9969 17.2219 21.5812 17.7562C21.6891 18.0656 21.75 18.4031 21.75 18.75C21.75 20.4047 20.4047 21.75 18.75 21.75C18.4875 21.75 18.2297 21.7172 17.9859 21.6516C17.8453 22.9734 16.7297 24 15.375 24C13.9266 24 12.75 22.8234 12.75 21.375V2.625C12.75 1.17656 13.9266 0 15.375 0Z" fill="white"/>
                        </svg>''',
                        width: 22,
                        height: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LearnTrack',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.settings_outlined,
                          color: colors.textSecondary),
                      tooltip: 'Settings',
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
                const SizedBox(height: 24),

                // Welcome Section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final name = authProvider.fullName ?? 'Learner';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $name!',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ready to continue learning?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Search Bar
                const CustomSearchBar(),
                const SizedBox(height: 32),

                // Learning Section
                Text(
                  'Currently Learning . . .',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<LearningProvider>(
                  builder: (context, learningProvider, _) {
                    final courses = learningProvider.currentCourses;

                    if (courses.isEmpty) {
                      return Container(
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
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search,
                                size: 24,
                                color: colors.textTertiary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search for a topic to start learning',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: colors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: courses.map((course) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CourseCard(
                            title: course['title'] ?? 'Untitled Course',
                            details: course['details'] ?? 'No details',
                            progress: course['progress'] as double? ?? 0.0,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        icon: 'timer',
                        label: 'Pomodoro',
                        isActive: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LearnTrackPomodoro(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ActionButton(
                        icon: 'paths',
                        label: 'My Paths',
                        isActive: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LearningPathsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Streak Section
                const StreakOverview(),

                // Logout Button
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await Provider.of<AuthProvider>(context, listen: false)
                            .signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LearnTrackPage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
