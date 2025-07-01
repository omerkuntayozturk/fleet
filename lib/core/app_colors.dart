import 'package:flutter/material.dart';

class AppColors {
  // Modern primary colors
  static const Color primaryDark = Color(0xFF2D3250);  // Deep navy blue
  static const Color primary = Color(0xFF7077A1);      // Muted blue
  static const Color secondary = Color(0xFFE6B9DE);    // Soft pink
  static const Color accent = Color(0xFFF6E3DB);       // Pale peach

  // Modern neutral shades
  static const Color background = Color(0xFFF8F9FA);   // Off-white
  static const Color surface = Color(0xFFFFFFFF);      // Pure white
  static const Color grey100 = Color(0xFFF1F3F5);      // Lightest grey
  static const Color grey200 = Color(0xFFE9ECEF);      // Light grey
  static const Color grey300 = Color(0xFFDEE2E6);      // Medium grey
  static const Color grey400 = Color(0xFFCED4DA);      // Dark grey

  // Text colors
  static const Color textPrimary = Color(0xFF2D3250);  // Dark blue
  static const Color textSecondary = Color(0xFF6C757D); // Medium grey
  static const Color textLight = Color(0xFFADB5BD);    // Light grey

  // Status colors
  static const Color success = Color(0xFF40916C);      // Forest green
  static const Color warning = Color(0xFFFFB020);      // Amber
  static const Color error = Color(0xFFDC3545);        // Modern red
  static const Color info = Color(0xFF0DCAF0);         // Light blue
  static const Color primaryColor = Color(0xFF2196F3); // Using blue as an example
  static const Color textPrimaryColor = Color(0xFF333333); // Dark Gray
  static const Color textFieldBackgroundColor = Color(0xFFF5F5F5); // Light gray color for text field backgrounds
  static const Color darkBlueColor = Color(0xFF0A192F); // Dark Blue
  static const Color accentColor = Color.fromARGB(255, 94, 96, 204); // Purple/Accent Color
  static const backgroundColor = Color(0xFFF3F4F6); // Light Gray
  static const textSecondaryColor = Color(0xFF666666); // Medium Gray
  static const Color iconColor = Colors.grey;
  static const Color appBarBackgroundColor = Colors.white;
  static const Color iconBackgroundColor = Color(0xFFF5F5F5); // Light grey background for icons
  static const Color backgroundStart = Color(0xFF2C3E50);
  static const Color backgroundEnd = Color(0xFF3498DB);
  static const Color secondaryAccentColor = Color(0x000000ff);  // Your accent color value here
  static const Color accentColorLight = Color(0x000000ff);  // Add a lighter shade
  static const Color goldColor = Color(0xFFFFD700);





  // Eklenen renkler
  static const textColorDark = Color(0xFF333333); // Same as textPrimaryColor
  static const textColorMedium = Color(0xFF666666);

  static const secondaryColor = textSecondaryColor;

  static var expenseColor; // Same as textSecondaryColor
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF2D3250),
    Color(0xFF7077A1),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFE6B9DE),
    Color(0xFFF6E3DB),
  ];
  
  // Helper method for color opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
