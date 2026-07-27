import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../providers/theme_provider.dart';
import '../services/learning_service.dart';
import '../theme/app_colors.dart';
import 'learning_paths_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 12),
          const _ThemeModeSelector(),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Gemini API Key'),
          const SizedBox(height: 12),
          const _ApiKeySection(),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Learning Path History'),
          const SizedBox(height: 12),
          const _PathHistoryList(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final options = [
      (ThemeMode.light, 'Light', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
      (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    ];

    return Container(
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
        children: [
          for (int i = 0; i < options.length; i++) ...[
            _ThemeModeTile(
              mode: options[i].$1,
              label: options[i].$2,
              icon: options[i].$3,
              selected: themeProvider.themeMode == options[i].$1,
              onTap: () => themeProvider.setThemeMode(options[i].$1),
            ),
            if (i != options.length - 1) Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeTile({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: colors.accent)
            else
              Icon(Icons.circle_outlined, size: 20, color: colors.border),
          ],
        ),
      ),
    );
  }
}

// Shows whether a Gemini API key is currently stored, and lets the user
// replace or remove it - e.g. after rotating a key that was accidentally
// shared, or to switch to a different Google Cloud project's key. Removing
// it just clears local storage; the next learning-path search will prompt
// for a new key the same way it does the very first time.
class _ApiKeySection extends StatefulWidget {
  const _ApiKeySection();

  @override
  State<_ApiKeySection> createState() => _ApiKeySectionState();
}

class _ApiKeySectionState extends State<_ApiKeySection> {
  final LearningService _learningService = LearningService();
  String? _maskedKey;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeyStatus();
  }

  Future<void> _loadKeyStatus() async {
    final key = await _learningService.getGeminiApiKey();
    if (!mounted) return;
    setState(() {
      _maskedKey = key == null ? null : _mask(key);
      _loading = false;
    });
  }

  String _mask(String key) {
    if (key.length <= 4) return '••••';
    return '••••••••${key.substring(key.length - 4)}';
  }

  Future<void> _showKeyDialog() async {
    final colors = context.colors;
    final controller = TextEditingController();

    final newKey = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            _maskedKey == null ? 'Set Gemini API Key' : 'Replace Gemini API Key',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your Gemini API key',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: colors.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: colors.accent),
              child: Text('Save',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (newKey != null && newKey.isNotEmpty) {
      await _learningService.setGeminiApiKey(newKey);
      await _loadKeyStatus();
    }
  }

  Future<void> _confirmReset() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Reset API key?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'Your saved Gemini API key will be removed from this device. '
            "You'll be asked for a new one the next time you generate a "
            'learning path.',
            style: GoogleFonts.poppins(fontSize: 14, color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Reset',
                style: GoogleFonts.poppins(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _learningService.clearGeminiApiKey();
      await _loadKeyStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
      child: _loading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _maskedKey == null
                          ? Icons.key_off_outlined
                          : Icons.vpn_key_outlined,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _maskedKey ?? 'No API key set',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showKeyDialog,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          foregroundColor: colors.accent,
                        ),
                        child: Text(_maskedKey == null ? 'Set Key' : 'Replace'),
                      ),
                    ),
                    if (_maskedKey != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _confirmReset,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.error),
                            foregroundColor: colors.error,
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

class _PathHistoryList extends StatelessWidget {
  const _PathHistoryList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, _) {
        final paths = learningProvider.learningPaths;

        if (paths.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
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
                  Icon(Icons.history, size: 32, color: colors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'No learning paths generated yet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show most recently generated first.
        final ordered = paths.reversed.toList();

        return Column(
          children: List.generate(ordered.length, (i) {
            final path = ordered[i];
            final originalIndex = paths.length - 1 - i;
            final modules = path['modules'] as List<dynamic>? ?? [];
            final hours = path['estimatedHours'] as int? ?? 0;
            final progress = (path['progress'] as num?)?.toDouble() ?? 0.0;
            final createdAt = _parseDate(path['createdAt'] as String?);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LearningPathsScreen(),
                    ),
                  );
                },
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
                        children: [
                          Expanded(
                            child: Text(
                              path['title'] ?? 'Untitled Path',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.accentSurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: colors.textTertiary),
                            tooltip: 'Delete path',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDelete(
                                context, originalIndex, path),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        createdAt != null
                            ? _formatDate(createdAt)
                            : 'Date unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 14, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$hours hours',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.bookmark_border,
                              size: 14, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${modules.length} modules',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, int index, Map<String, dynamic> path) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Delete this path?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            '"${path['title'] ?? 'Untitled Path'}" and its progress will be permanently removed.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Provider.of<LearningProvider>(context, listen: false)
                    .deletePath(index);
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
