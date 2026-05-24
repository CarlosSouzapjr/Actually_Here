import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: const ActuallyHereApp(),
    ),
  );
}

class ActuallyHereApp extends StatelessWidget {
  const ActuallyHereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Actually Here',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
