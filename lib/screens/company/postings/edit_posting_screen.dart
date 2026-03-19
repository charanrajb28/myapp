import 'package:flutter/material.dart';

class EditPostingScreen extends StatefulWidget {
  final Map<String, dynamic> posting;
  const EditPostingScreen({super.key, required this.posting});

  @override
  State<EditPostingScreen> createState() => _EditPostingScreenState();
}

class _EditPostingScreenState extends State<EditPostingScreen> {
  late TextEditingController roleController;
  late TextEditingController descController;
  late TextEditingController stipendController;
  late TextEditingController durationController;
  late TextEditingController responsibilityController;

  @override
  void initState() {
    super.initState();
    roleController = TextEditingController(text: widget.posting['role']);
    descController = TextEditingController(text: 'Our company is scaling decentralised AI nodes. We need a high-performance engineer to build technical dashboards and cloud infra for enterprise monitoring.');
    stipendController = TextEditingController(text: '25000');
    durationController = TextEditingController(text: '06');
    responsibilityController = TextEditingController(text: '- Architect and scale responsive UI modules.\n- Optimize Node.js service layers.\n- Integrate Firebase functions.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('EDIT_POSTING_CONSOLE', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('> METADATA_TERMINAL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 24),
                _industrialField('ROLE_TITLE_LABEL', roleController),
                const SizedBox(height: 20),
                _industrialField('MISSION_DESCRIPTION_LOG', descController, maxLines: 4),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _industrialField('STIPEND (INR)', stipendController, isNumeric: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _industrialField('DURATION (MO)', durationController, isNumeric: true)),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('> LOCATION_SELECT_TERMINAL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 16),
                _locationOption(),
                const SizedBox(height: 32),
                const Text('> RESPONSIBILITY_LEDGER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 16),
                _industrialField('DUTIES_BULLETED', responsibilityController, maxLines: 6),
                const SizedBox(height: 48),
                _commitBtn(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool isRemote = true;

  Widget _locationOption() {
    return Row(
      children: [
        _locBtn('REMOTE_IN', isRemote, () => setState(() => isRemote = true)),
        const SizedBox(width: 12),
        _locBtn('ONSITE_HQ', !isRemote, () => setState(() => isRemote = false)),
      ],
    );
  }

  Widget _locBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _industrialField(String label, TextEditingController controller, {int maxLines = 1, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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

  Widget _commitBtn(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RECORDS_COMMITTED_SUCCESSFULLY. DATA_SYNC_ACTIVE.')));
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('COMMIT_CHANGES', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
