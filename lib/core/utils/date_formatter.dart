import 'package:intl/intl.dart';

/// French date formatting helpers. Uses inline French month/day names
/// instead of `DateFormat(..., 'fr_FR')` so the app doesn't need
/// `initializeDateFormatting` in main.
abstract final class DateFormatter {
  static const _moisShort = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static const _moisLong = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  static const _joursLong = [
    'lundi', 'mardi', 'mercredi', 'jeudi',
    'vendredi', 'samedi', 'dimanche',
  ];

  /// "Aujourd'hui", "Hier", "Il y a 3 jours", ...
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? 'Il y a 1 semaine' : 'Il y a $weeks semaines';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return months == 1 ? 'Il y a 1 mois' : 'Il y a $months mois';
    }
    final years = (diff.inDays / 365).floor();
    return years == 1 ? 'Il y a 1 an' : 'Il y a $years ans';
  }

  /// "1 mai 2026"
  static String short(DateTime date) =>
      '${date.day} ${_moisShort[date.month - 1]} ${date.year}';

  /// "mai 2026"
  static String monthYear(DateTime date) =>
      '${_moisLong[date.month - 1]} ${date.year}';

  /// "jeudi 19:00"
  /// `DateTime.weekday` is 1=Monday … 7=Sunday.
  static String dayTime(DateTime date) {
    final day = _joursLong[date.weekday - 1];
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$day $hh:$mm';
  }

  /// "04/04/2026"
  static String numeric(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);
}
