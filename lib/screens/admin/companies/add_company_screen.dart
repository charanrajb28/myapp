import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../../config/mail_config.dart';
import '../../../firebase_options.dart';
import '../../../services/turso_database_service.dart';
import 'company_detail_screen.dart';

class AddCompanyScreen extends StatefulWidget {
  final CompanyDetailArgs? company;
  const AddCompanyScreen({super.key, this.company});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _aboutController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mouDateController = TextEditingController();
  final _partnerSinceController = TextEditingController(text: DateTime.now().year.toString());
  final _hrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _customIndustryController = TextEditingController();

  String _industry = 'E-Commerce';
  bool _isSubmitting = false;

  List<String> _industries = [
    'E-Commerce',
    'Retail & Wholesale',
    'Logistics & Supply Chain',
    'Marketing & Sales',
    'Fintech & Finance',
    'E-Commerce Operations',
    'Digital Marketing',
    'Business Analytics',
    'Customer Support',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    final String rawIndustry = c?.industry ?? 'E-Commerce';
    if (_industries.contains(rawIndustry)) {
      _industry = rawIndustry;
    } else {
      _industry = 'Other';
      _customIndustryController.text = rawIndustry;
    }
    if (c != null) {
      _companyNameController.text = c.name;
      _locationController.text = c.location;
      _aboutController.text = c.about;
      _fetchExistingCompanyDetails(c.id);
    }
    _loadDynamicIndustries(rawIndustry);
  }

