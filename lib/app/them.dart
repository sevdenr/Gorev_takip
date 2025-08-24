import 'package:flutter/material.dart';
import 'package:trello/app/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightScaffoldBackground,
        useMaterial3: true,
        
        // ColorScheme - Material 3 için önemli
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          surface: Colors.white,           // Dialog ve card arka planları
          onSurface: Colors.black,         // Yazı renkleri
          primary: Colors.blue,
          onPrimary: Colors.white,
        ),
        
        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.lightAppBarForeground,
          elevation: 1,
          surfaceTintColor: Colors.transparent,  // Material 3 renk tonlamasını kaldır
          shadowColor: Colors.grey,
          iconTheme: IconThemeData(color: Colors.black),
          actionsIconTheme: IconThemeData(color: Colors.black),
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,  // Material 3 renk tonlamasını kaldır
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Dialog Theme - En önemli kısım
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Bottom Sheet Theme
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white,
          modalBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        
        // PopupMenu Theme
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          elevation: 8,
          textStyle: TextStyle(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        
        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
        
        // ListTile Theme
        listTileTheme: ListTileThemeData(
          textColor: Colors.black,
          iconColor: Colors.grey.shade700,
        ),

        // Switch Theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue;
            }
            return Colors.grey.shade400;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue.withOpacity(0.5);
            }
            return Colors.grey.shade300;
          }),
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade200,
          selectedColor: Colors.blue.withOpacity(0.2),
          deleteIconColor: Colors.grey.shade600,
          labelStyle: TextStyle(color: Colors.black87),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkScaffoldBackground,
        useMaterial3: true,
        
        // ColorScheme - Dark tema için
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: AppColors.darkAppBarBackground,
          onSurface: Colors.white,
          primary: Colors.blue,
          onPrimary: Colors.white,
        ),
        
        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkAppBarBackground,
          foregroundColor: AppColors.darkAppBarForeground,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.darkAppBarBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Dialog Theme
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkAppBarBackground,
          elevation: 8,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Bottom Sheet Theme
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.darkAppBarBackground,
          modalBackgroundColor: AppColors.darkAppBarBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        
        // PopupMenu Theme
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.darkAppBarBackground,
          elevation: 8,
          textStyle: TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF374151),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade300),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        
        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
        
        // ListTile Theme
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.grey.shade300,
        ),

        // Switch Theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue;
            }
            return Colors.grey.shade600;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue.withOpacity(0.5);
            }
            return Colors.grey.shade700;
          }),
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: Color(0xFF4B5563),
          selectedColor: Colors.blue.withOpacity(0.3),
          deleteIconColor: Colors.grey.shade400,
          labelStyle: TextStyle(color: Colors.white),
        ),
      );

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}