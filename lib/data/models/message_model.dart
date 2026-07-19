import 'package:chatrizz/domain/entities/message.dart';

class MessageModel {
  final String id;
  final String matchId;
  final String text;
  final String sender;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.matchId,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      matchId: entity.matchId,
      text: entity.text,
      sender: entity.sender == MessageSender.me ? 'me' : 'them',
      timestamp: entity.timestamp,
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      matchId: matchId,
      text: text,
      sender: sender == 'me' ? MessageSender.me : MessageSender.them,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchId': matchId,
    'text': text,
    'sender': sender,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] as String,
    matchId: json['matchId'] as String,
    text: json['text'] as String,
    sender: json['sender'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
