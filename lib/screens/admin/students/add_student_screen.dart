import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AddStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? student;
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentContactController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  
  final TextEditingController _gpaController = TextEditingController();
  final TextEditingController _expectedGradController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final TextEditingController _adminSmtpEmailController = TextEditingController(text: 'charanrajb282004@gmail.com');
  final TextEditingController _adminSmtpPasswordController = TextEditingController(text: 'nftj sgzj occd kgid');

  String _selectedDepartment = 'Computer Science';
  String _selectedSemester = '6th Semester';
  String _selectedGender = 'Male';
  bool _sendInvite = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final s = widget.student!;
      final nameParts = (s['name'] ?? '').split(' ');
      _firstNameController.text = nameParts.length > 0 ? nameParts[0] : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _idController.text = s['enrollment_id']?.toString() ?? '';
      _phoneController.text = s['phone_number']?.toString() ?? '';
      _parentContactController.text = s['parent_contact']?.toString() ?? '';
      _parentEmailController.text = s['parent_email']?.toString() ?? '';
      _gpaController.text = s['gpa']?.toString() ?? '';
      _expectedGradController.text = s['graduation_year']?.toString() ?? '';
      _emailController.text = s['contact_email']?.toString() ?? '';
      _selectedDepartment = s['department'] ?? 'Computer Science';
      _selectedSemester = s['semester'] ?? '6th Semester';
      // Passwords are not fetched for security
      _sendInvite = false; 
    }
  }
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _parentContactController.dispose();
    _parentEmailController.dispose();
    _gpaController.dispose();
    _expectedGradController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminSmtpEmailController.dispose();
    _adminSmtpPasswordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    final password = String.fromCharCodes(Iterable.generate(
      14, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
    setState(() {
      _passwordController.text = password;
    });
  }

  Future<void> _submitStudent() async {
    final isEdit = widget.student != null;
    
    if (!isEdit && (_emailController.text.isEmpty || _passwordController.text.isEmpty || _firstNameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First Name, Email, and Password are required fields.'), backgroundColor: Colors.red)
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final supabase = Supabase.instance.client;
      String? userId;

      if (!isEdit) {
        // 1. Isolated client to prevent logging the Admin out during creation
        final inviteClient = SupabaseClient(
          'https://nfurwspybtiaycqntzev.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mdXJ3c3B5YnRpYXljcW50emV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyODg4NzcsImV4cCI6MjA5MDg2NDg3N30.IoOwVWFQDNtA5ZIz48G_Zm-VIbzX91MDdMqJ-fy58v0',
          authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
        );
        
        final AuthResponse res = await inviteClient.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'role': 'student',
            'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          }
        );
        userId = res.user?.id;
      } else {
        userId = widget.student!['user_id'];
      }
      
      if (userId != null) {
        // 2. Update student profile
        final gpaVal = double.tryParse(_gpaController.text) ?? 0.0;
        final updRes = await supabase.from('students').update({
          'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'enrollment_id': _idController.text.trim(),
          'college': 'Shesadripuram College',
          'contact_email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'parent_contact': _parentContactController.text.trim(),
          'parent_email': _parentEmailController.text.trim(),
          'department': _selectedDepartment,
          'semester': _selectedSemester,
          'gpa': gpaVal,
          'graduation_year': int.tryParse(_expectedGradController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        }).eq('user_id', userId).select();

        if ((updRes as List).isEmpty) {
          throw Exception("Failed to sync profile. Student record not found.");
        }
        
        if (!isEdit && _sendInvite) {
          await _dispatchEmailAutomation(
            email: _emailController.text.trim(),
            name: _firstNameController.text.trim(),
            tempPassword: _passwordController.text,
          );
        }
        
        if (mounted) {
          Navigator.pop(context, true); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Student Profile Updated!' : 'Student Profile Created!'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _dispatchEmailAutomation({required String email, required String name, required String tempPassword}) async {
    final String senderEmail = _adminSmtpEmailController.text.trim();
    final String senderPassword = _adminSmtpPasswordController.text.trim();
    
    if (senderEmail.isEmpty || senderPassword.isEmpty) {
      debugPrint('SMTP Credentials missing, skipping actual send.');
      return;
    }

    // Configured for Gmail SMTP by default as it's the most common for Option C
    final smtpServer = gmail(senderEmail, senderPassword);

    final message = Message()
      ..from = Address(senderEmail, 'ScholarBridge Admin')
      ..recipients.add(email)
      ..subject = 'Welcome to ScholarBridge Internship Portal'
      ..html = """
        <div style='font-family: sans-serif; padding: 20px; color: #0F172A;'>
          <h2 style='color: #2563EB;'>Welcome to the Program, $name!</h2>
          <p>Your internship tracking account has been successfully created by the administration.</p>
          <div style='background: #F1F5F9; padding: 15px; border-radius: 8px; margin: 20px 0;'>
            <p style='margin: 5px 0;'><strong>Portal Link:</strong> <a href='#'>Open ScholarBridge</a></p>
            <p style='margin: 5px 0;'><strong>Username:</strong> $email</p>
            <p style='margin: 5px 0;'><strong>One-Time Password:</strong> $tempPassword</p>
          </div>
          <p style='font-size: 12px; color: #64748B;'>Please change your password immediately upon your first login.</p>
        </div>
      """;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: $sendReport');
    } catch (e) {
      debugPrint('Email error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mailing failed: Check your SMTP credentials'), backgroundColor: Colors.orange)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add New Student',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            )),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student != null ? 'Edit Student Profile' : 'Create Student Profile',
                      style: TextStyle(fontSize: isMobile ? 22 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the comprehensive details to seamlessly onboard a new student into the internship tracking system.',
                      style: TextStyle(fontSize: isMobile ? 14 : 15, color: const Color(0xFF64748B), height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // ── Personal Details Section ──
                    _buildSectionHeader('PERSONAL DETAILS', Icons.person_outline),
                    _buildCard(
                      isMobile: isMobile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResponsiveRow(isMobile, [
                            _buildTextField(label: 'First Name', controller: _firstNameController, hint: 'e.g. John'),
                            _buildTextField(label: 'Last Name', controller: _lastNameController, hint: 'e.g. Doe'),
                          ]),
                          const SizedBox(height: 20),
                          _buildResponsiveRow(isMobile, [
                            _buildTextField(label: 'Student Mobile', controller: _phoneController, hint: '+91 00000 00000', icon: Icons.phone_outlined),
                            _buildDropdownField(
                              label: 'Gender',
                              value: _selectedGender,
                              items: ['Male', 'Female', 'Non-Binary', 'Other'],
                              onChanged: (val) => setState(() => _selectedGender = val!),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildResponsiveRow(isMobile, [
                            _buildTextField(label: 'Parent Contact Number', controller: _parentContactController, hint: '+91 00000 00000', icon: Icons.escalator_warning_outlined),
                            _buildTextField(label: 'Parent Email Address', controller: _parentEmailController, hint: 'parent@example.com', icon: Icons.alternate_email_outlined),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Academic Profile Section ──
                    _buildSectionHeader('ACADEMIC PROFILE', Icons.school_outlined),
                    _buildCard(
                      isMobile: isMobile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResponsiveRow(isMobile, [
                            _buildTextField(label: 'Enrollment ID', controller: _idController, hint: 'e.g. STU-2024-001', icon: Icons.badge_outlined),
                            _buildDropdownField(
                              label: 'Department / Major',
                              value: _selectedDepartment,
                              items: ['Computer Science', 'Information Tech', 'Electrical Eng', 'Mechanical Eng', 'Data Science'],
                              onChanged: (val) => setState(() => _selectedDepartment = val!),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildResponsiveRow(isMobile, [
                            _buildDropdownField(
                              label: 'Current Semester',
                              value: _selectedSemester,
                              items: ['1st Semester', '2nd Semester', '3rd Semester', '4th Semester', '5th Semester', '6th Semester'],
                              onChanged: (val) => setState(() => _selectedSemester = val!),
                            ),
                            _buildTextField(label: 'Current GPA', controller: _gpaController, hint: 'e.g. 8.5 / 10.0', icon: Icons.grade_outlined),
                            _buildTextField(label: 'Expected Graduation', controller: _expectedGradController, hint: 'e.g. May 2027', icon: Icons.calendar_month_outlined),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (widget.student == null) ...[
                      _buildSectionHeader('SYSTEM CREDENTIALS', Icons.admin_panel_settings_outlined),
                      _buildCard(
                        isMobile: isMobile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResponsiveRow(isMobile, [
                              _buildTextField(label: 'College Email Address', controller: _emailController, hint: 'student@college.edu', icon: Icons.email_outlined),
                              const SizedBox(),
                            ]),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Temporary Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                const SizedBox(height: 8),
                                if (isMobile) ...[
                                  TextField(
                                    controller: _passwordController,
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: 'Enter or generate...',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.password_rounded, size: 20, color: Color(0xFF64748B)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _generatePassword,
                                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                      label: const Text('Generate Secure Token', style: TextStyle(fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        foregroundColor: const Color(0xFF0F172A),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _passwordController,
                                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                          decoration: InputDecoration(
                                            hintText: 'Enter or generate secure password...',
                                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                            prefixIcon: const Icon(Icons.password_rounded, size: 20, color: Color(0xFF64748B)),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: _generatePassword,
                                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                                        label: const Text('Generate Secure Token', style: TextStyle(fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          foregroundColor: const Color(0xFF0F172A),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _sendInvite,
                                        onChanged: (val) {
                                          setState(() {
                                            _sendInvite = val ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF0F172A),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Send System Invite Email', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                        SizedBox(height: 4),
                                        Text('Automatically dispatch an email containing the secure generated credentials and portal link to the student.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),

                    // ── Action Buttons ──
                    if (isMobile) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitStudent,
                          icon: _isSubmitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(_isSubmitting ? (isEdit ? 'Updating...' : 'Creating...') : (isEdit ? 'Save Changes' : 'Create Student Profile'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel & Go Back', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: const Text('Cancel & Go Back', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitStudent,
                            icon: _isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, size: 20),
                            label: Text(_isSubmitting ? 'Creating...' : 'Create Student Profile', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((e) => Padding(
          padding: EdgeInsets.only(bottom: e == children.last ? 0 : 20.0),
          child: e,
        )).toList(),
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((e) {
          if (e is SizedBox && e.child == null) {
             return Expanded(child: e);
          }
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e == children.last ? 0 : 20.0),
              child: e,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required bool isMobile, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, String? hint, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
              items: items.map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
