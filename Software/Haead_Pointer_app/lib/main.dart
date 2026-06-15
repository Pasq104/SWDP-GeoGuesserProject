import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/connection_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color beigeSeed = Color(0xFFD8C3A5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Altium League Head Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: beigeSeed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F1E8),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEADDCB),
          foregroundColor: Color(0xFF3E3328),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFBF5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      home: const ConnectionPage(title: 'Altium League Head Controller'),
    );
  }
}