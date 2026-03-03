import 'package:flutter/material.dart';
import 'dart:math';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  final TextEditingController _gpaController = TextEditingController();
  final TextEditingController _expectedGradController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedDepartment = 'Computer Science';
  String _selectedSemester = '6th Semester (Year 3)';
  String _selectedGender = 'Male';
  bool _sendInvite = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _gpaController.dispose();
    _expectedGradController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  @override
  Widget build(BuildContext context) {
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
                      'Create Student Profile',
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
                            _buildTextField(label: 'Date of Birth', controller: _dobController, hint: 'MM/DD/YYYY', icon: Icons.cake_outlined),
                            _buildDropdownField(
                              label: 'Gender',
                              value: _selectedGender,
                              items: ['Male', 'Female', 'Non-Binary', 'Other'],
                              onChanged: (val) => setState(() => _selectedGender = val!),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildResponsiveRow(isMobile, [
                            _buildTextField(label: 'Phone Number', controller: _phoneController, hint: '+1 (555) 000-0000', icon: Icons.phone_outlined),
                            const SizedBox(), // Empty for alignment 
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
                            _buildTextField(label: 'College ID Number', controller: _idController, hint: 'e.g. STU-2024-001', icon: Icons.badge_outlined),
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
                              items: ['4th Semester (Year 2)', '5th Semester (Year 3)', '6th Semester (Year 3)', '7th Semester (Year 4)', '8th Semester (Year 4)'],
                              onChanged: (val) => setState(() => _selectedSemester = val!),
                            ),
                            _buildTextField(label: 'Current GPA', controller: _gpaController, hint: 'e.g. 3.8', icon: Icons.grade_outlined),
                            _buildTextField(label: 'Expected Graduation', controller: _expectedGradController, hint: 'e.g. May 2027', icon: Icons.calendar_month_outlined),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── System Credentials Section ──
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
                    const SizedBox(height: 48),

                    // ── Action Buttons ──
                    if (isMobile) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Submit Logic
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comprehensive Student Profile created successfully.'),
                                backgroundColor: Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: const Text('Create Student Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                            onPressed: () {
                              // Submit Logic
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Comprehensive Student Profile created successfully.'),
                                  backgroundColor: Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            label: const Text('Create Student Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
