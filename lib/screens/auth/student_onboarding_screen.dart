import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../student/student_shell.dart';

class StudentOnboardingScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String email;

  const StudentOnboardingScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  State<StudentOnboardingScreen> createState() =>
      _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 1: Academic Info ────────────────────────────────────────────────
  final _enrollmentIdController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _gpaController = TextEditingController();

  // ── Step 2: Personal Contact ────────────────────────────────────────────
  final _phoneController = TextEditingController();
  String _selectedSemester = '1st Semester';
  String _selectedDepartment = 'B.Com LSCM';

  static const _college = 'Sheshadripuram College';

  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF6366F1);
  static const _textSecondary = Color(0xFF64748B);
  static const _borderColor = Color(0xFFE2E8F0);
  static const _fieldBg = Color(0xFFF8FAFC);
  static const _errorColor = Color(0xFFDC2626);

  final List<String> _semesters = [
    '1st Semester', '2nd Semester', '3rd Semester',
    '4th Semester', '5th Semester', '6th Semester',
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
  ];

  late final AnimationController _progressAnimController;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimController.animateTo(
      1 / 3,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimController.dispose();
    _enrollmentIdController.dispose();
    _graduationYearController.dispose();
    _gpaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _progressAnimController.animateTo(
      (step + 1) / 3,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep < _formKeys.length) {
        if (!_formKeys[_currentStep].currentState!.validate()) return;
      }
      _goToStep(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('students').upsert({
        'user_id': widget.userId,
        'name': widget.name,
        'contact_email': widget.email,
        'college': _college,
        'department': _selectedDepartment,
        'enrollment_id': _enrollmentIdController.text.trim(),
        'graduation_year': _graduationYearController.text.trim().isEmpty
            ? null
            : int.tryParse(_graduationYearController.text.trim()),
        'gpa': _gpaController.text.trim().isEmpty ? null : double.tryParse(_gpaController.text.trim()),
        'phone_number': _phoneController.text.trim(),
        'semester': _selectedSemester,
      }, onConflict: 'user_id');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🎉 Profile set up! Welcome to ScholarBridge.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepMeta(
        icon: Icons.school_rounded,
        title: 'Academic Details',
        subtitle: 'Tell us about your institution',
        color: const Color(0xFF3B82F6),
      ),
      _StepMeta(
        icon: Icons.contact_phone_rounded,
        title: 'Personal Contact',
        subtitle: 'How can we reach you?',
        color: const Color(0xFF8B5CF6),
      ),
      _StepMeta(
        icon: Icons.fact_check_rounded,
        title: 'Review & Confirm',
        subtitle: 'Everything look right?',
        color: const Color(0xFF10B981),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + Progress ──────────────────────────────────────────
            _buildHeader(steps),

            // ── Page Content ───────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(steps),
                ],
              ),
            ),

            // ── Bottom Navigation ──────────────────────────────────────────
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header with step indicator ────────────────────────────────────────────
  Widget _buildHeader(List<_StepMeta> steps) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, size: 18, color: _accent),
              ),
              const SizedBox(width: 10),
              const Text(
                'ScholarBridge',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} of 3',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Step dot indicators
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
                            color: (isActive || isDone)
                                ? steps[i].color
                                : const Color(0xFFE2E8F0),
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
          const SizedBox(height: 20),

          // Current step title
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(
              key: ValueKey(_currentStep),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: steps[_currentStep].color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(steps[_currentStep].icon,
                          size: 18, color: steps[_currentStep].color),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[_currentStep].title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _primary,
                          ),
                        ),
                        Text(
                          steps[_currentStep].subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  // ── Step 1: Academic Details ───────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          children: [
            _card(children: [
              // College — fixed, read-only
              _inputLabel('College'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded,
                        size: 20, color: _textSecondary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        _college,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: _textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'College is pre-configured by your institution.',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Department — dropdown
              _inputLabel('Department / Course *'),
              const SizedBox(height: 8),
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
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    items: _departments
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDepartment = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _inputLabel('Enrollment / Roll Number *'),
              _textField(
                controller: _enrollmentIdController,
                hint: 'e.g. SIT-2022-1042',
                icon: Icons.badge_rounded,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enrollment ID is required' : null,
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
                  final year = int.tryParse(v!.trim());
                  if (year == null || year < 2020 || year > 2035) {
                    return 'Enter a valid year (2020–2035)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _inputLabel('GPA / CGPA (optional)'),
              _textField(
                controller: _gpaController,
                hint: 'e.g. 3.85',
                icon: Icons.star_outline_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Personal Contact ───────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          children: [
            // Email (pre-filled, read-only)
            _card(children: [
              _inputLabel('College Email Address'),
              _textField(
                controller: TextEditingController(text: widget.email),
                hint: widget.email,
                icon: Icons.alternate_email_rounded,
                disabled: true,
              ),
              const SizedBox(height: 8),
              const Text(
                'Email is linked to your account and cannot be changed.',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
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
              _inputLabel('Current Semester *'),
              const SizedBox(height: 8),
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
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    items: _semesters
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSemester = val);
                    },
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Info callout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: _accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your profile details will be used for internship applications and check-ins. You can update them any time from your profile settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4338CA),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
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

  // ── Step 3: Review & Confirm ───────────────────────────────────────────────
  Widget _buildStep3(List<_StepMeta> steps) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'STUDENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Academic details review
          _reviewSection(
            icon: Icons.school_rounded,
            title: 'Academic Details',
            color: const Color(0xFF3B82F6),
            onEdit: () => _goToStep(0),
            rows: [
              _ReviewRow('College', _college),
              _ReviewRow('Department', _selectedDepartment),
              _ReviewRow('Enrollment ID', _enrollmentIdController.text.trim()),
              _ReviewRow('Graduation Year', _graduationYearController.text.trim()),
              if (_gpaController.text.trim().isNotEmpty)
                _ReviewRow('GPA / CGPA', _gpaController.text.trim()),
            ],
          ),

          const SizedBox(height: 16),

          // Contact details review
          _reviewSection(
            icon: Icons.contact_phone_rounded,
            title: 'Contact Details',
            color: const Color(0xFF8B5CF6),
            onEdit: () => _goToStep(1),
            rows: [
              _ReviewRow('Email', widget.email),
              _ReviewRow('Phone', _phoneController.text.trim()),
              _ReviewRow('Semester', _selectedSemester),
            ],
          ),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'By proceeding, you confirm that all information entered is accurate. You can edit your profile any time from the Profile tab.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Review section card ───────────────────────────────────────────────────
  Widget _reviewSection({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onEdit,
    required List<_ReviewRow> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _primary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: _textSecondary,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ...rows.map((row) => _buildReviewRow(row)),
        ],
      ),
    );
  }

  Widget _buildReviewRow(_ReviewRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value.isEmpty ? '—' : row.value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation bar ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final isLastStep = _currentStep == 2;

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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18, color: _primary),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : (isLastStep ? _submitProfile : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep
                    ? const Color(0xFF10B981)
                    : _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Complete Setup' : 'Continue',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLastStep
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _primary,
        ),
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
        hintStyle: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon,
            color: disabled ? const Color(0xFFCBD5E1) : _textSecondary,
            size: 20),
        filled: true,
        fillColor: disabled
            ? const Color(0xFFF1F5F9).withValues(alpha: 0.6)
            : _fieldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor, width: 2),
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _errorColor,
        ),
      ),
    );
  }
}

// ── Helper models ──────────────────────────────────────────────────────────────

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

class _ReviewRow {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);
}
