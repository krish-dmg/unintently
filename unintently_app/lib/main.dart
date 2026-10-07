import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UnintentlyApp());
}

class UnintentlyApp extends StatelessWidget {
  const UnintentlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unintently',
      debugShowCheckedModeBanner: false,
      theme: UnintentlyTheme.lightTheme,
      darkTheme: UnintentlyTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
