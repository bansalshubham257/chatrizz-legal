import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
