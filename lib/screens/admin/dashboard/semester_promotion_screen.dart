import 'package:flutter/material.dart';

class SemesterPromotionScreen extends StatefulWidget {
  const SemesterPromotionScreen({super.key});

  @override
  State<SemesterPromotionScreen> createState() => _SemesterPromotionScreenState();
}

class _SemesterPromotionScreenState extends State<SemesterPromotionScreen> {
  // Current active global semester (the "live" one)
  int _activeSem = 2;

  // Student counts per semester (index 0 = Sem 1)
  final List<int> _counts = [162, 158, 154, 149, 145, 141, 138, 124];

  // Track which sems have been promoted in this session (UI feedback)
  final Set<int> _justPromoted = {};

  static const _yearLabel = ['Year 1', 'Year 1', 'Year 2', 'Year 2', 'Year 3', 'Year 3', 'Year 4', 'Year 4'];

  // Total students across all sems
  int get _totalStudents => _counts.fold(0, (a, b) => a + b);

  bool _canPromote(int sem) => sem <= _activeSem && sem < 8;

  void _promoteSem(int sem) {
    if (!_canPromote(sem)) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          sem == 7 ? 'Graduate Semester 7 Students' : 'Promote Semester $sem → Semester ${sem + 1}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sem == 7 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                sem == 7 ? Icons.school_rounded : Icons.arrow_upward_rounded,
                color: sem == 7 ? const Color(0xFFDC2626) : const Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sem == 7
                      ? '${_counts[sem - 1]} students in Sem 7 will be moved to Sem 8 (Final Year).'
                      : '${_counts[sem - 1]} students will move from Semester $sem → Semester ${sem + 1}.',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: sem == 7 ? const Color(0xFFDC2626) : const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text(
            'This action cannot be undone. Please ensure all reports and assessments for Semester $sem are finalised.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _justPromoted.add(sem);
                // Advance active sem if promoting the current active one
                if (sem == _activeSem && _activeSem < 8) _activeSem++;
              });
              Navigator.pop(ctx);
              _showSnack(
                sem == 7
                    ? 'Semester 7 students moved to Semester 8 ✓'
                    : 'Semester $sem students promoted to Semester ${sem + 1} ✓',
                success: true,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: sem == 7 ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(sem == 7 ? 'Move to Sem 8' : 'Promote All'),
          ),
        ],
      ),
    );
  }

  void _promoteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Promote All Active Semesters',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'This will advance every active semester at once. All students in Sem 1 to the current active semester will move up by one.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          ...List.generate(_activeSem, (i) {
            final sem = i + 1;
            if (sem >= 8) return const SizedBox.shrink();
            return _PromoteRow(
              label: sem == 7 ? 'Sem 7 → Sem 8' : 'Sem $sem → Sem ${sem + 1}',
              count: '${_counts[i]} students',
              isLast: sem == _activeSem,
            );
          }),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                for (int s = 1; s <= _activeSem && s < 8; s++) {
                  _justPromoted.add(s);
                }
                if (_activeSem < 8) _activeSem++;
              });
              Navigator.pop(ctx);
              _showSnack('All active semesters promoted successfully ✓', success: true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Promote All Now'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _statusChip(String label, Color color, {bool center = false}) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Semester Promotion',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _promoteAll,
              icon: const Icon(Icons.double_arrow_rounded, size: 16),
              label: const Text('Promote All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              _SummaryStat(label: 'Total Students', value: '$_totalStudents', color: const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              _SummaryStat(label: 'Active Semester', value: 'Sem $_activeSem', color: const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _SummaryStat(label: 'Pending Promotion', value: '${_activeSem < 8 ? _counts[_activeSem - 1] : 0}', color: const Color(0xFFF59E0B)),
            ]),
          ),
          Container(color: const Color(0xFFE2E8F0), height: 1),
          // Sem list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 8,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final sem = i + 1;
                final isActive = sem == _activeSem;
                final isPast = sem < _activeSem;
                final isUpcoming = sem > _activeSem;
                final wasPromoted = _justPromoted.contains(sem);
                final count = _counts[i];
                final canPromote = _canPromote(sem);

                Color statusColor;
                String statusLabel;
                IconData statusIcon;
                if (isActive) {
                  statusColor = const Color(0xFF6366F1);
                  statusLabel = 'Active';
                  statusIcon = Icons.radio_button_checked_rounded;
                } else if (isPast) {
                  statusColor = const Color(0xFF10B981);
                  statusLabel = 'Completed';
                  statusIcon = Icons.check_circle_rounded;
                } else {
                  statusColor = const Color(0xFF94A3B8);
                  statusLabel = 'Upcoming';
                  statusIcon = Icons.schedule_rounded;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6366F1).withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                          : const Color(0xFFE2E8F0),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isActive
                            ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: isActive ? 16 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    // Sem badge
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFFF1F5F9)
                            : statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isPast && !isActive
                            ? Icon(Icons.check_rounded, color: statusColor, size: 22)
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(
                                  'S$sem',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w900,
                                    color: isUpcoming ? const Color(0xFFCBD5E1) : statusColor,
                                  ),
                                ),
                              ]),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Title + status chip — use Wrap to prevent overflow
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Semester $sem',
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: isUpcoming ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(statusIcon, size: 9, color: statusColor),
                              const SizedBox(width: 3),
                              Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _yearLabel[i],
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: isUpcoming ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(
                          Icons.people_alt_rounded, size: 13,
                          color: isUpcoming ? const Color(0xFFCBD5E1) : const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$count students enrolled',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isUpcoming ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ]),
                    ])),
                    const SizedBox(width: 10),
                    // Action button — fixed width so it never overflows
                    SizedBox(
                      width: 76,
                      child: sem == 8
                        ? _statusChip('Final\nSem', const Color(0xFF10B981), center: true)
                        : isUpcoming
                            ? _statusChip('Upcoming', const Color(0xFFCBD5E1))
                            : wasPromoted
                                ? _statusChip('✓ Done', const Color(0xFF10B981))
                                : SizedBox(
                                    width: 76,
                                    child: ElevatedButton(
                                      onPressed: canPromote ? () => _promoteSem(sem) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        disabledBackgroundColor: const Color(0xFFF1F5F9),
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: const Color(0xFFCBD5E1),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      child: const Text('Advance →', textAlign: TextAlign.center),
                                    ),
                                  ),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ]),
      ),
    );
  }
}

class _PromoteRow extends StatelessWidget {
  final String label;
  final String count;
  final bool isLast;
  const _PromoteRow({required this.label, required this.count, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
          fontSize: 13, fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
          color: isLast ? const Color(0xFF6366F1) : const Color(0xFF475569),
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(count, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
        ),
      ]),
    );
  }
}
