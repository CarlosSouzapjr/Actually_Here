import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/server_connection_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
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
      home: const ServerConnectionScreen(),
    );
  }
}
