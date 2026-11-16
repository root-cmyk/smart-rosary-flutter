
import 'package:flutter/material.dart';

const purple = Color(0xFF7654D6);
const deepPurple = Color(0xFF5033A5);
const lavender = Color(0xFFECE5FF);
const pageBg = Color(0xFFFAF9FF);
const ink = Color(0xFF27213D);
const muted = Color(0xFF89849B);

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
        fontFamily: 'Arial',
      );
}