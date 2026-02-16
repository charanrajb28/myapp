import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/core/theme/theme.dart';
import 'package:myapp/features/auth/presentation/pages/login_page.dart';
import 'package:myapp/features/auth/presentation/pages/registration_page.dart';
import 'package:myapp/features/auth/presentation/pages/user_type_selection.dart';
import 'package:myapp/features/student/presentation/pages/student_home_page.dart';
import 'package:myapp/features/company/presentation/pages/company_home_page.dart';
import 'package:myapp/features/student/presentation/pages/settings_page.dart';

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: isLoggedIn ? '/student' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const UserTypeSelectionPage(),
        ),
        GoRoute(
          path: '/login/:userType',
          builder: (context, state) => LoginPage(userType: state.pathParameters['userType']!),
        ),
        GoRoute(
          path: '/register/:userType',
          builder: (context, state) => RegistrationPage(userType: state.pathParameters['userType']!),
        ),
        GoRoute(
          path: '/student',
          builder: (context, state) => const StudentHomePage(),
        ),
        GoRoute(
          path: '/company',
          builder: (context, state) => const CompanyHomePage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    );

    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
      return MaterialApp.router(
        title: 'Intern-Connect',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        routerConfig: router,
      );
    });
  }
}
