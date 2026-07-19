import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:chatrizz/domain/entities/match.dart';
import 'package:chatrizz/domain/entities/message.dart';
import 'package:chatrizz/domain/entities/memory.dart';
import 'package:chatrizz/domain/repositories/match_repository.dart';
import 'package:chatrizz/domain/repositories/message_repository.dart';
import 'package:chatrizz/domain/repositories/memory_repository.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/services/api_service.dart';
import 'package:chatrizz/core/constants/app_constants.dart';

class MatchDetailController extends ChangeNotifier {
  final MatchRepository _matchRepository;
  final MessageRepository _messageRepository;
  final MemoryRepository _memoryRepository;
  final AiRepository _aiRepository;
  final LocalDataSource _localDataSource;
  final AdService _adService;
  final ApiService _apiService;
  final String _matchId;
  static const _uuid = Uuid();

  MatchEntity? _match;
  List<MessageEntity> _messages = [];
  List<MemoryEntity> _memories = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _useFullHistory = true;
  AiReplyResponse? _replyOptions;
  String? _error;
  String? _userMotive;
  String? _progressAnalysis;
  bool _isAnalyzingProgress = false;

  bool _showIntentPicker = false;
  String? _pendingQuestion;
  bool _needsCredits = false;
  int _pendingAdRewards = 0;

  StreamSubscription? _matchSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _memorySub;
  StreamSubscription? _apiSub;

  MatchDetailController({
    required MatchRepository matchRepository,
    required MessageRepository messageRepository,
    required MemoryRepository memoryRepository,
    required AiRepository aiRepository,
    required LocalDataSource localDataSource,
    required AdService adService,
    required ApiService apiService,
    required String matchId,
  })  : _matchRepository = matchRepository,
        _messageRepository = messageRepository,
        _memoryRepository = memoryRepository,
        _aiRepository = aiRepository,
        _localDataSource = localDataSource,
        _adService = adService,
        _apiService = apiService,
        _matchId = matchId {
    _init();
  }

  MatchEntity? get match => _match;
  List<MessageEntity> get messages => _messages;
  AiReplyResponse? get replyOptions => _replyOptions;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get useFullHistory => _useFullHistory;
  String? get error => _error;
  bool get showIntentPicker => _showIntentPicker;
  String? get pendingQuestion => _pendingQuestion;
  bool get needsCredits => _needsCredits;
  int get credits => _apiService.credits;
  int get pendingAdRewards => _pendingAdRewards;
  String? get userMotive => _userMotive;
  String? get progressAnalysis => _progressAnalysis;
  bool get isAnalyzingProgress => _isAnalyzingProgress;

  void setMotive(String? motive) {
    _userMotive = motive;
    notifyListeners();
  }

  void _init() {
    _apiSub = _apiService.addListener(_onCreditsChanged);
    _matchSub = _matchRepository.getMatches().listen((matches) {
      try {
        _match = matches.firstWhere((m) => m.id == _matchId);
        notifyListeners();
      } catch (_) {}
    });

    _messageSub = _messageRepository.getMessages(_matchId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });

