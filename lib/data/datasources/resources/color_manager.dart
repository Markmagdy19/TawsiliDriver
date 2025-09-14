import 'package:flutter/material.dart';

class ColorManager {
  // Primary Colors
  static Color primary = const Color(0xFFE1B46E);
  static Color buttonDark = const Color(0xFF2C2C2C);
  static Color darkPrimary = const Color(0xFFD17D11);
  static Color lightPrimary = const Color(0x00ffffff); // 80% opacity
  static Color profile = const Color(0xFFDDE4EF);
  static Color lightBlue1 = const Color(0xFFECF2FC);
  static const Color lightGrey = Colors.black12;





  // Accent Colors
  static Color secondary = const Color(0xFF3B4B59);
  static Color accent = const Color(0xFF4CAF50);
  static const Color divider = Color(0x4D4285F4);
  // Background Colors
  static Color scaffoldBackground = const Color(0xFFF5F5F5);
  static Color cardBackground = const Color(0xFFFFFFFF);
  static const  Color lightBlueBackground =  Color(0xFFECF2FC); // Added ECF2FC

  // Text Colors
  static Color textPrimary = const Color(0xFF212121);
  static Color textSecondary = const Color(0xFF757575);
  static Color textWhite = const Color(0xFFFFFFFF);
  // Grey Shades
  static Color grey = const Color(0xFFEFEFEF);
  static Color grey1 = const Color(0xFF707070);
  static Color grey2 = const Color(0xFF797979);

  static  const Color grey5 =  Color(0XFF929292);
  // Standard Colors
  static Color white = const Color(0xFFFFFFFF);
  static Color black = const Color(0xFF000000);
  static const Color redCancelText = Color(0xffEA5858);

  static Color transparent = const Color(0x00000000);

  // Feedback Colors
  static Color error = const Color(0xFFE61F34);

  static Color success = const Color(0xFF388E3C);
  static Color warning = const Color(0xFFF57C00);
  static Color info = const Color(0xFF1976D2);
  static const Color lightGrayBackground = Color(0xFFF2F3F2);
  // Dark Mode Colors
  static Color darkScaffoldBackground = const Color(0xFF121212);
  static Color darkCardBackground = const Color(0xFF1E1E1E);
  static Color darkTextPrimary = const Color(0xFFFFFFFF);
  static Color darkTextSecondary = const Color(0xFFBDBDBD);
  static Color darkGreyBlue = const Color(0xFF61677D); // Added 61677D

  // Other Common Colors
  static Color red = const Color(0xFFF44336);
  static Color pink = const Color(0xFFE91E63);
  static Color purple = const Color(0xFF9C27B0);
  static Color deepPurple = const Color(0xFF673AB7);
  static Color indigo = const Color(0xFF3F51B5);
  static Color blue = const Color(0xFF1877F2); // Added 1877F2

  static Color lightBlue = const Color(0xFF03A9F4);
  static Color cyan = const Color(0xFF00BCD4);
  static Color teal = const Color(0xFF009688);
  static Color green = const Color(0xFF4CAF50);
  static Color lightGreen = const Color(0xFF8BC34A);
  static Color lime = const Color(0xFFCDDC39);
  static Color yellow = const Color(0xFFFFEB3B);
  static Color amber = const Color(0xFFFFC107);
  static Color orange = const Color(0xFFFF9800);
  static Color deepOrange = const Color(0xFFFF5722);
  static Color brown = const Color(0xFF795548);

  // Social Media Colors
  static Color facebookBlue = const Color(0xFF4267B2);
  static Color twitterBlue = const Color(0xFF1DA1F2);
  static Color googleRed = const Color(0xFFDB4437);
  static Color linkedInBlue = const Color(0xFF0077B5);
  static Color instagramPurple = const Color(0xFFE1306C);
  static Color youtubeRed = const Color(0xFFFF0000);

  // Material Design Opacity Variants
  static Color primaryWithOpacity70 = const Color(0xB3E1B46E);
  static Color primaryWithOpacity50 = const Color(0x80E1B46E);
  static Color primaryWithOpacity30 = const Color(0x4DE1B46E);

  // Gradient Colors
  static List<Color> primaryGradient = [primary, darkPrimary];
  static List<Color> sunsetGradient = [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)];
  static List<Color> oceanGradient = [const Color(0xFF00B4DB), const Color(0xFF0083B0)];


  static const Color darkGray = Color(0xFF2C2C2C); // Add this line
  static const Color BlueNotification = Color(0xffD1E4FC);
  static const Color redNotification = Color(0x1A2C2C2C);
  static const Color gradientStart = Color(0xFFEEF6FF); // Light blue-white
  static const Color gradientEnd = Color(0xFF1877F2);   // Facebook blue
  static const Color semiTransparentWhite = Color(0x8AFFFFFF);


 static Color transparentBlue = const Color(0x4285F433);


  final BoxDecoration reusableGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: const [
        Color(0xffD1E4FC),
        Color(0xFFEEF6FF),
      ],
      stops: const [0.0, 1],
    ),
  );



  static LinearGradient getBackgroundGradient({double angle = 180.0}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [gradientStart, gradientEnd],
      stops: const [0.0, 0.4095], // 0% and 40.95%
    );
  }



}