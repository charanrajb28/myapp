import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manage_postings_screen.dart';

class CreatePostingScreen extends StatefulWidget {
  const CreatePostingScreen({super.key});

  @override
  State<CreatePostingScreen> createState() => _CreatePostingScreenState();
}

class _CreatePostingScreenState extends State<CreatePostingScreen> {
  final roleController = TextEditingController();
  final descController = TextEditingController();
  final stipendController = TextEditingController();
  final durationController = TextEditingController();
  final responsibilityController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool isRemote = true;
  bool _isSaving = false;

  Future<void> _publishPosting() async {
    if (roleController.text.isEmpty || descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required job details.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final companyRes = await supabase
          .from('companies')
          .select('id, name')
          .eq('user_id', user.id)
          .single();
      
      final companyId = companyRes['id'];
      
      final colors = ['#6366F1', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444'];
      final randomColor = colors[DateTime.now().millisecond % colors.length];

      await supabase.from('internships').insert({
        'company_id': companyId,
        'role': roleController.text,
        'about': descController.text,
        'stipend': stipendController.text,
        'duration': durationController.text.trim(),
        'industry': 'Software Engineering',
        'location': isRemote ? 'Remote' : 'On-site',
        'brand_color': randomColor,
        'status': 'INTERVIEWING',
        'logo_initial': (companyRes['name'] as String).isNotEmpty ? (companyRes['name'] as String)[0].toUpperCase() : 'C',
        'responsibilities': responsibilityController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
        'deadline': DateTime(
          _selectedDeadline.year,
          _selectedDeadline.month,
          _selectedDeadline.day,
        ).toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posted successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error publishing posting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('CREATE NEW JOB POST', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                const Text('JOB DETAILS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 24),
                _industrialField('JOB TITLE', roleController, hint: 'e.g. Mobile Developer'),
                const SizedBox(height: 20),
                _industrialField('JOB DESCRIPTION', descController, maxLines: 4, hint: 'What will the intern do?'),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _industrialField('STIPEND (INR)', stipendController, isNumeric: true, hint: 'e.g. 15000')),
                    const SizedBox(width: 16),
                    Expanded(child: _industrialField('DURATION (MO)', durationController, isNumeric: true, hint: 'e.g. 06')),
                  ],
                ),
                const SizedBox(height: 20),
                _deadlineField(),
                const SizedBox(height: 32),
                const Text('WORK LOCATION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 16),
                _locationOption(),
                const SizedBox(height: 32),
                const Text('RESPONSIBILITIES', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 16),
                _industrialField('LIST TASKS (ONE PER LINE)', responsibilityController, maxLines: 6, hint: 'Bullet points here...'),
                const SizedBox(height: 48),
                _publishBtn(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.white60,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _industrialField(String label, TextEditingController controller, {int maxLines = 1, bool isNumeric = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric 
            ? TextInputType.number 
            : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w500),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _deadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECTION DEADLINE',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDeadline),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline.isBefore(now) ? now : _selectedDeadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDeadline = picked;
    });
  }

  Widget _locationOption() {
    return Row(
      children: [
        _locBtn('Work from Home', isRemote, () => setState(() => isRemote = true)),
        const SizedBox(width: 12),
        _locBtn('On-site Office', !isRemote, () => setState(() => isRemote = false)),
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

  Widget _publishBtn(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _publishPosting,
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
              Icon(Icons.send_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('PUBLISH JOB POST', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
