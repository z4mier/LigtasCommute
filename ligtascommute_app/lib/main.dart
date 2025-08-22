import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'services/my_settings_actions.dart';

void main() {
  runApp(const LigtasCommuteApp());
}

class LigtasCommuteApp extends StatelessWidget {
  const LigtasCommuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create ONE instance and reuse it (so prefs/lang/dark state persist)
    final settingsActions = MySettingsActions();

    return MaterialApp(
      title: 'LigtasCommute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins', // optional if you added GoogleFonts config
      ),

      // Your current home (login). After login, navigate to your home screen.
      home: const LoginScreen(),

      // Provide a named route so you can open Settings anywhere:
      routes: {
        '/settings': (_) => SettingsScreen(actions: settingsActions),
      },
    );
  }
}
