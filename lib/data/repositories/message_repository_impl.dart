import 'dart:async';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/data/models/message_model.dart';
import 'package:chatrizz/domain/entities/message.dart';
import 'package:chatrizz/domain/repositories/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  final LocalDataSource _localDataSource;
  final StreamController<List<MessageEntity>> _controller = StreamController<List<MessageEntity>>.broadcast();
  String? _currentMatchId;

  MessageRepositoryImpl(this._localDataSource) {
    _localDataSource.changeNotifier.addListener(_onDataChange);
  }

  void _onDataChange() {
    if (_currentMatchId != null) {
      _controller.add(_getMessagesSync(_currentMatchId!));
    }
  }

  List<MessageEntity> _getMessagesSync(String matchId) {
    return _localDataSource.getMessages(matchId)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Stream<List<MessageEntity>> getMessages(String matchId) async* {
    _currentMatchId = matchId;
    yield _getMessagesSync(matchId);
    yield* _controller.stream;
  }

  @override
  Future<void> addMessage(MessageEntity message) async {
    await _localDataSource.addMessage(MessageModel.fromEntity(message));
  }

  @override
  Future<List<MessageEntity>> getRecentMessages(String matchId, {int limit = 10}) async {
    final messages = _getMessagesSync(matchId);
    if (messages.length <= limit) return messages;
    return messages.sublist(messages.length - limit);
  }

  @override
  Future<void> deleteMessage(String matchId, String messageId) async {
    await _localDataSource.deleteMessage(matchId, messageId);
  }

  @override
  Future<void> updateMessage(MessageEntity message) async {
    await _localDataSource.updateMessage(MessageModel.fromEntity(message));
  }

  @override
  Future<void> deleteMessagesForMatch(String matchId) async {
    await _localDataSource.saveMessages(matchId, []);
  }

  void dispose() {
    _localDataSource.changeNotifier.removeListener(_onDataChange);
    _controller.close();
  }
}
