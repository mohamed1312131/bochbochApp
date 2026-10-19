import 'package:intl/intl.dart';

abstract final class MillimesFormatter {
  // French thousands separator (NBSP) — `12_400_000 → "12 400 TND"`.
  static final NumberFormat _tndFormatter = NumberFormat('#,##0', 'fr_FR');

  // 85000 → "85 TND" · 12400000 → "12 400 TND"
  static String format(int millimes) {
    final tnd = (millimes / 1000).round();
    return '${_tndFormatter.format(tnd)} TND';
  }

  // 85000 → "85.000"
  static String formatRaw(int millimes) {
    final formatter = NumberFormat('#,##0.###', 'fr_TN');
    return formatter.format(millimes / 1000);
  }

  // 85 TND → 85000
  static int toMillimes(double tnd) => (tnd * 1000).round();

  // 85000 → 85.0
  static double toTnd(int millimes) => millimes / 1000;
}