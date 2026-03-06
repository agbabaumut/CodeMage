import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color tawnyOwl = Color(0xFFF1947B);
  static const Color greatHornedOwl = Color(0xFFED6F72);
  static const Color burrowingOwl = Color(0xFFEA4F6C);

  static const Color screechOwl = Color(0xFF994164);
  static const Color greatGreyOwl = Color(0xFF484C6D);
  static const Color elfOwl = Color(0xFF1F1D2F);

  static const Color bgPrimary = Color(0xFF12121A);
  static const Color bgSecondary = Color(0xFF1A1A24);
  static const Color bgElevated = Color(0xFF22222E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A8);
  static const Color textMuted = Color(0xFF6B6B75);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);

  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [burrowingOwl, greatHornedOwl],
  );

  static const LinearGradient gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greatHornedOwl, tawnyOwl],
  );

  static const LinearGradient gradientSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [screechOwl, greatGreyOwl],
  );
}
