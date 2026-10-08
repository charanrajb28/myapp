import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/turso_database_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/app_logo.dart';
import '../student/student_shell.dart';

class StudentOnboardingScreen extends StatefulWidget {
  final String? userId;
  final String? name;
  final String? email;
  final String? password;

  const StudentOnboardingScreen({
    super.key,
    this.userId,
    this.name,
    this.email,
    this.password,
  });

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 1: USN Verification & Basic Student Info ──────────────────────
  final _usnController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedSemester = '1st Semester';
  String _selectedDepartment = 'B.Com LSCM';
  
  bool _isVerifyingUsn = false;
  bool _usnVerified = false;
  String? _usnError;

  // ── Step 2: Other Personal & Academic Details ──────────────────────────
  final _collegeController = TextEditingController(text: 'Sheshadripuram College');
  final _phoneController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _gpaController = TextEditingController();

  final _parentNameController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _parentEmailController = TextEditingController();

  // ── Step 3: Account Credentials (Email & Password Confirmation) ────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF6366F1);
  static const _textSecondary = Color(0xFF64748B);
  static const _borderColor = Color(0xFFE2E8F0);
  static const _fieldBg = Color(0xFFF8FAFC);
  static const _errorColor = Color(0xFFDC2626);

  final List<String> _semesters = [
    '1st Semester', '2nd Semester', '3rd Semester',
    '4th Semester', '5th Semester', '6th Semester',
    '7th Semester', '8th Semester',
  ];

  final List<String> _departments = [
    'B.Com LSCM',
    'B.Com A&F',
    'B.Com (Regular)',
    'BCA',
    'BBA',
  ];

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late final AnimationController _progressAnimController;

