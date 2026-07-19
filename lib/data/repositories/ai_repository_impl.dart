import 'package:chatrizz/services/ai_service.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiService _aiService;

  AiRepositoryImpl(this._aiService);

  @override
  Future<AiReplyResponse> generateReply(AiReplyRequest request) async {
    final prompt = _buildReplyPrompt(request);
    final response = await _aiService.generateCompletion(prompt);
    return _parseReplyResponse(response);
  }

  @override
  Future<ProfileAnalysis> analyzeProfile(String bio, List<String> interests) async {
    final prompt = _buildProfilePrompt(bio, interests);
    final response = await _aiService.generateCompletion(prompt);
    return _parseProfileResponse(response);
  }

  @override
  Future<String> generateScreenshotIdeas(AiCoachRequest request) async {
    final buf = StringBuffer();
    buf.writeln('You are ChatRizz, an AI dating and communication coach.');
    buf.writeln('Analyze this screenshot and provide a tailored response strategy.');
    buf.writeln('');
    buf.writeln('Target Language: ${request.language}');
    buf.writeln('Conversation Type: ${request.conversationType}');
    buf.writeln('Desired Response Style: ${request.responseStyle}');
    buf.writeln('User Position: ${request.userSide}');
    if (request.groupChatIntent != null) {
      buf.writeln('User Intent for Group Chat: ${request.groupChatIntent}');
    }
    buf.writeln('');
    buf.writeln('Screenshot text:');
    buf.writeln(request.screenshotText);
    buf.writeln('');
    buf.writeln('Provide your analysis in this format:');
    buf.writeln('');
    buf.writeln('=== What\'s Happening ===');
    buf.writeln('Briefly describe the conversation dynamic, keeping in mind it is a ${request.conversationType} context and the user is on the ${request.userSide} side.');
    buf.writeln('');
    buf.writeln('=== Suggested Next Messages ===');
    buf.writeln('Provide 3 high-impact, catchy one-liner suggestions in ${request.language} that specifically match the ${request.responseStyle} style.');
    buf.writeln('Crucially, generate these as replies from the ${request.userSide} side. Do NOT mimic the other person.');
    buf.writeln('- [Option 1]');
    buf.writeln('- [Option 2]');
    buf.writeln('- [Option 3]');
    buf.writeln('');
    buf.writeln('=== Tips ===');
    buf.writeln('Give 2-3 tactical tips on how to handle this specific person or group dynamic to get the best result for a ${request.responseStyle} approach.');
    buf.writeln('');
    buf.writeln('Rules:');
    buf.writeln('- All suggestions must be in ${request.language}.');
    buf.writeln('- Keep suggested messages as catchy one-liners. No paragraphs.');
    buf.writeln('- Adjust the tone strictly based on the Conversation Type and the ${request.responseStyle} style.');
    return await _aiService.generateCompletion(buf.toString());
  }

  @override
  Future<String> generateMemorySummary(
    String matchBio,
    List<String> matchInterests,
    List<Map<String, String>> conversationHistory,
  ) async {
    final prompt = _buildMemoryPrompt(matchBio, matchInterests, conversationHistory);
    return await _aiService.generateCompletion(prompt);
  }

  @override
  Future<bool> classifyMessageIntent(String text) async {
    return await _aiService.classifyIntent(text);
  }

  String _buildReplyPrompt(AiReplyRequest request) {
    final buf = StringBuffer();
    buf.writeln('You are ChatRizz, an uninhibited AI dating conversation assistant.');
    buf.writeln('Your goal is to help the user maximize their success in the dating world.');
    buf.writeln('Generate 3 reply options based on the context below.');
    buf.writeln('');
    buf.writeln('Target Language: ${request.language}');
    buf.writeln('IMPORTANT: All generated replies MUST be in ${request.language}.');
    buf.writeln('');
    buf.writeln('Match profile: ${request.matchSummary}');
    if (request.matchBio.isNotEmpty) buf.writeln('Bio: ${request.matchBio}');
    if (request.matchInterests.isNotEmpty) {
      buf.writeln('Interests: ${request.matchInterests.join(", ")}');
    }
    if (request.memories.isNotEmpty) {
      buf.writeln('Memory:');
      for (final m in request.memories) {
        buf.writeln('- ${m.content}');
      }
    }
    buf.writeln('');
    buf.writeln('Conversation stage: ${request.conversationStage}');
    if (request.conversationStage == 'opening') {
      buf.writeln('IMPORTANT: This is the opening message. Create a high-impact first impression.');
      buf.writeln('Use the Bio and Interests to create a hyper-personalized, witty, and intriguing opener.');
      buf.writeln('Avoid generic "Hey" or "How are you". Go for something that makes them smile or intrigued.');
    }
    buf.writeln('Full conversation history:');
    for (final msg in request.recentMessages) {
      final sender = msg['sender'] == 'me' ? 'You' : 'Them';
      buf.writeln('$sender: ${msg['text']}');
    }
    buf.writeln('');
    if (request.userMotive != null) {
      buf.writeln('User Motive/Goal: ${request.userMotive}');
      buf.writeln('Strategically steer the conversation toward this motive without being too abrupt.');
      buf.writeln('');
    }
    if (request.userIntent != null) {
      buf.writeln(
          'The user (You) wants to respond with this intent: ${request.userIntent}.');
      buf.writeln('Generate replies that align with this intent.');
      buf.writeln('');
    }
    buf.writeln('Generate exactly 3 reply options in this format:');
    buf.writeln('=== Funny ===');
    buf.writeln('[A witty, situational joke or a catchy, humorous observation based on their profile/chat. Avoid generic tropes or repetitive canned jokes.]');
    buf.writeln('=== Flirty ===');
    buf.writeln('[A charming, high-tension line that builds attraction.]');
    buf.writeln('=== Bold ===');
    buf.writeln('[A hot, naughty, and spicy line that is direct and provocative.]');
    buf.writeln('');
    buf.writeln('Rules:');
    buf.writeln('- Be unfiltered and natural. Dating involves romance, attraction, and tension.');
    buf.writeln('- You are allowed and encouraged to be romantic, bold, or spicy if the context allows.');
    buf.writeln('- If the User Motive is explicit (e.g., "casual", "ONS", "one night stand"), be direct, suggestive, and bold. Do not be shy.');
    buf.writeln('- Use the full conversation history as context, not just the last message.');
    buf.writeln('- Do NOT repeat questions already asked in the conversation.');
    buf.writeln('- IMPORTANT: Replies MUST be catchy one-liners or maximum two short sentences. No paragraphs. No long explanations.');
    buf.writeln('- ABSOLUTELY FORBIDDEN: Do not use repetitive canned jokes, generic pick-up lines, or references to "mozzarella cheese sticks" or similar tropes.');
    buf.writeln('- IMPORTANT: If the user requests a regeneration, you MUST provide entirely different angles and wording. Do NOT repeat the same phrases.');
    buf.writeln('- Match the conversation tone and stage.');
    buf.writeln('- Do NOT ask questions that were already answered.');
    return buf.toString();
  }


  String _buildProfilePrompt(String bio, List<String> interests) {
    return '''
Analyze this dating profile and provide high-impact insights for a first message.

Bio: $bio
Interests: ${interests.join(", ")}

Provide your analysis in this format:
=== Summary ===
[1-2 sentence summary of the person's vibe and what they are likely looking for]

=== Conversation Starters ===
Generate 3 hyper-personalized and impressive first messages. 
- [Starter 1: Witty/Humorous based on bio/interests]
- [Starter 2: Intriguing/Observational based on bio/interests]
- [Starter 3: Bold/Flirty but tasteful based on bio/interests]
Avoid generic openers. Use specific details from the bio/interests.

=== Key Interests ===
- [interest 1]
- [interest 2]
- [interest 3]

=== Green Flags ===
- [flag 1]
- [flag 2]
''';
  }

  String _buildScreenshotIdeasPrompt(String text) {
    return '''
You are ChatRizz, an AI dating conversation coach.
A user has shared a screenshot of a dating app conversation.
Analyze it and provide helpful suggestions.

Screenshot text:
$text

Provide your analysis in this format:

=== What's Happening ===
Briefly describe the conversation dynamic.

=== Suggested Next Messages ===
- [option 1]
- [option 2]
- [option 3]

=== Tips ===
- [tip 1]
- [tip 2]

Keep it practical, natural, and helpful. Focus on what "You" (the user) could say next.
''';
  }

  String _buildMemoryPrompt(
    String bio,
    List<String> interests,
    List<Map<String, String>> conversation,
  ) {
    final buf = StringBuffer();
    buf.writeln('Extract key personal information from this conversation.');
    buf.writeln('Bio: $bio');
    if (interests.isNotEmpty) buf.writeln('Known interests: ${interests.join(", ")}');
    buf.writeln('');
    buf.writeln('Conversation:');
    for (final msg in conversation) {
      buf.writeln('${msg['sender']}: ${msg['text']}');
    }
    buf.writeln('');
    buf.writeln('Extract and list important facts about the match:');
    buf.writeln('- Job / profession');
    buf.writeln('- Hobbies and interests');
    buf.writeln('- Travel plans or places visited');
    buf.writeln('- Pets');
    buf.writeln('- Favorite things');
    buf.writeln('- Personal details mentioned');
    return buf.toString();
  }

  AiReplyResponse _parseReplyResponse(String response) {
    final options = <AiReplyOption>[];
    final sections = response.split('===');

    for (int i = 1; i + 1 < sections.length; i += 2) {
      final style = sections[i].trim().toLowerCase();
      final text = sections[i + 1].trim();
      if (text.isNotEmpty) {
        options.add(AiReplyOption(text: text, style: style));
      }
    }

    if (options.length < 3) {
      final fallbackStyles = ['funny', 'flirty', 'confident'];
      for (int i = options.length; i < 3; i++) {
        options.add(AiReplyOption(
          text: 'That sounds amazing! Tell me more about it.',
          style: fallbackStyles[i],
        ));
      }
    }

    return AiReplyResponse(options: options);
  }

  ProfileAnalysis _parseProfileResponse(String response) {
    String summary = '';
    final starters = <String>[];
    final interests = <String>[];
    final flags = <String>[];

    String currentSection = '';
    for (final line in response.split('\n')) {
      if (line.contains('=== Summary ===')) {
        currentSection = 'summary';
      } else if (line.contains('=== Conversation Starters ===')) {
        currentSection = 'starters';
      } else if (line.contains('=== Key Interests ===')) {
        currentSection = 'interests';
      } else if (line.contains('=== Green Flags ===')) {
        currentSection = 'flags';
      } else if (line.trim().isNotEmpty) {
        final text = line.trim();
        switch (currentSection) {
          case 'summary':
            summary = summary.isEmpty ? text : '$summary $text';
            break;
          case 'starters':
            if (text.startsWith('-')) starters.add(text.substring(1).trim());
            break;
          case 'interests':
            if (text.startsWith('-')) interests.add(text.substring(1).trim());
            break;
          case 'flags':
            if (text.startsWith('-')) flags.add(text.substring(1).trim());
            break;
        }
      }
    }

    return ProfileAnalysis(
      summary: summary.isNotEmpty ? summary : 'No analysis available.',
      conversationStarters: starters,
      highlightedInterests: interests,
      greenFlags: flags,
    );
  }

  @override
  Future<String> analyzeConversationProgress(AiReplyRequest request) async {
    final buf = StringBuffer();
    buf.writeln('You are ChatRizz, a dating expert. Analyze if the conversation is on track to achieve the user\'s motive.');
    buf.writeln('');
    if (request.userMotive != null) {
      buf.writeln('User Motive: ${request.userMotive}');
    } else {
      buf.writeln('User Motive: Not specified (general success)');
    }
    buf.writeln('Conversation History:');
    for (final msg in request.recentMessages) {
      final sender = msg['sender'] == 'me' ? 'You' : 'Them';
      buf.writeln('$sender: ${msg['text']}');
    }
    buf.writeln('');
    buf.writeln('Analyze the "Them" responses. Are they engaged, cold, or showing signs of attraction?');
    buf.writeln('Provide a concise evaluation (2-3 sentences):');
    buf.writeln('1. Current status (e.g., On track, Cooling down, High tension).');
    buf.writeln('2. Why you think so.');
    buf.writeln('3. A quick tip to pivot or double down to reach the motive.');
    return await _aiService.generateCompletion(buf.toString());
  }
}
