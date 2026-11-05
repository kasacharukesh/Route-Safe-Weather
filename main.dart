import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RouteSafeApp());
}

class RouteSafeApp extends StatelessWidget {
  const RouteSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF19B6A4),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF071426),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF071426),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF10243B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF203B55)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
