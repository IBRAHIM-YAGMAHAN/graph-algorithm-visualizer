import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() => runApp(const GraphAlgoApp());

class GraphAlgoApp extends StatelessWidget {
  const GraphAlgoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Algoritmalar Odevi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00A0FF),
          secondary: Color(0xFF00A0FF),
        ),
      ),
      home: const MainScreen(),
    );
  }
}