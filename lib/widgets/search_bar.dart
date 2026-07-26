import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../screens/learning_paths_screen.dart';
import '../services/learning_service.dart';

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
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _apiKeyError = null;
    });

    try {
      final learningProvider =
          Provider.of<LearningProvider>(context, listen: false);
      await learningProvider.generateLearningPath(query);

      if (context.mounted) {
        _controller.clear();
        // Navigate to paths screen to show the new path
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LearningPathsScreen()),
        );
      }
    } catch (e) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Set Gemini API Key',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
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
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Go to console.cloud.google.com\n2. Enable Gemini API\n3. Create API Key\n4. Paste it below',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  hintText: 'Enter your Gemini API key',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFADAEBC),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                  color: const Color(0xFF6B7280),
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
                backgroundColor: const Color(0xFF4F46E5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: 'What would you like to learn?',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFFADAEBC),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                errorText: _apiKeyError,
              ),
              onSubmitted: (_) => _generateLearningPath(),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4F46E5),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.arrow_forward,
                color: Color(0xFF4F46E5),
              ),
              onPressed: _generateLearningPath,
            ),
        ],
      ),
    );
  }
}
