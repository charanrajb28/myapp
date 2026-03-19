// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'company_detail_screen.dart';

class AddCompanyScreen extends StatefulWidget {
  final CompanyDetailArgs? company;
  const AddCompanyScreen({super.key, this.company});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile data
  String _companyName = '';
  String _industry = 'Information Technology';
  String _location = '';
  String _about = '';
  String _website = '';

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    if (c != null) {
      _companyName = c.name;
      if (_industries.contains(c.industry)) _industry = c.industry;
      _location = c.location;
      _about = c.about;
    }
  }

  // Contact & Partnership
  String _phone = '';
  String _mouDate = '';
  String _partnerSince = '';

  // Credentials
  String _hrEmail = '';
  String _password = '';
  bool _obscurePassword = true;

  final _industries = [
    'Information Technology',
    'Financial Services',
    'Aerospace & Defense',
    'Mechanical Eng.',
    'Healthcare & Biotech',
    'Consulting',
    'Other'
  ];

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company Added Successfully')));
      Navigator.pop(context);
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
                initialValue: _companyName,
                onSaved: (v) => _companyName = v!,
              ),
              const SizedBox(height: 20),

              _DropdownField(
                label: 'Industry Category',
                value: _industry,
                items: _industries,
                icon: Icons.category_outlined,
                onChanged: (v) => setState(() => _industry = v!),
              ),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(
                  child: _InputField(
                    label: 'HQ Location',
                    hint: 'City, State',
                    icon: Icons.location_city_rounded,
                    initialValue: _location,
                    onSaved: (v) => _location = v!,
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
                initialValue: _about,
                onSaved: (v) => _about = v ?? '',
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
                    onSaved: (v) => _website = v ?? '',
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
                    onSaved: (v) => _phone = v ?? '',
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(
                  child: _InputField(
                    label: 'MOU Signed Date',
                    hint: 'MM/DD/YYYY',
                    icon: Icons.handshake_rounded,
                    required: false,
                    onSaved: (v) => _mouDate = v ?? '',
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
                    onSaved: (v) => _partnerSince = v ?? '',
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
                        onSaved: (v) => _hrEmail = v!,
                      ),
                      const SizedBox(height: 20),
                      _InputField(
                        label: 'Initial Password',
                        hint: '••••••••',
                        icon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        onSaved: (v) => _password = v!,
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
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.company == null ? 'Create Company Profile' : 'Save Changes',
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
  final void Function(String?)? onSaved;

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
    this.onSaved,
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
          initialValue: initialValue,
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
