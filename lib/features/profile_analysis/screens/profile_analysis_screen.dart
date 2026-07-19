import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';

class ProfileAnalysisScreen extends StatefulWidget {
  final String bio;
  final List<String> interests;

  const ProfileAnalysisScreen({
    super.key,
    required this.bio,
    required this.interests,
  });

  @override
  State<ProfileAnalysisScreen> createState() => _ProfileAnalysisScreenState();
}

class _ProfileAnalysisScreenState extends State<ProfileAnalysisScreen> {
  ProfileAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final aiRepo = context.read<AiRepository>();
      final analysis = await aiRepo.analyzeProfile(widget.bio, widget.interests);
      setState(() => _analysis = analysis);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Analysis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _analysis == null
                  ? const Center(child: Text('No analysis available'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Summary', _analysis!.summary, Icons.summarize),
          const SizedBox(height: 16),
          _buildListSection('Conversation Starters', _analysis!.conversationStarters, Icons.chat_bubble_outline),
          const SizedBox(height: 16),
          _buildListSection('Key Interests', _analysis!.highlightedInterests, Icons.interests_outlined),
          const SizedBox(height: 16),
          _buildListSection('Green Flags', _analysis!.greenFlags, Icons.flag_outlined),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.purpleLight),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.purpleLight),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text(
                'No items found',
                style: TextStyle(color: AppColors.textTertiary, fontStyle: FontStyle.italic),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(color: AppColors.purpleLight)),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
