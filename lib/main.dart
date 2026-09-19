import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/turso_database_service.dart';
import 'services/auth_service.dart';
import 'services/supabase_compat.dart';

import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/student_signup_screen.dart';
import 'screens/company/company_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/dashboard/admin_dashboard_screen.dart';
import 'screens/student/student_shell.dart';
import 'utils/device_session_helper.dart';
import 'services/fcm_service.dart';
import 'widgets/app_logo.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  TursoDatabaseService.instance.configure(
    dbUrl: const String.fromEnvironment(
      'TURSO_DATABASE_URL',
      defaultValue: 'https://aaroha-sandhyashree.aws-ap-south-1.turso.io',
    ),
    authToken: const String.fromEnvironment(
      'TURSO_AUTH_TOKEN',
      defaultValue: 'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJnaWQiOiJhYWI2OGVkNS04OGFmLTQwMGQtOGI5Yi0yNjczMjcxMWNkMDciLCJpYXQiOjE3ODU2NjQ2MjEsImtpZCI6IjJCN2xEd3hVd3lKVWZRWnNZVEprNFFpMi1keWZncnV1cDN3TkdUQ1R6X2siLCJyaWQiOiI1ZjViZThhZi0xMjZiLTQzZDQtYWU4Zi1mZjQ3NDM0YTczNTMifQ.PQt6cPa_RM7VTaRuEK-Z3qgfpgRkkWTwJiLQ3GXWE9dB9b6QkHkgYA2ApQXRJCrugsBBCcvLBR-yVGxQRU-ZAw',
    ),
  );
  await TursoDatabaseService.instance.ensureSchema();

  // Ensure default admin user account exists
  await AuthService.instance.ensureDefaultAdminAccount(
    email: 'admin@aaroha.com',
    password: 'adminpassword123',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Set to true while a sign-up / sign-in screen is handling its own
/// navigation, so the global auth listener doesn't interfere.
bool suppressAuthRedirect = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize Firebase Push Notifications with navigator context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService.initialize(_navigatorKey.currentContext);
    });

    _authSubscription =
        AuthService.instance.authStateChanges.listen((user) {
      if (user != null) {
        FCMService.login(user.uid);
      } else {
        FCMService.logout();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Aaroha',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.figtreeTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/login': (context) => const LoginPage(),
        '/logout': (context) => const LogoutScreen(),
        '/signup': (context) => const StudentSignUpScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _checkAuth() {
    _authSub = AuthService.instance.authStateChanges.listen((user) async {
      if (user != null && _checking) {
        _authSub?.cancel();
        await _navigateToDashboard(user);
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null && _checking) {
        _authSub?.cancel();
        await _navigateToDashboard(currentUser);
      } else if (currentUser == null && _checking) {
        _authSub?.cancel();
        setState(() => _checking = false);
      }
    });
  }

  Future<void> _navigateToDashboard(User user) async {
    try {
      final userData = await TursoDatabaseService.instance.querySingle(
        'SELECT role FROM users WHERE id = ?',
        [user.uid],
      );

      final role = userData?['role'];
      if (!mounted) return;

      Widget destination;
      if (role == 'admin' || role == 'sub_admin') {
        destination = const AdminShell(child: AdminDashboardScreen());
      } else if (role == 'student') {
        destination = const StudentShell();
      } else if (role == 'company') {
        destination = const CompanyShell();
      } else {
        destination = const LoginPage();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destination),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 120, heroTag: 'app_logo'),
              const SizedBox(height: 24),
              const Text(
                'Aaroha',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'An initiative by Dhruthi Internship Commitee, Seshadripuram college',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const CircularProgressIndicator(
                color: Color(0xFF0F172A),
              ),
            ],
          ),
        ),
      );
    }
    return const LoginPage();
  }
}

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  @override
  void initState() {
    super.initState();
    _performLogout();
  }

  Future<void> _performLogout() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final token = await getOrCreateDeviceToken();
        await TursoDatabaseService.instance.execute(
          '''
          UPDATE user_device_sessions
          SET is_active = 0, logged_out_at = CURRENT_TIMESTAMP
          WHERE user_id = ? AND device_token = ?
          ''',
          [user.uid, token],
        );
      }
      await AuthService.instance.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    
    await Future.delayed(const Duration(seconds: 1)); // Show the cool animation for a second
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const accentColor = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.03),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logout Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Text
                const Text(
                  'Signing Out',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Securing your session and returning to login...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Loading Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom branding
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Aaroha',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: primaryColor.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enterprise Grade Security',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<bool?> _showConflictDialog(BuildContext context, String otherDeviceName) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Device Conflict',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Text(
            'Another device ($otherDeviceName) is currently logged in.\n\n'
            'Would you like to log out from that device and log in here?',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Log Out Other Device',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF8FAFC);
    final surfaceColor = Colors.white;
    final textPrimary = const Color(0xFF0F172A);
    final textSecondary = const Color(0xFF64748B);
    final borderColor = const Color(0xFFE2E8F0);
    final primaryAccent = const Color(0xFF0F172A);
    final subtleBackground = const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo ──────────────────────────────────────────────
                  const AppLogo(size: 96, heroTag: 'app_logo'),
                  const SizedBox(height: 20),
                  Text(
                    'Aaroha',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'An initiative by Dhruthi Internship Commitee, Seshadripuram college',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Login Form ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College Email / ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your official credentials',
                            hintStyle: TextStyle(
                              color: textSecondary.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(Icons.alternate_email,
                                color: textSecondary, size: 22),
                            filled: true,
                            fillColor: subtleBackground,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryAccent, width: 2),
                            ),
                          ),
                          style: TextStyle(
                              color: textPrimary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                                color: textSecondary.withValues(alpha: 0.7),
                                letterSpacing: 2),
                            prefixIcon: Icon(Icons.lock_outline,
                                color: textSecondary, size: 22),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: subtleBackground,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryAccent, width: 2),
                            ),
                          ),
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: _obscurePassword ? 2 : 0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) => setState(
                                        () => _rememberMe = val ?? false),
                                    activeColor: primaryAccent,
                                    side: BorderSide(
                                        color: textSecondary.withValues(alpha: 0.5),
                                        width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/forgot-password',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              setState(() => _isLoading = true);
                              try {
                                final cred = await AuthService.instance.signInWithEmailAndPassword(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                );
                                
                                final user = cred.user;
                                if (user != null) {
                                  final deviceToken = await getOrCreateDeviceToken();
                                  final deviceInfo = getDeviceInfo();
                                  
                                  // Check for active session(s)
                                  final activeSessions = await TursoDatabaseService.instance.query(
                                    '''
                                    SELECT device_token, device_info FROM user_device_sessions
                                    WHERE user_id = ? AND is_active = 1
                                    ''',
                                    [user.uid],
                                  );
                                      
                                  bool proceed = true;
                                  if (activeSessions.isNotEmpty) {
                                    final currentActiveToken = activeSessions.first['device_token'];
                                    final currentActiveInfo = activeSessions.first['device_info'];
                                    
                                    if (currentActiveToken != deviceToken) {
                                      if (!context.mounted) {
                                        await AuthService.instance.signOut();
                                        return;
                                      }
                                      final shouldLogoutOther = await _showConflictDialog(context, currentActiveInfo ?? 'Other device');
                                      if (shouldLogoutOther == true) {
                                        await TursoDatabaseService.instance.execute(
                                          '''
                                          UPDATE user_device_sessions
                                          SET is_active = 0, logged_out_at = CURRENT_TIMESTAMP
                                          WHERE user_id = ? AND is_active = 1
                                          ''',
                                          [user.uid],
                                        );
                                            
                                        await TursoDatabaseService.instance.execute(
                                          '''
                                          INSERT INTO user_device_sessions (id, user_id, device_token, device_info, is_active)
                                          VALUES (?, ?, ?, ?, 1)
                                          ''',
                                          ['session_${DateTime.now().millisecondsSinceEpoch}', user.uid, deviceToken, deviceInfo],
                                        );
                                      } else {
                                        proceed = false;
                                        await AuthService.instance.signOut();
                                      }
                                    }
                                  } else {
                                    await TursoDatabaseService.instance.execute(
                                      '''
                                      INSERT INTO user_device_sessions (id, user_id, device_token, device_info, is_active)
                                      VALUES (?, ?, ?, ?, 1)
                                      ''',
                                      ['session_${DateTime.now().millisecondsSinceEpoch}', user.uid, deviceToken, deviceInfo],
                                    );
                                  }

                                  if (proceed) {
                                    final userData = await TursoDatabaseService.instance.querySingle(
                                      'SELECT role FROM users WHERE id = ?',
                                      [user.uid],
                                    );
                                        
                                    final role = userData?['role'];
                                    
                                    if (!context.mounted) return;
                                    
                                    if (role == 'admin' || role == 'sub_admin') {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (context) => const AdminShell(child: AdminDashboardScreen())),
                                      );
                                    } else if (role == 'student') {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (context) => const StudentShell()),
                                      );
                                    } else if (role == 'company') {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (context) => const CompanyShell()),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('User role not found or not assigned.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    )
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign In to Portal',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Register link ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New student?',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/signup');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Create an account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Security stamp ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text(
                        'Secured by Institutional Authentication',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
