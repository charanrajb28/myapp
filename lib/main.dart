import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/forgot_password_screen.dart';
import 'screens/company/company_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/dashboard/admin_dashboard_screen.dart';
import 'screens/student/student_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Replace with your actual Supabase URL and Anon Key
  // Once you start your local Supabase instance (using 'supabase start')
  await Supabase.initialize(
    url: 'https://nfurwspybtiaycqntzev.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mdXJ3c3B5YnRpYXljcW50emV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyODg4NzcsImV4cCI6MjA5MDg2NDg3N30.IoOwVWFQDNtA5ZIz48G_Zm-VIbzX91MDdMqJ-fy58v0',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (session != null) {
        return;
      }

      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        _redirectToLogin();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ScholarBridge',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/login': (context) => const LoginPage(),
        '/logout': (context) => const LogoutScreen(),
      },
    );
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
    // Simulate a sign-out process
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
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
                    'ScholarBridge',
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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // ── DEV-ONLY: used for frontend testing. Removed when real auth lands. ──
  String _devRole = 'Student';
  bool _devPanelOpen = false;
  // ────────────────────────────────────────────────────────────────────────

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _devAnimController;
  late final Animation<double> _devPanelAnim;

  @override
  void initState() {
    super.initState();
    _devAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _devPanelAnim = CurvedAnimation(
      parent: _devAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _devAnimController.dispose();
    super.dispose();
  }

  void _toggleDevPanel() {
    setState(() {
      _devPanelOpen = !_devPanelOpen;
      if (_devPanelOpen) {
        _devAnimController.forward();
      } else {
        _devAnimController.reverse();
      }
    });
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.school, size: 36, color: textPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ScholarBridge',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Internship Management System',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
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
                                final res = await Supabase.instance.client.auth.signInWithPassword(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                );
                                
                                final user = res.user;
                                if (user != null) {
                                  // Fetch role from public.users table
                                  final userData = await Supabase.instance.client
                                      .from('users')
                                      .select('role')
                                      .eq('id', user.id)
                                      .single();
                                      
                                  final role = userData['role'];
                                  
                                  if (!mounted) return;
                                  
                                  if (role == 'admin') {
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
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
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
                  Text(
                    'Credentials are issued by the administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
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

                  const SizedBox(height: 36),

                  // ── 🛠 DEV ONLY — Role Switcher (collapsed by default) ──
                  // TODO: Remove this entire block before production / backend integration.
                  GestureDetector(
                    onTap: _toggleDevPanel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3), // amber-50
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFBBF24), width: 1), // amber-400
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.developer_mode_rounded,
                              size: 16, color: Color(0xFF92400E)),
                          const SizedBox(width: 6),
                          Text(
                            'Dev Tools — $_devRole',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.5)
                                .animate(_devPanelAnim),
                            child: const Icon(Icons.keyboard_arrow_down,
                                size: 16, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Animated collapsible dev panel
                  SizeTransition(
                    sizeFactor: _devPanelAnim,
                    axisAlignment: -1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFBBF24), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️  Dev only — select portal to test frontend',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                final client = Supabase.instance.client;
                                try {
                                  // 1. Wipe public tables via RPC function (If created)
                                  try {
                                    await client.rpc('reset_demo_db');
                                  } catch (e) {
                                    debugPrint('RPC Reset failed (Function might not exist yet): $e');
                                    // Fallback if the user hasn't run the SQL yet
                                    await client.from('applications').delete().neq('id', '00000000-0000-0000-0000-000000000000');
                                    await client.from('students').delete().neq('id', '00000000-0000-0000-0000-000000000000');
                                    await client.from('companies').delete().neq('id', '00000000-0000-0000-0000-000000000000');
                                  }

                                  // 2. Create Fresh Demo Auth Accounts with Isolated Client
                                  // We use a temporary client to batch create WITHOUT logging the current user out.
                                  final inviteClient = SupabaseClient(
                                    'https://nfurwspybtiaycqntzev.supabase.co',
                                    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mdXJ3c3B5YnRpYXljcW50emV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyODg4NzcsImV4cCI6MjA5MDg2NDg3N30.IoOwVWFQDNtA5ZIz48G_Zm-VIbzX91MDdMqJ-fy58v0',
                                    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
                                  );

                                  await inviteClient.auth.signUp(
                                    email: 'admin@scholarbridge.com',
                                    password: 'adminpassword123',
                                    data: {'role': 'admin', 'name': 'System Admin'},
                                  );
                                  await inviteClient.auth.signUp(
                                    email: 'student@college.edu',
                                    password: 'studentpassword123',
                                    data: {'role': 'student', 'name': 'Alex Student', 'semester': '6th Semester'},
                                  );
                                  await inviteClient.auth.signUp(
                                    email: 'hr@techcorp.com',
                                    password: 'companypassword123',
                                    data: {'role': 'company', 'name': 'TechCorp HR'},
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database Reset & Demo Users Created!')));
                                  }
                                } catch(e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note: Some Auth users might already exist. Proceed to login.')));
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              icon: _isLoading 
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF92400E)))
                                : const Icon(Icons.bolt_rounded),
                              label: const Text('Wipe DB & Generate Demo Credentials'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDE68A), // amber-200
                                foregroundColor: const Color(0xFF92400E), // amber-900
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _devRoleChip(String role, IconData icon, Color textPrimary) {
    final selected = _devRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _devRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
