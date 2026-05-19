import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Modern Finance Palette
  static const Color primary = Color(0xFF1E1B4B); // Deep Indigo
  static const Color secondary = Color(0xFF059669); // Emerald
  static const Color accent = Color(0xFF0891B2); // Cyan
  
  // Light Mode Colors
  static const Color backgroundLight = Color(0xFFF9FAFB); // Soft Gray
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF111827); // Deep Gray/Black
  static const Color textSecondaryLight = Color(0xFF6B7280); // Medium Gray
  
  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Shared System Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF334155);

  // Legacy compatibility (re-routing to new tokens where possible)
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
}
