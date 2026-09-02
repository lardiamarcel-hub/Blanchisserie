import 'package:flutter/material.dart';

/// Thème unique de l'application : gros boutons, texte lisible, contrastes
/// forts — pensé pour une clientèle pas nécessairement technophile.
class AppTheme {
  static const Color bleuPrincipal = Color(0xFF0B5FA5);
  static const Color vertSucces = Color(0xFF1E8E4E);
  static const Color orangeAlerte = Color(0xFFE8871E);
  static const Color rougeErreur = Color(0xFFC62828);
  static const Color fondClair = Color(0xFFF5F7FA);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: bleuPrincipal,
      primary: bleuPrincipal,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: fondClair,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: bleuPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}
