import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/features/chat/controllers/ai_chat_controller.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';
import 'package:chatrizz/services/ocr_service.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/core/constants/app_constants.dart';
import 'package:chatrizz/services/api_service.dart';
import 'package:chatrizz/widgets/common/banner_ad_widget.dart';
import 'package:chatrizz/services/overlay_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final ctrl = AiChatController(
          aiRepository: context.read<AiRepository>(),
          ocrService: context.read<OcrService>(),
          localDataSource: context.read<LocalDataSource>(),
          apiService: context.read<ApiService>(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadOverlayScreenshot(context, ctrl);
          context.read<OverlayService>().deductPendingCredits();
        });
        return ctrl;
      },
      child: Consumer2<AiChatController, OverlayService>(
        builder: (context, ctrl, overlay, _) {
          if (overlay.lastScreenshotPath != null && !ctrl.isProcessing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadOverlayScreenshot(context, ctrl);
            });
          }
          return _buildScaffold(context, ctrl);
        },
      ),
    );
  }

  void _loadOverlayScreenshot(BuildContext context, AiChatController ctrl) {
    final overlay = context.read<OverlayService>();
    final path = overlay.lastScreenshotPath;
    if (path == null || path.isEmpty || ctrl.isProcessing) return;
    overlay.clearScreenshot();
    ctrl.loadScreenshotFromPath(path);
  }

  Widget _buildScaffold(BuildContext context, AiChatController ctrl) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Get conversation ideas from a screenshot',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildScreenshotSection(context, ctrl),
            if (ctrl.isProcessing)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (ctrl.extractedText != null) ...[
              const SizedBox(height: 16),
              _buildTypeAndStylePickers(context, ctrl),
              const SizedBox(height: 16),
              _buildTextPreview(ctrl),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: ctrl.isGenerating ? null : () => ctrl.generateIdeas(),
                icon: ctrl.isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(ctrl.isGenerating ? 'Generating...' : 'Get Ideas'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
            if (ctrl.needsCredits) ...[
              const SizedBox(height: 16),
              _buildCreditsDialog(context, ctrl),
            ],
            if (ctrl.error != null) ...[
              const SizedBox(height: 12),
              Text(ctrl.error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (ctrl.aiResult != null) ...[
              const SizedBox(height: 16),
              _buildResult(ctrl),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildTypeAndStylePickers(BuildContext context, AiChatController ctrl) {
    final types = [
      'Corporate (Boss)',
      'Colleague',
      'Stranger (Relationship)',
      'Family Member',
      'Partner/Girlfriend',
      'Normal Friend',
    ];

    final styles = ctrl.categories;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                context,
                label: 'Chatting with...',
                value: ctrl.conversationType,
                options: types,
                onChanged: (val) {
                  if (val != null) ctrl.setConversationType(val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                context,
                label: 'Desired Style...',
                value: ctrl.responseStyle,
                options: styles,
                onChanged: (val) {
                  if (val != null) ctrl.setResponseStyle(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context,
      {required String label, required String value, required List<String> options,
      required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceCard,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget _buildScreenshotSection(BuildContext context, AiChatController ctrl) {
    return GestureDetector(
      onTap: () => ctrl.pickScreenshot(),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ctrl.screenshot != null ? AppColors.purple.withValues(alpha: 0.4) : AppColors.border,
            width: ctrl.screenshot != null ? 2 : 1,
          ),
        ),
        child: Center(
          child: ctrl.screenshot != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(ctrl.screenshot!, fit: BoxFit.contain),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => ctrl.clear(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text('Tap to select a screenshot',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Upload a chat screenshot for ideas',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextPreview(AiChatController ctrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_snippet, size: 16, color: AppColors.purpleLight),
              const SizedBox(width: 6),
              const Text('Extracted Text',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('${ctrl.extractedText!.length} chars',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(ctrl.extractedText!,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildResult(AiChatController ctrl) {
    final sections = _parseSections(ctrl.aiResult!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppColors.purpleLight),
              const SizedBox(width: 8),
              const Text('AI Suggestions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.purpleLight)),
              const Spacer(),
              Text('${ctrl.credits} credits left',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          ...sections.map((section) => _buildSection(section)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ctrl.clear(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Another'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purpleLight,
              side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  _Section _parseSection(String raw) {
    final headerMatch = RegExp(r'^===+\s*(.+?)\s*===+').firstMatch(raw.trim());
    if (headerMatch == null) {
      return _Section(title: null, body: raw.trim(), items: []);
    }
    final title = headerMatch.group(1)!;
    final body = raw.substring(headerMatch.end).trim();
    final items = body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => l.startsWith('- ') || l.startsWith('* ') ? l.substring(2) : l)
        .toList();
    return _Section(title: title, body: body, items: items);
  }

  List<_Section> _parseSections(String text) {
    final rawSections = text.split(RegExp(r'\n(?====)'));
    return rawSections.map((s) => _parseSection(s.trim())).where((s) => s.body.isNotEmpty).toList();
  }

  Widget _buildSection(_Section section) {
    final isSuggestions = section.title != null &&
        (section.title!.contains('Suggested Next Messages') ||
         section.title!.contains('Suggested Messages'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(section.title!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.purpleLight)),
          ),
        if (isSuggestions)
          ...section.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(item.trim(),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.trim()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.copy, size: 14, color: AppColors.purpleLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ))
        else
          SelectableText(section.body,
              style: const TextStyle(
                  color: AppColors.textPrimary, height: 1.6, fontSize: 14)),
      ],
    );
  }

  Widget _buildCreditsDialog(BuildContext context, AiChatController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, size: 32, color: AppColors.warning),
          const SizedBox(height: 8),
          const Text('Out of credits!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('You have ${ctrl.credits} credits left.',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text('Watch ads to earn ${AppConstants.creditTopUpAmount} credits.',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Section {
  final String? title;
  final String body;
  final List<String> items;
  _Section({required this.title, required this.body, required this.items});
}
