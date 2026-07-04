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
  final roleController       = TextEditingController();
  final descController       = TextEditingController();
  final stipendController    = TextEditingController();
  final durationController   = TextEditingController();
  final notesController      = TextEditingController();
  final _taskInputController = TextEditingController();
  final activeDurationController = TextEditingController(text: '7');

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool isRemote  = true;
  bool _isSaving = false;

  // Tasks list
  final List<String> _tasks = [];

  // Days of the week state
  static const List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _activeDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

  @override
  void dispose() {
    roleController.dispose();
    descController.dispose();
    stipendController.dispose();
    durationController.dispose();
    notesController.dispose();
    _taskInputController.dispose();
    activeDurationController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _taskInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(text);
      _taskInputController.clear();
    });
  }

  void _removeTask(int index) {
    setState(() => _tasks.removeAt(index));
  }

  Future<void> _publishPosting() async {
    if (roleController.text.isEmpty || descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required job details.')));
      return;
    }
    if (_activeDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one active day.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user     = supabase.auth.currentUser;
      if (user == null) return;

      final companyRes = await supabase
          .from('companies')
          .select('id, name')
          .eq('user_id', user.id)
          .single();

      final companyId  = companyRes['id'];
      final colors     = ['#6366F1', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444'];
      final randomColor = colors[DateTime.now().millisecond % colors.length];
      final sortedDays  = _allDays.where((d) => _activeDays.contains(d)).toList();

      await supabase.from('internships').insert({
        'company_id'  : companyId,
        'role'        : roleController.text.trim(),
        'about'       : descController.text.trim(),
        'stipend'     : stipendController.text.trim(),
        'duration'    : durationController.text.trim(),
        'industry'    : 'Software Engineering',
        'location'    : isRemote ? 'Remote' : 'On-site',
        'brand_color' : randomColor,
        'status'      : 'INTERVIEWING',
        'logo_initial': (companyRes['name'] as String).isNotEmpty
            ? (companyRes['name'] as String)[0].toUpperCase()
            : 'C',
        'responsibilities': _tasks,
        'notes'       : notesController.text.trim(),
        'active_days' : sortedDays,
        'application_duration_days': int.tryParse(activeDurationController.text.trim()) ?? 7,
        'deadline'    : DateTime(
          _selectedDeadline.year,
          _selectedDeadline.month,
          _selectedDeadline.day,
        ).toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error publishing posting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('CREATE NEW JOB POST',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('JOB DETAILS'),
                const SizedBox(height: 24),
                _industrialField('JOB TITLE', roleController,
                    hint: 'e.g. Mobile Developer'),
                const SizedBox(height: 20),
                _industrialField('JOB DESCRIPTION', descController,
                    maxLines: 4, hint: 'What will the intern do?'),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                      child: _industrialField('STIPEND (INR)', stipendController,
                          isNumeric: true, hint: 'e.g. 15000')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _industrialField('DURATION (MO)', durationController,
                          isNumeric: true, hint: 'e.g. 06')),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _deadlineField()),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _industrialField('APP ACTIVE DURATION (DAYS)', activeDurationController,
                          isNumeric: true, hint: 'e.g. 7')),
                ]),
                const SizedBox(height: 32),

                // ── Work Location ───────────────────────────────────────
                _sectionLabel('WORK LOCATION'),
                const SizedBox(height: 16),
                _locationOption(),
                const SizedBox(height: 32),

                // ── Days Active ─────────────────────────────────────────
                _sectionLabel('DAYS ACTIVE IN THE WEEK'),
                const SizedBox(height: 8),
                const Text('Select which days interns are expected to be active',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _dayPickerSection(),
                const SizedBox(height: 32),

                // ── Task List ───────────────────────────────────────────
                _sectionLabel('TASK LIST'),
                const SizedBox(height: 8),
                const Text('Add individual tasks the intern will be responsible for',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _taskListSection(),
                const SizedBox(height: 32),

                // ── Notes ───────────────────────────────────────────────
                _sectionLabel('NOTES'),
                const SizedBox(height: 8),
                const Text('Internal notes, special requirements, or any extra info',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _notesField(),
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

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1));

  Widget _taskListSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskInputController,
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Write unit tests for the API',
                      hintStyle: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addTask(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTask,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 5),
                        Text('ADD TASK',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Task items
          if (_tasks.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                return _taskItem(index);
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 16),
              child: Text('No tasks added yet',
                  style: TextStyle(
                      color: const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _taskItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 9,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_tasks[index],
                style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () => _removeTask(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFEF4444), size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: notesController,
            maxLines: 5,
            style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.6),
            decoration: const InputDecoration(
              hintText:
                  'Any special requirements, work culture info, tools used, etc.',
              hintStyle: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w400),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayPickerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:
                _allDays.map((day) => Expanded(child: _dayChip(day))).toList(),
          ),
          if (_activeDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_buildActiveDaySummary(),
                      style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayChip(String day) {
    final isSelected = _activeDays.contains(day);
    final isWeekend  = day == 'Sat' || day == 'Sun';
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _activeDays.remove(day);
        } else {
          _activeDays.add(day);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            day.substring(0, 1),
            style: TextStyle(
                color:
                    isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  String _buildActiveDaySummary() {
    final sorted = _allDays.where((d) => _activeDays.contains(d)).toList();
    if (sorted.length == 7) return 'All days — 7 days/week';
    if (sorted.length == 5 &&
        !_activeDays.contains('Sat') &&
        !_activeDays.contains('Sun')) return 'Monday to Friday — 5 days/week';
    return '${sorted.join(', ')} — ${sorted.length} day${sorted.length == 1 ? '' : 's'}/week';
  }

  Widget _industrialField(String label, TextEditingController controller,
      {int maxLines = 1, bool isNumeric = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric
              ? TextInputType.number
              : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _deadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECTION DEADLINE',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDeadline),
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: Color(0xFF94A3B8), size: 20),
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
      initialDate:
          _selectedDeadline.isBefore(now) ? now : _selectedDeadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDeadline = picked);
  }

  Widget _locationOption() {
    return Row(
      children: [
        _locBtn('Work from Home', isRemote,
            () => setState(() => isRemote = true)),
        const SizedBox(width: 12),
        _locBtn('On-site Office', !isRemote,
            () => setState(() => isRemote = false)),
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
            border: Border.all(
                color: active
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _publishBtn(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _publishPosting,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('PUBLISH JOB POST',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background decorations ────────────────────────────────────────────────────

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
        child: CustomPaint(painter: _DotPainter()),
      );
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
