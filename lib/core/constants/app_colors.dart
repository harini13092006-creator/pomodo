import 'package:flutter/material.dart';

/// Application color constants adhering to the Forest & Minimalist productivity palette.
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF244B3B); // Deep Forest Green
  static const Color secondary = Color(0xFFA8BFA8); // Sage Green
  static const Color background = Color(0xFFF7F7F2); // Warm Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF202820); // Dark Charcoal
  static const Color accent = Color(0xFFE9A66B); // Soft Orange

  // Derived & Tonal Colors
  static const Color textSecondary = Color(0xFF637365); // Muted Forest Charcoal
  static const Color textLight = Color(0xFF8F9F90); // Light Sage Text
  static const Color surfaceVariant = Color(0xFFEFF3EE); // Very Soft Sage Wash
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8E0); // Subtle Border

  // Timer Progress Rings
  static const Color timerTrack = Color(0xFFE8ECE6); // Soft Track
  static const Color timerFocusProgress = Color(0xFF244B3B); // Forest Green Progress
  static const Color timerBreakProgress = Color(0xFFE9A66B); // Soft Orange for Break

  // Indicators & Status
  static const Color sessionActive = Color(0xFF244B3B);
  static const Color sessionInactive = Color(0xFFD6DFD5);
  static const Color streakOrange = Color(0xFFE9A66B);
}