  @override
  void initState() {
    super.initState();
    if (widget.name != null && widget.name!.isNotEmpty) {
      _nameController.text = widget.name!;
    }
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
    if (widget.password != null && widget.password!.isNotEmpty) {
      _passwordController.text = widget.password!;
      _confirmPasswordController.text = widget.password!;
    }

    _progressAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimController.animateTo(
      1 / 4,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
    _usnController.dispose();
    _nameController.dispose();
    _collegeController.dispose();
    _phoneController.dispose();
    _graduationYearController.dispose();
    _gpaController.dispose();
    _parentNameController.dispose();
    _parentContactController.dispose();
    _parentEmailController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  String _normalizeSemester(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '1st Semester';

    // Exact match first
    for (final sem in _semesters) {
      if (sem.toLowerCase() == trimmed.toLowerCase()) {
        return sem;
      }
    }

    // Extract digits e.g. "3", "3rd", "Semester 3"
    final digitMatch = RegExp(r'[1-8]').firstMatch(trimmed);
    if (digitMatch != null) {
      final num = int.parse(digitMatch.group(0)!);
      final suffixes = ['st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th'];
      final expected = '$num${suffixes[num - 1]} Semester';
      if (_semesters.contains(expected)) {
        return expected;
      }
    }

    return trimmed;
  }

  Future<void> _verifyUsn() async {
    final usn = _usnController.text.trim();
    if (usn.isEmpty) {
      setState(() {
        _usnError = 'Please enter your University Seat No.';
        _usnVerified = false;
      });
      return;
    }

    setState(() {
      _isVerifyingUsn = true;
      _usnError = null;
      _usnVerified = false;
    });

    try {
      // 1. Check if user already exists in students table in DB
      final existingStudent = await TursoDatabaseService.instance.query(
        'SELECT id FROM students WHERE LOWER(enrollment_id) = LOWER(?)',
        [usn],
      );

      if (existingStudent.isNotEmpty) {
        setState(() {
          _usnError = 'User with University Seat No. already exists.';
          _usnVerified = false;
          _isVerifyingUsn = false;
        });
        return;
      }

      // 2. Check if USN exists in pending_students_verification table
      final pendingList = await TursoDatabaseService.instance.query(
        'SELECT * FROM pending_students_verification WHERE LOWER(usn) = LOWER(?)',
        [usn],
      );

      if (pendingList.isEmpty) {
        setState(() {
          _usnError = 'Invalid University Seat No. University Seat No. not found in student verification database.';
          _usnVerified = false;
          _isVerifyingUsn = false;
        });
        return;
      }

      // 3. USN Valid & Verified! Autofill Name, Class/Department, Semester
      final studentData = pendingList.first;
      final name = studentData['name']?.toString() ?? '';
      final department = studentData['department']?.toString() ?? 'B.Com LSCM';
      final rawSemester = studentData['semester']?.toString() ?? '1st Semester';
      final semester = _normalizeSemester(rawSemester);

      setState(() {
        if (name.isNotEmpty) {
          _nameController.text = name;
        }
        if (_departments.contains(department)) {
          _selectedDepartment = department;
        } else if (department.isNotEmpty) {
          _departments.add(department);
          _selectedDepartment = department;
        }
        if (!_semesters.contains(semester)) {
          _semesters.add(semester);
        }
        _selectedSemester = semester;
        _usnVerified = true;
        _usnError = null;
        _isVerifyingUsn = false;
      });
    } catch (e) {
      debugPrint('Error verifying University Seat No.: $e');
      setState(() {
        _usnError = 'Error verifying University Seat No.: $e';
        _usnVerified = false;
        _isVerifyingUsn = false;
      });
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _progressAnimController.animateTo(
      (step + 1) / 4,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (!_usnVerified) {
        await _verifyUsn();
        if (!_usnVerified) return;
      }
      if (!_formKeys[0].currentState!.validate()) return;
      _goToStep(1);
    } else if (_currentStep == 1) {
      if (!_formKeys[1].currentState!.validate()) return;
      _goToStep(2);
    } else if (_currentStep == 2) {
      if (!_formKeys[2].currentState!.validate()) return;
      _goToStep(3);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKeys[3].currentState!.validate()) return;

    if (!_usnVerified) {
      _showError('Please verify your University Seat No. in Step 1 first.');
      _goToStep(0);
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match. Please confirm your password.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Create user account and add student data to DB
      final cred = await AuthService.instance.createStudentAccount(
        email: email,
        password: password,
        name: _nameController.text.trim(),
        enrollmentId: _usnController.text.trim(),
        college: _collegeController.text.trim(),
        department: _selectedDepartment,
        semester: _selectedSemester,
      );

      final uid = cred.user!.uid;

      // Update additional student profile details in DB
      await TursoDatabaseService.instance.execute(
        '''
        UPDATE students 
        SET phone_number = ?, graduation_year = ?, gpa = ?, parent_name = ?, parent_contact = ?, parent_email = ?
        WHERE user_id = ? OR enrollment_id = ?
        ''',
        [
          _phoneController.text.trim(),
          _graduationYearController.text.trim().isEmpty ? null : int.tryParse(_graduationYearController.text.trim()),
          _gpaController.text.trim().isEmpty ? null : double.tryParse(_gpaController.text.trim()),
          _parentNameController.text.trim(),
          _parentContactController.text.trim(),
          _parentEmailController.text.trim(),
          uid,
          _usnController.text.trim(),
        ],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🎉 Account created & registration successful!',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(ErrorHandler.getErrorMessage(e, fallbackMessage: 'Failed to complete registration. Please try again.'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _StepMeta(
        icon: Icons.verified_user_rounded,
        title: 'University Seat No. Verification',
        subtitle: 'Verify your University Seat No. & basic info',
        color: Color(0xFF3B82F6),
      ),
      const _StepMeta(
        icon: Icons.assignment_ind_rounded,
        title: 'Academic Details',
        subtitle: 'Add contact & academic info',
        color: Color(0xFF8B5CF6),
      ),
      const _StepMeta(
        icon: Icons.lock_outline_rounded,
        title: 'Parent Details',
        subtitle: 'Add parent or guardian contact',
        color: Color(0xFFF59E0B),
      ),
      const _StepMeta(
        icon: Icons.lock_outline_rounded,
        title: 'Account Credentials',
        subtitle: 'Set your email & password',
        color: Color(0xFF10B981),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + Progress Indicator ──────────────────────────────────
            _buildHeader(steps),

            // ── Multi-Step Form Pages ─────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),

            // ── Bottom Navigation Controls ────────────────────────────────────
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header Component ───────────────────────────────────────────────────────
  Widget _buildHeader(List<_StepMeta> steps) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _primary),
                onPressed: () {
                  if (_currentStep > 0) {
                    _prevStep();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 4),
              const AppLogo(size: 28),
              const SizedBox(width: 8),
              const Text(
                'Aaroha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _primary),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: List.generate(3, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: isDone ? () => _goToStep(i) : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 4,
                          decoration: BoxDecoration(
                            color: (isActive || isDone) ? steps[i].color : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 6),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Current Step Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: steps[_currentStep].color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(steps[_currentStep].icon, size: 18, color: steps[_currentStep].color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[_currentStep].title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _primary),
                  ),
                  Text(
                    steps[_currentStep].subtitle,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  // ── Step 1: USN Verification & Basic Student Info ────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              children: [
                _inputLabel('Enter University Seat No. *'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usnController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. U18GH24C0160',
                          prefixIcon: const Icon(Icons.badge_rounded, color: _textSecondary, size: 20),
                          filled: true,
                          fillColor: _fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'University Seat No. is required';
                          if (!_usnVerified) return 'Please verify your University Seat No.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isVerifyingUsn ? null : _verifyUsn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isVerifyingUsn
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),

                if (_usnError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _usnError!,
                            style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_usnVerified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'University Seat No. Verified! Student details fetched successfully.',
                            style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 20),

                // Name Field (locked after USN verification)
                _inputLabel('Full Name *'),
                _textField(
                  controller: _nameController,
                  hint: 'Student Full Name',
                  icon: Icons.person_outline_rounded,
                  disabled: true,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                // Class / Department Dropdown
                _inputLabel('Class / Department *'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDepartment,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                      style: const TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 15),
                      items: _departments
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Semester Dropdown
                _inputLabel('Current Semester *'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSemester,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
                      style: const TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 15),
                      items: _semesters
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Other Academic & Contact Details (No DB Write) ────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              children: [
                _inputLabel('College / Institution'),
                _textField(
                  controller: _collegeController,
                  hint: 'College Name',
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 20),

                _inputLabel('Phone Number *'),
                _textField(
                  controller: _phoneController,
                  hint: 'e.g. +91 98765 43210',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Phone number is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _inputLabel('Expected Graduation Year *'),
                _textField(
                  controller: _graduationYearController,
                  hint: 'e.g. 2026',
                  icon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Graduation year is required';
                    final yr = int.tryParse(v!.trim());
                    if (yr == null || yr < 2020 || yr > 2035) {
                      return 'Enter a valid year (2020-2035)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _inputLabel('GPA / Percentage (Optional)'),
                _textField(
                  controller: _gpaController,
                  hint: 'e.g. 8.5',
                  icon: Icons.star_outline_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, size: 18, color: _accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your details are stored in memory only. No data is sent to the database until email and password are submitted in the final step.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4338CA), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Account Credentials (Email & Passwords) ──────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: _card(
          children: [
            _inputLabel('Parent / Guardian Name *'),
            _textField(
              controller: _parentNameController,
              hint: 'Full name',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Parent or guardian name is required' : null,
            ),
            const SizedBox(height: 20),
            _inputLabel('Parent / Guardian Contact *'),
            _textField(
              controller: _parentContactController,
              hint: 'e.g. +91 98765 43210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Parent contact is required' : null,
            ),
            const SizedBox(height: 20),
            _inputLabel('Parent / Guardian Email'),
            _textField(
              controller: _parentEmailController,
              hint: 'parent@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isNotEmpty && !value.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              children: [
                _inputLabel('College Email Address *'),
                _textField(
                  controller: _emailController,
                  hint: 'student@example.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final val = (v ?? '').trim();
                    if (val.isEmpty || !val.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _inputLabel('Password *'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: _textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textSecondary),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: _fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
                  ),
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Password is required';
                    if (v!.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _inputLabel('Confirm Password *'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: _textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textSecondary),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: _fieldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
                  ),
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Controls ───────────────────────────────────────────
  Widget _buildBottomNav() {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _isSaving ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _borderColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18, color: _primary),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(fontWeight: FontWeight.w700, color: _primary)),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSaving ? null : (isLastStep ? _submitRegistration : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? const Color(0xFF10B981) : _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Create Account' : 'Continue',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool disabled = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !disabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: disabled ? const Color(0xFF94A3B8) : _primary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: disabled ? const Color(0xFFCBD5E1) : _textSecondary, size: 20),
        filled: true,
        fillColor: disabled ? const Color(0xFFF1F5F9).withValues(alpha: 0.6) : _fieldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorColor, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorColor, width: 2)),
        errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _errorColor),
      ),
    );
  }
}

class _StepMeta {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StepMeta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