  Future<void> _fetchExistingCompanyDetails(String companyId) async {
    try {
      final res = await TursoDatabaseService.instance.querySingle(
        'SELECT * FROM companies WHERE id = ? OR user_id = ?',
        [companyId, companyId],
      );
      if (res != null && mounted) {
        setState(() {
          if (res['name'] != null && res['name'].toString().isNotEmpty) {
            _companyNameController.text = res['name'].toString();
          }
          if (res['location'] != null && res['location'].toString().isNotEmpty) {
            _locationController.text = res['location'].toString();
          }
          if (res['description'] != null && res['description'].toString().isNotEmpty) {
            _aboutController.text = res['description'].toString();
          }
          if (res['website'] != null) {
            _websiteController.text = res['website'].toString();
          }
          if (res['phone'] != null) {
            _phoneController.text = res['phone'].toString();
          }
          if (res['mou_date'] != null) {
            _mouDateController.text = res['mou_date'].toString();
          }
          if (res['partner_since'] != null) {
            _partnerSinceController.text = res['partner_since'].toString();
          }
          if (res['contact_email'] != null) {
            _hrEmailController.text = res['contact_email'].toString();
          }

          final String dbIndustry = res['industry']?.toString() ?? widget.company?.industry ?? 'E-Commerce';
          if (_industries.contains(dbIndustry)) {
            _industry = dbIndustry;
          } else {
            _industry = 'Other';
            _customIndustryController.text = dbIndustry;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching existing company details: $e');
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _mouDateController.dispose();
    _partnerSinceController.dispose();
    _hrEmailController.dispose();
    _passwordController.dispose();
    _customIndustryController.dispose();
    super.dispose();
  }

  Future<void> _loadDynamicIndustries(String currentIndustry) async {
    try {
      final response = await TursoDatabaseService.instance.query('SELECT DISTINCT industry FROM companies');
      final dbIndustries = response
          .map((item) => item['industry']?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      
      if (mounted) {
        setState(() {
          _industries.remove('Other');
          for (final ind in dbIndustries) {
            if (!_industries.contains(ind)) {
              _industries.add(ind);
            }
          }
          _industries.add('Other');

          if (_industries.contains(currentIndustry)) {
            _industry = currentIndustry;
            if (currentIndustry != 'Other') {
              _customIndustryController.clear();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading dynamic industries: $e');
    }
  }

  bool _obscurePassword = true;

  Future<void> _selectMOUDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _mouDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() => _isSubmitting = true);
      
      final companyName = _companyNameController.text.trim();
      final location = _locationController.text.trim();
      final about = _aboutController.text.trim();
      final website = _websiteController.text.trim();
      final phone = _phoneController.text.trim();
      final mouDate = _mouDateController.text.trim();
      final partnerSince = _partnerSinceController.text.trim();
      final hrEmail = _hrEmailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        String? userId;

        if (widget.company == null) {
          // 1. Create company user in Firebase Auth via secondary app instance to preserve admin session
          FirebaseApp secondaryApp;
          try {
            secondaryApp = Firebase.app('SecondaryApp');
          } catch (_) {
            secondaryApp = await Firebase.initializeApp(
              name: 'SecondaryApp',
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
          final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
          final cred = await secondaryAuth.createUserWithEmailAndPassword(
            email: hrEmail,
            password: password,
          );
          userId = cred.user?.uid;
          await secondaryApp.delete();

          if (userId != null) {
            final finalIndustry = _industry == 'Other'
                ? (_customIndustryController.text.trim().isNotEmpty ? _customIndustryController.text.trim() : 'Other')
                : _industry;

            await TursoDatabaseService.instance.execute(
              'INSERT INTO users (id, role, email, name) VALUES (?, ?, ?, ?)',
              [userId, 'company', hrEmail, companyName],
            );

            final companyId = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
            await TursoDatabaseService.instance.execute(
              '''
              INSERT INTO companies (id, user_id, name, industry, location, website, phone, contact_email, description, mou_date, partner_since)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''',
              [
                companyId,
                userId,
                companyName,
                finalIndustry,
                location,
                website,
                phone,
                hrEmail,
                about,
                mouDate,
                int.tryParse(partnerSince) ?? DateTime.now().year,
              ],
            );

            await _dispatchEmailAutomation(
              email: hrEmail,
              name: companyName,
              tempPassword: password,
            );
          }
        } else {
          userId = widget.company!.id;
          final finalIndustry = _industry == 'Other'
              ? (_customIndustryController.text.trim().isNotEmpty ? _customIndustryController.text.trim() : 'Other')
              : _industry;

          await TursoDatabaseService.instance.execute(
            '''
            UPDATE companies SET name = ?, industry = ?, location = ?, website = ?, phone = ?, contact_email = ?, description = ?, mou_date = ?, partner_since = ?
            WHERE id = ? OR user_id = ?
            ''',
            [
              companyName,
              finalIndustry,
              location,
              website,
              phone,
              hrEmail,
              about,
              mouDate,
              int.tryParse(partnerSince) ?? DateTime.now().year,
              userId,
              userId,
            ],
          );
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company Profile & Access Point Created Successfully'), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _dispatchEmailAutomation({
    required String email,
    required String name,
    required String tempPassword,
  }) async {
    final String senderEmail = MailConfig.senderEmail;
    final String senderPassword = MailConfig.senderAppPassword;

    if (senderEmail.isEmpty || senderPassword.isEmpty) {
      debugPrint('SMTP Credentials missing, skipping company mail send.');
      return;
    }

    final smtpServer = gmail(senderEmail, senderPassword);

    final message = Message()
      ..from = Address(senderEmail, 'ScholarBridge Admin')
      ..recipients.add(email)
      ..subject = 'Welcome to ScholarBridge - Company Access Credentials'
      ..html = """
        <div style='font-family: sans-serif; padding: 20px; color: #0F172A;'>
          <h2 style='color: #0F172A;'>Welcome to ScholarBridge, $name!</h2>
          <p>A partner company account has been successfully created for you by the administration.</p>
          <div style='background: #F8FAFC; padding: 15px; border-radius: 8px; border: 1px solid #E2E8F0; margin: 20px 0;'>
            <p style='margin: 5px 0;'><strong>Username / Email:</strong> $email</p>
            <p style='margin: 5px 0;'><strong>Temporary Password:</strong> $tempPassword</p>
          </div>
          <p style='font-size: 12px; color: #64748B;'>Please log in and update your password immediately.</p>
        </div>
      """;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Company welcome email sent: $sendReport');
    } catch (e) {
      debugPrint('Company email error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.company == null ? 'Add Partner Company' : 'Edit Company Profile',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Company Profile ──
              _sectionTitle('Company Details', 'Public facing profile information.'),
              const SizedBox(height: 24),

              _InputField(
                label: 'Company Name',
                hint: 'ex. Acme Corp',
                icon: Icons.business_rounded,
                controller: _companyNameController,
              ),
              const SizedBox(height: 20),

              _DropdownField(
                label: 'Industry Category',
                value: _industries.contains(_industry) ? _industry : 'Other',
                items: _industries,
                icon: Icons.category_outlined,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _industry = v;
                      if (v != 'Other') {
                        _customIndustryController.clear();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              if (_industry == 'Other') ...[
                _InputField(
                  label: 'Custom Industry Category',
                  hint: 'ex. Fintech, E-Commerce Logistics',
                  icon: Icons.edit_note_rounded,
                  controller: _customIndustryController,
                ),
                const SizedBox(height: 20),
              ],

              Row(children: [
                Expanded(
                  child: _InputField(
                    label: 'HQ Location',
                    hint: 'City, State',
                    icon: Icons.location_city_rounded,
                    controller: _locationController,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              _InputField(
                label: 'About / Description',
                hint: 'Brief overview of what the company does...',
                icon: Icons.info_outline_rounded,
                maxLines: 4,
                required: false,
                controller: _aboutController,
              ),

              const SizedBox(height: 48),

              // ── Contact & Partnership ──
              _sectionTitle('Contact & Partnership', 'Additional details for internal records.'),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(
                  child: _InputField(
                    label: 'Website URL',
                    hint: 'www.acmecorp.com',
                    icon: Icons.language_rounded,
                    required: false,
                    controller: _websiteController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InputField(
                    label: 'Phone Number',
                    hint: '+1 (555) 000-0000',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    required: false,
                    controller: _phoneController,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectMOUDate,
                    child: _InputField(
                      label: 'MOU Signed Date',
                      hint: 'Select Date',
                      icon: Icons.handshake_rounded,
                      required: false,
                      enabled: false, // Prevents typing, forces use of calendar
                      controller: _mouDateController,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InputField(
                    label: 'Partner Since',
                    hint: 'YYYY',
                    icon: Icons.calendar_month_rounded,
                    keyboardType: TextInputType.number,
                    required: false,
                    controller: _partnerSinceController,
                  ),
                ),
              ]),

              if (widget.company == null) ...[
                const SizedBox(height: 48),

                // ── Partner Portal Credentials ──
                _sectionTitle('Portal Credentials', 'Login details for the company HR/Admin portal.'),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _InputField(
                        label: 'HR / Contact Email',
                        hint: 'hr@acmecorp.com',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        controller: _hrEmailController,
                      ),
                      const SizedBox(height: 20),
                      _InputField(
                        label: 'Initial Password',
                        hint: '••••••••',
                        icon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        controller: _passwordController,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF94A3B8), size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ] else ...[
                const SizedBox(height: 48),
              ],

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: const Color(0xFF475569),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.company == null ? 'Create Company Profile' : 'Save Changes',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Form Field Components
// ─────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final int maxLines;
  final bool required;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? initialValue;
  final TextEditingController? controller;
  final void Function(String?)? onSaved;
  final bool enabled;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.initialValue,
    this.controller,
    this.onSaved,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: controller == null ? initialValue : null,
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
                : Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
                  ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          onSaved: onSaved,
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.unfold_more_rounded, color: Color(0xFF94A3B8)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
