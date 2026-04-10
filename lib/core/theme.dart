import 'package:flutter/material.dart';

class AppTheme {
  static const spotifyGreen = Color(0xFF1DB954);

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: spotifyGreen,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.grey[900],
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: spotifyGreen,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
  );
}