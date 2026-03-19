import 'package:flutter/material.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;
  const EditCompanyProfileScreen({super.key, required this.companyData});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController tagController;
  late TextEditingController bioController;
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.companyData['name']);
    tagController = TextEditingController(text: widget.companyData['tagline']);
    bioController = TextEditingController(text: 'We are a high-performance technology node specializing in AI cloud infra and decentralized system architecture. Our mission is to scale the next generation of digital industrial engines.');
    locationController = TextEditingController(text: 'Bangalore, MH, India');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('EDIT_IDENTITY_CONSOLE', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SingleChildScrollView(
            child: Column(
              children: [
                // ── BRANDING_TERMINAL (Banner & Profile) ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 160, width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Stack(
                        children: [
                          Positioned(right: 16, bottom: 16, child: _editBadge(Icons.camera_alt_rounded)),
                          const Center(child: Text('BANNER_PREVIEW', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4))),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -40, left: 24,
                      child: Stack(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: const Icon(Icons.business_rounded, color: Color(0xFF6366F1), size: 32),
                          ),
                          Positioned(right: 0, bottom: 0, child: _editBadge(Icons.edit_rounded, size: 28)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),

                // ── METADATA_FIELDS ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('> IDENTITY_PARAMETERS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 24),
                      _industrialField('COMPANY_NAME_LABEL', nameController),
                      const SizedBox(height: 20),
                      _industrialField('CORPORATE_TAGLINE', tagController),
                      const SizedBox(height: 20),
                      _industrialField('LOCATION_NODE', locationController),
                      const SizedBox(height: 32),
                      const Text('> MISSION_STORY_LEDGER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      _industrialField('BIO_DESCRIPTION_LOG', bioController, maxLines: 5),
                      const SizedBox(height: 48),
                      _commitIdentityBtn(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editBadge(IconData icon, {double size = 32}) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IDENTITY_SYNCHRONIZED_SUCCESSFULLY. RE-INDEXING_COMPLETE.')));
        Navigator.pop(context, {'name': nameController.text, 'tagline': tagController.text});
      },
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
              Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('COMMIT_IDENTITY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
