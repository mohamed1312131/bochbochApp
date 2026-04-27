import 'package:intl/intl.dart';

abstract final class DateFormatter {
  // "2 days ago", "Today", "Yesterday"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  // "Apr 4, 2026"
  static String short(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  // "April 2026"
  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  // "Thursday 7:00 PM"
  static String dayTime(DateTime date) =>
      DateFormat('EEEE h:mm a').format(date);

  // "04/04/2026"
  static String numeric(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);
}