import 'package:flutter/material.dart';

class AppConstants {
  // App Name
  static const String appName = 'Smart Dairy';

  // ✅ API Base URLx
  static const String baseUrl = 'https://milkapi.onrender.com';

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFF81C784);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color successColor = Color(0xFF66BB6A);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Farm Sizes (for dropdown)
  static const List<String> farmSizes = [
    '1 acre',
    '2 acres',
    '3 acres',
    '4 acres',
    '5 acres',
    '6 acres',
    '7 acres',
    '8 acres',
    '9 acres',
    '10 acres',
    '15 acres',
    '20 acres',
    '25 acres',
    '30 acres',
    '50 acres',
    '100 acres',
    'Small (< 5 acres)',
    'Medium (5-20 acres)',
    'Large (> 20 acres)',
  ];

  // User Roles
  static const String roleFarmer = 'user';
  static const String roleAdmin = 'admin';

  // Messages
  static const String noInternetMessage = 'No internet connection';
  static const String serverErrorMessage =
      'Server error. Please try again later';
  static const String unexpectedErrorMessage = 'An unexpected error occurred';
}

// Show snackbar helper
void showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          isError ? AppConstants.errorColor : AppConstants.successColor,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
