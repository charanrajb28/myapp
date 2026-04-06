import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;
  const EditCompanyProfileScreen({super.key, required this.companyData});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController industryController;
  late TextEditingController descController;
  late TextEditingController locationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.companyData['name']);
    industryController = TextEditingController(text: widget.companyData['industry']);
    descController = TextEditingController(text: widget.companyData['description']);
    locationController = TextEditingController(text: widget.companyData['location']);
  }

  Future<void> _saveProfile() async {
     setState(() => _isSaving = true);
     try {
       final supabase = Supabase.instance.client;
       await supabase.from('companies').update({
         'name': nameController.text,
         'industry': industryController.text,
         'description': descController.text,
         'location': locationController.text,
       }).eq('id', widget.companyData['id']);

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
         Navigator.pop(context);
       }
     } catch (e) {
       debugPrint('Error saving profile: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update Error: $e')));
         setState(() => _isSaving = false);
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('EDIT PROFILE DETAILS', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SingleChildScrollView(
            child: Column(
              children: [
                // ── BRANDING_HEADER ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 160, width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                    ),
                    Positioned(
                      bottom: -40, left: 24,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Center(child: Text(nameController.text.isNotEmpty ? nameController.text[0].toUpperCase() : 'C', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 32, fontWeight: FontWeight.w900))),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),

                // ── PROFILE_FIELDS ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BASIC INFORMATION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 24),
                      _industrialField('COMPANY NAME', nameController),
                      const SizedBox(height: 20),
                      _industrialField('INDUSTRY TYPE', industryController),
                      const SizedBox(height: 20),
                      _industrialField('HEADQUARTERS LOCATION', locationController),
                      const SizedBox(height: 32),
                      const Text('COMPANY DESCRIPTION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      _industrialField('WRITE ABOUT YOUR COMPANY', descController, maxLines: 5),
                      const SizedBox(height: 48),
                      _commitIdentityBtn(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(color: Colors.white60, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _industrialField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _commitIdentityBtn(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect),
      child: CustomPaint(painter: _DotPainter()),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
