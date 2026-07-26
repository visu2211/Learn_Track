import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../screens/learning_paths_screen.dart';
import '../services/learning_service.dart';
import '../theme/app_colors.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({Key? key}) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _apiKeyError;
  final LearningService _learningService = LearningService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateLearningPath() async {
    if (_isLoading) return; // Ignore re-entrant submissions (e.g. double Enter).

    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _apiKeyError = null;
    });

    try {
      final options = await _learningService.checkAmbiguity(query);

      String topic = query;
      if (options.length > 1) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        if (!mounted) return;
        final choice = await _showDisambiguationDialog(query, options);
        if (choice == null) return; // User cancelled.
        topic = choice;
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
      }

      await _runGeneration(topic);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runGeneration(String topic) async {
    final learningProvider =
        Provider.of<LearningProvider>(context, listen: false);
    await learningProvider.generateLearningPath(topic);

    if (context.mounted) {
      _controller.clear();
      // Navigate to paths screen to show the new path
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LearningPathsScreen()),
      );
    }
  }

  void _handleError(Object e) {
    // Check if error is about missing API key
    if (e.toString().contains('API key not set')) {
      setState(() {
        _apiKeyError = 'Gemini API key not set. Please set it in settings.';
      });
      _showApiKeyDialog();
    } else {
      setState(() {
        _apiKeyError = 'Could not generate a learning path: ${e.toString()}';
      });
    }
  }

  Future<String?> _showDisambiguationDialog(
      String query, List<String> options) {
    final colors = context.colors;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Which "$query" did you mean?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This topic could refer to more than one subject. Pick one to generate a focused learning path.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(option),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.accentSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Set Gemini API Key',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To generate learning paths, LearnTrack needs a Gemini API key.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Go to console.cloud.google.com\n2. Enable Gemini API\n3. Create API Key\n4. Paste it below',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
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
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final apiKey = apiKeyController.text.trim();
                if (apiKey.isNotEmpty) {
                  await _learningService.setGeminiApiKey(apiKey);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    // Try again with the new key
                    _generateLearningPath();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.accentSurface,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'What would you like to learn?',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: colors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                errorText: _apiKeyError,
              ),
              onSubmitted: (_) => _generateLearningPath(),
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.accent,
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.arrow_forward,
                color: colors.accent,
              ),
              onPressed: _generateLearningPath,
            ),
        ],
      ),
    );
  }
}
