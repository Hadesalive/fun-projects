import 'package:flutter/material.dart';

// iOS HIG-compliant color system
class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F2F7);
  static const Color lightSecondaryBackground = Color(0xFFFFFFFF);
  static const Color lightTertiary = Color(0xFFF2F2F7);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSecondaryBackground = Color(0xFF2C2C2E);
  static const Color darkTertiary = Color(0xFF3A3A3C);
  
  // Primary Color
  static const Color primary = Color(0xFF007AFF);
  
  // iOS System Colors
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemPink = Color(0xFFFF2D92);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemYellow = Color(0xFFFFCC00);
  
  // Gray Colors
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  
  // Text Colors
  static const Color lightPrimaryText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF3C3C43);
  static const Color lightTertiaryText = Color(0xFF3C3C43);
  
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFEBEBF5);
  static const Color darkTertiaryText = Color(0xFFEBEBF5);
  
  // Message Bubble Colors
  static const Color outgoingBubbleLight = systemBlue;
  static const Color outgoingBubbleDark = systemBlue;
  static const Color incomingBubbleLight = Color(0xFFE5E5EA);
  static const Color incomingBubbleDark = Color(0xFF2C2C2E);
  
  // Status Colors
  static const Color online = systemGreen;
  static const Color away = systemYellow;
  static const Color offline = systemGray;
  
  // Border Colors
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color darkBorder = Color(0xFF3A3A3C);
  
  // Special Colors
  static const Color unreadBadge = systemRed;
  static const Color typing = systemGray;
  static const Color delivered = systemBlue;
  static const Color read = systemBlue;
}
