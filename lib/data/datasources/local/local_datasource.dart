import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chatrizz/data/models/match_model.dart';
import 'package:chatrizz/data/models/message_model.dart';
import 'package:chatrizz/data/models/memory_model.dart';
import 'package:chatrizz/data/models/user_model.dart';

class LocalDataSource {
  static const String _boxName = 'chatrizz_store';
  static const String _matchesKey = 'chatrizz_matches';
  static const String _messagesPrefix = 'chatrizz_messages_';
  static const String _memoriesPrefix = 'chatrizz_memories_';
  static const String _userKey = 'chatrizz_user';
  static const String _themeModeKey = 'chatrizz_theme_mode';
  static const String userKey = 'chatrizz_user';

  late Box<String> _box;
  final ValueNotifier<Set<String>> _changeNotifier = ValueNotifier({});

  ValueNotifier<Set<String>> get changeNotifier => _changeNotifier;

  void _notify(String key) {
    final updated = Set<String>.from(_changeNotifier.value);
    updated.add(key);
    _changeNotifier.value = updated;
  }

  void _set(String key, String value) {
    _box.put(key, value);
    _notify(key);
  }

  String? _get(String key) => _box.get(key);

  void _delete(String key) {
    _box.delete(key);
    _notify(key);
  }

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  List<MatchModel> getMatches() {
    final data = _get(_matchesKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMatches(List<MatchModel> matches) async {
    final data = jsonEncode(matches.map((m) => m.toJson()).toList());
    _set(_matchesKey, data);
  }

  MatchModel? getMatchById(String id) {
    final matches = getMatches();
    try {
      return matches.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMatch(MatchModel match) async {
    final matches = getMatches();
    matches.add(match);
    await saveMatches(matches);
  }

  Future<void> updateMatch(MatchModel match) async {
    final matches = getMatches();
    final index = matches.indexWhere((m) => m.id == match.id);
    if (index != -1) {
      matches[index] = match;
      await saveMatches(matches);
    }
  }

  Future<void> deleteMatch(String id) async {
    final matches = getMatches();
    matches.removeWhere((m) => m.id == id);
    await saveMatches(matches);
    _delete('$_messagesPrefix$id');
    _delete('$_memoriesPrefix$id');
  }

  List<MessageModel> getMessages(String matchId) {
    final data = _get('$_messagesPrefix$matchId');
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMessages(String matchId, List<MessageModel> messages) async {
    final data = jsonEncode(messages.map((m) => m.toJson()).toList());
    _set('$_messagesPrefix$matchId', data);
  }

  Future<void> deleteMessage(String matchId, String messageId) async {
    final messages = getMessages(matchId);
    messages.removeWhere((m) => m.id == messageId);
    await saveMessages(matchId, messages);
  }

  Future<void> addMessage(MessageModel message) async {
    final messages = getMessages(message.matchId);
    messages.add(message);
    await saveMessages(message.matchId, messages);
  }

  Future<void> updateMessage(MessageModel message) async {
    final messages = getMessages(message.matchId);
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = message;
      await saveMessages(message.matchId, messages);
    }
  }

  List<MemoryModel> getMemories(String matchId) {
    final data = _get('$_memoriesPrefix$matchId');
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => MemoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMemories(String matchId, List<MemoryModel> memories) async {
    final data = jsonEncode(memories.map((m) => m.toJson()).toList());
    _set('$_memoriesPrefix$matchId', data);
  }

  Future<void> addMemory(MemoryModel memory) async {
    final memories = getMemories(memory.matchId);
    memories.add(memory);
    await saveMemories(memory.matchId, memories);
  }

  Future<void> deleteMemory(String matchId, String memoryId) async {
    final memories = getMemories(matchId);
    memories.removeWhere((m) => m.id == memoryId);
    await saveMemories(matchId, memories);
  }

  Future<void> deleteMemoriesForMatch(String matchId) async {
    _delete('$_memoriesPrefix$matchId');
  }

  UserModel? getUser() {
    final data = _get(_userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> saveUser(UserModel user) async {
    _set(_userKey, jsonEncode(user.toJson()));
  }

  String? getThemeMode() => _get(_themeModeKey);

  Future<void> saveThemeMode(String themeMode) async {
    _set(_themeModeKey, themeMode);
  }
}
