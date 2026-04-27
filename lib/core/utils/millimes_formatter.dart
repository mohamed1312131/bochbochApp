import 'package:intl/intl.dart';

abstract final class MillimesFormatter {
  // 85000 → "85 TND"
  static String format(int millimes) {
    final tnd = (millimes / 1000).round();
    return '$tnd TND';
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