    _memorySub = _memoryRepository.getMemories(_matchId).listen((mems) {
      _memories = mems;
      _isLoading = false;
      notifyListeners();
    });
  }

  static const _intentKeywords = [
    'want to meet', 'wanna meet',
    'come over', 'my place',
    'grab drinks', 'grab a drink', 'get drinks', 'get a drink',
    'go on a date', 'date night',
    'hotel', 'hook up', 'netflix',
    'pick you up', 'take you out', 'treat you',
    'call me', 'text me', 'hit me up',
  ];

  static const _implicitSuggestions = [
    'let\'s meet', 'lets meet', 'let us meet',
    'we should meet', 'we could meet',
    'how about we', 'what about meeting',
  ];

  bool _hasDirectIntentKeywords(String text) {
    final lower = text.toLowerCase().trim();
    return _intentKeywords.any((p) => lower.contains(p));
  }

  bool _hasQuestionMark(String text) {
    return text.trim().endsWith('?');
  }

  bool _hasImplicitSuggestion(String text) {
    final lower = text.toLowerCase().trim();
    return _implicitSuggestions.any((p) => lower.contains(p));
  }

  void setUseFullHistory(bool value) {
    _useFullHistory = value;
    notifyListeners();
  }

  Future<void> addMessage(String text, MessageSender sender) async {
    final message = MessageEntity(
      id: _uuid.v4(),
      matchId: _matchId,
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
    );
    await _messageRepository.addMessage(message);

    if (_match != null) {
      await _matchRepository.updateMatch(
        _match!.copyWith(
          lastMessage: text,
          lastActivityDate: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void cancelIntentPicker() {
    _showIntentPicker = false;
    _pendingQuestion = null;
    _error = null;
    notifyListeners();
  }

  Future<void> generateReplies() async {
    if (_match == null) return;

    final lastThemMsg = _messages.where(
      (m) => m.sender == MessageSender.them,
    );
    final lastThem = lastThemMsg.isNotEmpty ? lastThemMsg.last : null;

    if (lastThem == null) {
      await _generateWithIntent();
      return;
    }

    if (lastThem == null) {
      await _generateWithIntent();
      return;
    }
    
    final text = lastThem.text;
    
    // 1. Check for direct intent keywords (High priority)
    if (_hasDirectIntentKeywords(text)) {
      _showIntentPicker = true;
      _pendingQuestion = text;
      _replyOptions = null;
      _error = null;
      notifyListeners();
      return;
    }
    
    // 2. If the last message is a question, ALWAYS ask for user mood (Consent)
    if (_hasQuestionMark(text)) {
      _showIntentPicker = true;
      _pendingQuestion = text;
      _replyOptions = null;
      _error = null;
      notifyListeners();
      return;
    }

    if (_hasImplicitSuggestion(text)) {
      try {
        final isIntent = await _aiRepository.classifyMessageIntent(text);
        if (isIntent) {
          _showIntentPicker = true;
          _pendingQuestion = text;
          _replyOptions = null;
          _error = null;
          notifyListeners();
          return;
        }
      } catch (_) {
      }
    }
    
    await _generateWithIntent();
  }


  Future<void> _generateWithIntent({String? intent}) async {
    _isGenerating = true;
    _error = null;
    _replyOptions = null;
    _needsCredits = false;
    notifyListeners();

    // Check credits for free-tier users
    final user = _localDataSource.getUser();
    if (user != null && user.subscriptionTier == 'free' && _apiService.credits <= 0) {
      _needsCredits = true;
      _isGenerating = false;
      notifyListeners();
      return;
    }

    try {
      // Fetch fresh messages from repository to ensure latest data
      final freshMessages = await _messageRepository.getRecentMessages(_matchId, limit: 100);
      
      List<Map<String, String>> recentMessages;
      if (_useFullHistory) {
        recentMessages = freshMessages
            .map((m) => {
                  'sender': m.sender == MessageSender.me ? 'me' : 'them',
                  'text': m.text,
                })
            .toList();
      } else {
        // Only use the very last message
        if (freshMessages.isNotEmpty) {
          final lastMsg = freshMessages.last;
          recentMessages = [
            {
              'sender': lastMsg.sender == MessageSender.me ? 'me' : 'them',
              'text': lastMsg.text,
            }
          ];
        } else {
          recentMessages = [];
        }
      }

      final match = _match!;
      final summary =
          '${match.name}${match.age != null ? ', ${match.age}' : ''}';
      final stage = _messages.length < 5
          ? 'opening'
          : _messages.length < 15 ? 'getting-to-know' : 'deepening';

      final request = AiReplyRequest(
        matchSummary: summary,
        matchBio: match.bio ?? '',
        matchInterests: match.interests,
        memories: _memories,
        recentMessages: recentMessages,
        conversationStage: stage,
        userIntent: intent,
        userMotive: _userMotive,
        language: _localDataSource.getUser()?.language ?? 'English',
      );

      _replyOptions = await _aiRepository.generateReply(request);

      // Deduct credit via API
      if (user != null && user.subscriptionTier == 'free') {
        await _apiService.deductCredits(1);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void dismissReplyOptions() {
    _replyOptions = null;
    _error = null;
    _needsCredits = false;
    _pendingAdRewards = 0;
    notifyListeners();
  }

  Future<int> watchAdForCredits() async {
    final earned = await _adService.showRewardedAd();
    if (!earned) return 0;

    _pendingAdRewards++;
    if (_pendingAdRewards >= AppConstants.rewardedAdsForTopUp) {
      final ok = await _apiService.addCredits(AppConstants.creditTopUpAmount);
      if (ok) {
        await _apiService.refreshCredits();
      }
      _pendingAdRewards = 0;
      _needsCredits = false;
      notifyListeners();
      return AppConstants.creditTopUpAmount;
    }
    notifyListeners();
    return -_pendingAdRewards; // negative = still need more
  }

  Future<void> generateRepliesWithIntent(String intent) async {
    _showIntentPicker = false;
    _pendingQuestion = null;
    notifyListeners();
    await _generateWithIntent(intent: intent);
  }

  Future<void> useReply(int index) async {
    if (_replyOptions == null || index >= _replyOptions!.options.length) return;

    final text = _replyOptions!.options[index].text;
    await addMessage(text, MessageSender.me);
    _replyOptions = null;
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    await _messageRepository.deleteMessage(_matchId, messageId);
  }

  Future<void> toggleSender(String messageId) async {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    final newSender = msg.sender == MessageSender.me ? MessageSender.them : MessageSender.me;
    final updated = MessageEntity(
      id: msg.id,
      matchId: msg.matchId,
      text: msg.text,
      sender: newSender,
      timestamp: msg.timestamp,
    );
    await _messageRepository.updateMessage(updated);
  }

  Future<void> reorderMessage(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final msgs = List<MessageEntity>.from(_messages);
    final moved = msgs.removeAt(oldIndex);
    msgs.insert(newIndex, moved);

    // Reassign timestamps sequentially to match new order
    final base = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < msgs.length; i++) {
      final updated = MessageEntity(
        id: msgs[i].id,
        matchId: msgs[i].matchId,
        text: msgs[i].text,
        sender: msgs[i].sender,
        timestamp: DateTime.fromMillisecondsSinceEpoch(base + i),
      );
      await _messageRepository.updateMessage(updated);
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    final updated = MessageEntity(
      id: msg.id,
      matchId: msg.matchId,
      text: newText,
      sender: msg.sender,
      timestamp: msg.timestamp,
    );
    await _messageRepository.updateMessage(updated);
  }

  Future<void> analyzeProgress() async {
    if (_match == null) return;

    _isAnalyzingProgress = true;
    _error = null;
    notifyListeners();

    try {
      final freshMessages = await _messageRepository.getRecentMessages(_matchId, limit: 100);
      final recentMessages = freshMessages
          .map((m) => {
                'sender': m.sender == MessageSender.me ? 'me' : 'them',
                'text': m.text,
              })
          .toList();

      final match = _match!;
      final request = AiReplyRequest(
        matchSummary: '${match.name}${match.age != null ? ', ${match.age}' : ''}',
        matchBio: match.bio ?? '',
        matchInterests: match.interests,
        memories: _memories,
        recentMessages: recentMessages,
        conversationStage: _messages.length < 5 ? 'opening' : 'ongoing',
        userMotive: _userMotive,
      );

      _progressAnalysis = await _aiRepository.analyzeConversationProgress(request);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isAnalyzingProgress = false;
      notifyListeners();
    }
  }

  void clearProgressAnalysis() {
    _progressAnalysis = null;
    notifyListeners();
  }

  Future<ProfileAnalysis?> analyzeProfile() async {
    if (_match == null) return null;
    try {
      return await _aiRepository.analyzeProfile(
        _match!.bio ?? '',
        _match!.interests,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateMatchProfile(MatchEntity updated) async {
    await _matchRepository.updateMatch(updated);
  }

  void _onCreditsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    _messageSub?.cancel();
    _memorySub?.cancel();
    _apiSub?.cancel();
    super.dispose();
  }
}
