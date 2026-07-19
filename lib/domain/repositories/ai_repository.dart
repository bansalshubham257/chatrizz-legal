import 'package:chatrizz/domain/entities/memory.dart';

class AiReplyRequest {
  final String matchSummary;
  final String matchBio;
  final List<String> matchInterests;
  final List<MemoryEntity> memories;
  final List<Map<String, String>> recentMessages;
  final String conversationStage;
  final String? userIntent;
  final String? userMotive;
  final String language;

  const AiReplyRequest({
    required this.matchSummary,
    required this.matchBio,
    required this.matchInterests,
    required this.memories,
    required this.recentMessages,
    required this.conversationStage,
    this.userIntent,
    this.userMotive,
    this.language = 'English',
  });
}

class AiCoachRequest {
  final String screenshotText;
  final String conversationType;
  final String? groupChatIntent;
  final String responseStyle;
  final String userSide;
  final String language;

  const AiCoachRequest({
    required this.screenshotText,
    required this.conversationType,
    this.groupChatIntent,
    required this.responseStyle,
    required this.userSide,
    this.language = 'English',
  });
}

class AiReplyOption {
  final String text;
  final String style;

  const AiReplyOption({required this.text, required this.style});
}

class AiReplyResponse {
  final List<AiReplyOption> options;

  const AiReplyResponse({required this.options});
}

class ProfileAnalysis {
  final String summary;
  final List<String> conversationStarters;
  final List<String> highlightedInterests;
  final List<String> greenFlags;

  const ProfileAnalysis({
    required this.summary,
    required this.conversationStarters,
    required this.highlightedInterests,
    required this.greenFlags,
  });
}

abstract class AiRepository {
  Future<AiReplyResponse> generateReply(AiReplyRequest request);
  Future<ProfileAnalysis> analyzeProfile(String bio, List<String> interests);
  Future<String> generateScreenshotIdeas(AiCoachRequest request);
  Future<String> generateMemorySummary(
    String matchBio,
    List<String> matchInterests,
    List<Map<String, String>> conversationHistory,
  );
  Future<bool> classifyMessageIntent(String text);
  Future<String> analyzeConversationProgress(AiReplyRequest request);
}
