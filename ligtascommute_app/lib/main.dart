import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const LigtasCommuteApp());
}

class LigtasCommuteApp extends StatelessWidget {
  const LigtasCommuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LigtasCommute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
