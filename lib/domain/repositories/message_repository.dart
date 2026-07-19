import 'package:chatrizz/domain/entities/message.dart';

abstract class MessageRepository {
  Stream<List<MessageEntity>> getMessages(String matchId);
  Future<void> addMessage(MessageEntity message);
  Future<List<MessageEntity>> getRecentMessages(String matchId, {int limit = 10});
  Future<void> updateMessage(MessageEntity message);
  Future<void> deleteMessage(String matchId, String messageId);
  Future<void> deleteMessagesForMatch(String matchId);
}
