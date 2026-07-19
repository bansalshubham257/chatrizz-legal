enum MessageSender { me, them }

class MessageEntity {
  final String id;
  final String matchId;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  const MessageEntity({
    required this.id,
    required this.matchId,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}
