import 'package:flutter/material.dart';

class CandidatePortfolioScreen extends StatefulWidget {
  final Map<String, dynamic> candidate;
  const CandidatePortfolioScreen({super.key, required this.candidate});

  @override
  State<CandidatePortfolioScreen> createState() => _CandidatePortfolioScreenState();
}

class _CandidatePortfolioScreenState extends State<CandidatePortfolioScreen> {
  void _showRemoveInternDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('REMOVE_INTERN_CMD', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SPECIFY_REASON_FOR_TERMINATION', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter mission termination log...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to postings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.candidate['name']} has been removed from the registry.'),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('CONFIRM_REMOVAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('PORTFOLIO: ${widget.candidate['name'].toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IDENTITY_PULSE ──
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 40, backgroundImage: NetworkImage(widget.candidate['avatar'])),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.candidate['name'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(widget.candidate['college'], style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                          child: const Text('SCH_NODE_ID: 8829-AX', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── PERFORMANCE_CORE ──
            const Text('> PERFORMANCE_INSIGHTS_v2.0', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statBox('RESUME', 'DOWNLOAD_PDF', Icons.description_rounded, const Color(0xFF3B82F6))),
                const SizedBox(width: 12),
                Expanded(child: _statBox('ATTENDANCE', '98.5%', Icons.verified_user_rounded, const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 32),
            _attendanceHeatmap(),

            const SizedBox(height: 48),


            // ── SKILL_MATRIX ──
            const Text('> TECHNICAL_SKILL_BREAKDOWN', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                _skillPulse('Flutter / Dart', 0.95),
                _skillPulse('Firebase Cloud', 0.85),
                _skillPulse('Node.js Backend', 0.70),
                _skillPulse('DevOps Workflow', 0.50),
                _skillPulse('RESTful APIs', 0.90),
                _skillPulse('UI/UX Design', 0.75),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // ── ACTIONS ──
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1E3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('GIVE CERTIFICATE OF EXCELLENCE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _showRemoveInternDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      foregroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('REMOVE INTERN FROM MISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _attendanceHeatmap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ATTENDANCE_LOG_AUDIT (LAST 30 DAYS)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(30, (i) {
               bool absent = i == 7 || i == 14 || i == 21;
               return Container(
                 width: 14, height: 14,
                 decoration: BoxDecoration(
                   color: absent ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.2),
                   borderRadius: BorderRadius.circular(3),
                   border: Border.all(color: absent ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.2)),
                 ),
               );
            }),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text('AVG_LOGIN_TIME: 09:14 AM', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w800)),
              Spacer(),
              Text('STATUS: HIGH_CONSISTENCY', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _skillPulse(String label, double strength) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: strength > 0.7 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
