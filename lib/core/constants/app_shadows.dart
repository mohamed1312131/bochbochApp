import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const xs = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const sm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const xl = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  // Dark mode → no shadows, use borders instead
  static const none = <BoxShadow>[];
}