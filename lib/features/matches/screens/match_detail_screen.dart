import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/core/utils/date_utils.dart';
import 'package:chatrizz/domain/entities/message.dart';
import 'package:chatrizz/features/matches/controllers/match_detail_controller.dart';
import 'package:chatrizz/domain/repositories/match_repository.dart';
import 'package:chatrizz/domain/repositories/message_repository.dart';
import 'package:chatrizz/domain/repositories/memory_repository.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';
import 'package:chatrizz/services/ocr_service.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/services/api_service.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/core/constants/app_constants.dart';
import 'package:chatrizz/features/settings/controllers/settings_controller.dart';
import 'package:chatrizz/widgets/common/banner_ad_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  MessageSender _selectedSender = MessageSender.me;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _importChatScreenshot(
      BuildContext context, MatchDetailController controller) async {
    final ocr = context.read<OcrService>();
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final result = await ocr.extractText(File(file.path));
    if (result.messages.isNotEmpty) {
      // Step 1: Identify if it's a group chat (more than 2 unique senders)
      final uniqueSenders = result.messages.map((m) => m.sender).toSet();
      final isGroupChat = uniqueSenders.length > 2;

      // Step 2: Ask for Conversation Type
      String selectedType = await _showConversationTypePicker(context);
      if (selectedType == 'Cancel') return;

      // Step 3: Ask for Response Style
      String selectedStyle = await _showStylePicker(context);
      if (selectedStyle == 'Cancel') return;

      // Step 4: Handle Group Chat Intent if applicable
      String? groupIntent;
      if (isGroupChat) {
        groupIntent = await _showGroupIntentPicker(context);
        if (groupIntent == 'Cancel') return;
      }

      // Step 5: Generate AI Ideas
      final aiRepo = context.read<AiRepository>();
      final language = context.read<SettingsController>().language;
      
      final ideas = await aiRepo.generateScreenshotIdeas(
        AiCoachRequest(
          screenshotText: result.messages.map((m) => '${m.sender}: ${m.text}').join('\n'),
          conversationType: selectedType,
          responseStyle: selectedStyle,
          groupChatIntent: groupIntent,
          userSide: 'right',
          language: language,
        ),
      );

      if (context.mounted) {
        _showAiCoachResult(context, ideas);
      }

      // Also import messages into the chat
      for (final msg in result.messages) {
        final sender = msg.sender == 'me' ? MessageSender.me : MessageSender.them;
        await controller.addMessage(msg.text, sender);
      }
      _scrollToBottom();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${result.messages.length} messages'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No messages detected in screenshot'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<String> _showConversationTypePicker(BuildContext context) async {
    final types = [
      'Corporate (Boss)',
      'Colleague',
      'Stranger (Relationship)',
      'Family Member',
      'Partner/Girlfriend',
      'Normal Friend',
    ];

    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Who are you chatting with?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: types.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                title: Text(types[index], style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, types[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'Cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ) ?? 'Cancel';
  }

  Future<String> _showStylePicker(BuildContext context) async {
    final user = context.read<LocalDataSource>().getUser();
    final styles = user?.categories ?? ['Funny', 'Flirty', 'Bold'];

    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('What style do you want?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: styles.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                title: Text(styles[index], style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, styles[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'Cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ) ?? 'Cancel';
  }

  Future<String?> _showGroupIntentPicker(BuildContext context) async {

    final intents = [
      'Follow the group trend (e.g. wish birthday)',
      'Be different/stand out',
      'Just a casual reply',
    ];

    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Group Chat Detected',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This looks like a group chat. How do you want to handle it?',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...intents.map((intent) => ListTile(
              title: Text(intent, style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, intent),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'Cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ) ?? 'Cancel';
  }

  void _showAiCoachResult(BuildContext context, String result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('AI Coach Suggestions',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SingleChildScrollView(
          child: Text(
            result,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showMotiveDialog(BuildContext context, MatchDetailController ctrl) {
    final motives = [
      'Casual',
      'One Night Stand',
      'Dinner Date',
      'Travel Partner',
      'Time Pass',
      'Serious Relationship',
      'Friendly Flirt',
      'Deep Connection',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Set Your Goal',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: motives.length,
            itemBuilder: (ctx, index) {
              final motive = motives[index];
              return ListTile(
                title: Text(motive, style: const TextStyle(color: AppColors.textPrimary)),
                trailing: ctrl.userMotive == motive
                    ? const Icon(Icons.check, color: AppColors.purpleLight)
                    : null,
                onTap: () {
                  ctrl.setMotive(motive);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisDialog(BuildContext context, MatchDetailController ctrl) async {
    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: ctrl,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('Conversation Analysis',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: Consumer<MatchDetailController>(
            builder: (context, controller, _) {
              if (controller.isAnalyzingProgress) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.error != null) {
                return Text(
                  'Error: ${controller.error}',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                );
              }
              if (controller.progressAnalysis == null) {
                return const Text(
                  'No analysis yet. Click Analyze to evaluate your progress.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                );
              }
              return Text(
                controller.progressAnalysis!,
                style: const TextStyle(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await ctrl.analyzeProgress();
              },
              child: const Text('Analyze', style: TextStyle(color: AppColors.purpleLight)),
            ),
          ],
        ),
      ),
    );
  }
  void _editMatchProfile(BuildContext context, MatchDetailController ctrl) {
    final match = ctrl.match;
    if (match == null) return;

    final nameCtrl = TextEditingController(text: match.name);
    final ageCtrl = TextEditingController(text: match.age?.toString() ?? '');
    final bioCtrl = TextEditingController(text: match.bio ?? '');
    final locationCtrl = TextEditingController(text: match.location ?? '');
    final interests = List<String>.from(match.interests);
    final interestCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('Edit Match Profile',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ageCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: interestCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Add interest',
                          labelStyle: TextStyle(color: AppColors.textTertiary),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.purpleLight),
                      onPressed: () {
                        final text = interestCtrl.text.trim();
                        if (text.isNotEmpty && !interests.contains(text)) {
                          setDialogState(() {
                            interests.add(text);
                            interestCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: interests.map((i) => Chip(
                      label: Text(i, style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.purpleSurface,
                      side: BorderSide.none,
                      onDeleted: () {
                        setDialogState(() => interests.remove(i));
                      },
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updated = match.copyWith(
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : match.name,
                  age: ageCtrl.text.trim().isNotEmpty ? int.tryParse(ageCtrl.text.trim()) : match.age,
                  bio: bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : match.bio,
                  location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : match.location,
                  interests: interests,
                );
                ctrl.updateMatchProfile(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: AppColors.purpleLight)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchDetailController(
        matchRepository: context.read<MatchRepository>(),
        messageRepository: context.read<MessageRepository>(),
        memoryRepository: context.read<MemoryRepository>(),
        aiRepository: context.read<AiRepository>(),
        localDataSource: context.read<LocalDataSource>(),
        adService: context.read<AdService>(),
        apiService: context.read<ApiService>(),
        matchId: widget.matchId,
      ),
      child: Consumer<MatchDetailController>(
        builder: (context, ctrl, _) => _buildScaffold(context, ctrl),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, MatchDetailController ctrl) {
    final match = ctrl.match;

    return Scaffold(
      appBar: AppBar(
        title: match != null
            ? Text(match.name, style: const TextStyle(fontWeight: FontWeight.w600))
            : null,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome),
            onSelected: (value) {
              if (value == 'goal') _showMotiveDialog(context, ctrl);
              if (value == 'analyze') _showAnalysisDialog(context, ctrl);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'goal',
                child: ListTile(
                  leading: Icon(Icons.flag, size: 18),
                  title: Text('Set Goal'),
                  dense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'analyze',
                child: ListTile(
                  leading: Icon(Icons.analytics, size: 18),
                  title: Text('Analyze Progress'),
                  dense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editMatchProfile(context, ctrl),
            tooltip: 'Edit profile',
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined),
            onPressed: () => _importChatScreenshot(context, ctrl),
            tooltip: 'Import chat screenshot',
          ),
        ],
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (match != null && (match.bio != null || match.interests.isNotEmpty))
                  _buildProfileStrip(match),
                Expanded(child: _buildChatArea(context, ctrl)),
                if (ctrl.showIntentPicker)
                  _buildIntentPicker(ctrl),
                if (ctrl.replyOptions != null)
                  _buildAiOptions(context, ctrl),
                if (ctrl.needsCredits)
                  _buildCreditsDialog(context, ctrl),
                _buildInputBar(ctrl),
              ],
            ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildProfileStrip(dynamic match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.purpleSurface,
                child: Text(
                  match.name.isNotEmpty ? match.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.purpleLight),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (match.location != null)
                      Text(match.location!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          if (match.interests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: match.interests.map<Widget>((i) {
                return Chip(
                  label: Text(i, style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.purpleSurface,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context, MatchDetailController ctrl) {
    if (ctrl.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              const Text('No messages yet',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Type a message below or import a\nchat screenshot to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      scrollController: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: ctrl.messages.length,
      buildDefaultDragHandles: true,
      onReorder: (oldIndex, newIndex) => ctrl.reorderMessage(oldIndex, newIndex),
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        color: Colors.transparent,
        shadowColor: AppColors.purple.withValues(alpha: 0.3),
        child: child,
      ),
      itemBuilder: (context, index) {
        final msg = ctrl.messages[index];
        final isMe = msg.sender == MessageSender.me;

        return GestureDetector(
          key: ValueKey(msg.id),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 200) {
              ctrl.toggleSender(msg.id);
            }
          },
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _MessageActions.editMessageStatic(context, ctrl, msg),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.purple : AppColors.surfaceCard,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                    bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                  ),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isMe ? 'You' : 'Them',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMe
                                ? AppColors.white.withValues(alpha: 0.7)
                                : AppColors.purpleLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.swap_horiz, size: 10,
                            color: isMe
                                ? AppColors.white.withValues(alpha: 0.3)
                                : AppColors.textTertiary),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.copy, size: 12,
                                color: isMe
                                    ? AppColors.white.withValues(alpha: 0.4)
                                    : AppColors.textTertiary),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ctrl.deleteMessage(msg.id),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close, size: 14,
                                color: isMe
                                    ? AppColors.white.withValues(alpha: 0.4)
                                    : AppColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(msg.text,
                        style: TextStyle(
                            color: isMe ? AppColors.white : AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.formatTime(msg.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? AppColors.white.withValues(alpha: 0.5)
                                : AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        _MessageActions(msg: msg, ctrl: ctrl),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiOptions(BuildContext context, MatchDetailController ctrl) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          ctrl.dismissReplyOptions();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.purpleLight),
              const SizedBox(width: 6),
              const Text('Suggested replies',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleLight)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ctrl.generateReplies(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => ctrl.dismissReplyOptions(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16,
                      color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ctrl.replyOptions!.options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: AppColors.purpleSurface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ctrl.useReply(i);
                    _scrollToBottom();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            opt.style.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.purpleLight,
                                letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(opt.text,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: opt.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.copy, size: 12, color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.send, size: 14, color: AppColors.purpleLight),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      ),
    );
  }

  Widget _buildIntentPicker(MatchDetailController ctrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 16, color: AppColors.purpleLight),
              const SizedBox(width: 6),
              const Text('They asked something...',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleLight)),
              const Spacer(),
              TextButton(
                onPressed: () => ctrl.cancelIntentPicker(),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('"${ctrl.pendingQuestion}"',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
                  Expanded(
                    child: _intentButton(ctrl, 'yes', 'Yes', Icons.thumb_up, AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _intentButton(ctrl, 'no', 'No', Icons.thumb_down, AppColors.error),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _intentButton(ctrl, 'not_sure', 'Not Sure', Icons.schedule, AppColors.warning),
                  ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsDialog(BuildContext context, MatchDetailController ctrl) {
    final remaining = AppConstants.rewardedAdsForTopUp - ctrl.pendingAdRewards;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 24, color: AppColors.purpleLight),
          const SizedBox(height: 8),
          const Text('Out of credits!',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('You have ${ctrl.credits} credits left.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Watch ${remaining > 1 ? "$remaining ads" : "1 ad"} to earn ${AppConstants.creditTopUpAmount} credits.',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => ctrl.dismissReplyOptions(),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await ctrl.watchAdForCredits();
                  if (result > 0 && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Earned $result credits!')),
                    );
                  } else if (result < 0 && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${-result}/${AppConstants.rewardedAdsForTopUp} ads watched')),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: Text(ctrl.pendingAdRewards > 0
                    ? 'Watch Ad (${ctrl.pendingAdRewards}/${AppConstants.rewardedAdsForTopUp})'
                    : 'Watch Ad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _intentButton(
      MatchDetailController ctrl, String intent, String label, IconData icon, Color color) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: ctrl.isGenerating
            ? null
            : () => ctrl.generateRepliesWithIntent(intent),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(MatchDetailController ctrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _senderToggle(),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _selectedSender == MessageSender.me
                          ? 'Type your message...'
                          : 'Type their message...',
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _sendMessage(ctrl),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.purple),
                  onPressed: () => _sendMessage(ctrl),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: ctrl.isGenerating ? null : () => ctrl.generateReplies(),
                icon: ctrl.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                    ctrl.isGenerating ? 'Generating...' : 'Generate AI replies',
                    style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purpleLight,
                  side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (ctrl.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ctrl.error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _senderToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedSender = _selectedSender == MessageSender.me
            ? MessageSender.them
            : MessageSender.me;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedSender == MessageSender.me
              ? AppColors.purple.withValues(alpha: 0.2)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedSender == MessageSender.me
                ? AppColors.purple.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedSender == MessageSender.me ? Icons.person : Icons.favorite,
              size: 14,
              color: _selectedSender == MessageSender.me
                  ? AppColors.purpleLight
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedSender == MessageSender.me ? 'Me' : 'Them',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedSender == MessageSender.me
                    ? AppColors.purpleLight
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(MatchDetailController ctrl) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ctrl.addMessage(text, _selectedSender);
    _textController.clear();
    _scrollToBottom();
  }
}

class _MessageActions extends StatelessWidget {
  final MessageEntity msg;
  final MatchDetailController ctrl;

  const _MessageActions({required this.msg, required this.ctrl});

  static void editMessageStatic(BuildContext context, MatchDetailController ctrl, MessageEntity msg) {
    final controller = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Edit message',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                ctrl.editMessage(msg.id, newText);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.purpleLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz, size: 16,
          color: msg.sender == MessageSender.me
              ? AppColors.white.withValues(alpha: 0.5)
              : AppColors.textTertiary),
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        switch (value) {
          case 'copy':
            Clipboard.setData(ClipboardData(text: msg.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
            );
          case 'edit':
            editMessageStatic(context, ctrl, msg);
          case 'delete':
            ctrl.deleteMessage(msg.id);
          case 'toggle':
            ctrl.toggleSender(msg.id);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'copy', child: ListTile(
          leading: Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
          title: Text('Copy', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          dense: true, contentPadding: EdgeInsets.zero,
        )),
        const PopupMenuItem(value: 'edit', child: ListTile(
          leading: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
          title: Text('Edit', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          dense: true, contentPadding: EdgeInsets.zero,
        )),
        const PopupMenuItem(value: 'toggle', child: ListTile(
          leading: Icon(Icons.swap_horiz, size: 18, color: AppColors.textSecondary),
          title: Text('Toggle sender', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          dense: true, contentPadding: EdgeInsets.zero,
        )),
        const PopupMenuItem(value: 'delete', child: ListTile(
          leading: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
          title: Text('Delete', style: TextStyle(fontSize: 14, color: AppColors.error)),
          dense: true, contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }
}
