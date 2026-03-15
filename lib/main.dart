import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: HMColors.bg2,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Check for existing session
  final prefs = await SharedPreferences.getInstance();
  final hasSession = prefs.getString('session_cookie') != null;

  runApp(HealthMateApp(hasSession: hasSession));
}

class HealthMateApp extends StatelessWidget {
  final bool hasSession;
  const HealthMateApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthMate',
      debugShowCheckedModeBanner: false,
      theme: HMTheme.dark,
      home: hasSession ? const MainScreen() : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home':  (_) => const MainScreen(),
      },
    );
  }
}
