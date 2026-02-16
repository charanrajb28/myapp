import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/app.dart';
import 'package:myapp/core/theme/theme.dart';
import 'package:myapp/features/auth/data/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}
