import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 17,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
}
