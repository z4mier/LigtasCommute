// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/my_settings_actions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LigtasCommuteApp());
}

class LigtasCommuteApp extends StatelessWidget {
  const LigtasCommuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // One shared instance so dark mode & language persist/rebuild globally
    final settingsActions = MySettingsActions();

    return AnimatedBuilder(
      animation: settingsActions,
      builder: (context, _) {
        return MaterialApp(
          title: 'LigtasCommute',
          debugShowCheckedModeBanner: false,

          // Light theme
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF0F172A),
            brightness: Brightness.light,
            fontFamily: 'Poppins',
            snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
          ),

          // Dark theme
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF0F172A),
            brightness: Brightness.dark,
            fontFamily: 'Poppins',
            snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
          ),

          // Flip based on saved setting
          themeMode: settingsActions.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // App entry
          home: const LoginScreen(),

          // Named routes
          routes: {
            '/home': (_) => const HomeScreen(),
            '/settings': (_) => SettingsScreen(actions: settingsActions),
            '/login': (_) => const LoginScreen(),
          },
        );
      },
    );
  }
}
