import 'package:flutter/material.dart';

class ConsentLettersScreen extends StatelessWidget {
  const ConsentLettersScreen({super.key});

  static const _letters = [
    {'student': 'Arjun Mehta',       'id': 'S2021001', 'company': 'TechNova Solutions', 'status': 'Generated',  'date': 'Mar 3, 2025'},
    {'student': 'Priya Sharma',      'id': 'S2021042', 'company': 'Aero Dynamics Ltd',  'status': 'Pending',    'date': 'Mar 4, 2025'},
    {'student': 'Rahul Kumar',       'id': 'S2020089', 'company': 'FinEdge Corp',        'status': 'Signed',     'date': 'Feb 28, 2025'},
    {'student': 'Ananya Singh',      'id': 'S2021117', 'company': 'MediCore Health',     'status': 'Generated',  'date': 'Mar 1, 2025'},
    {'student': 'Dev Patel',         'id': 'S2022003', 'company': 'DataStream Inc',      'status': 'Revoked',    'date': 'Feb 25, 2025'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Consent Letters',
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
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Generate', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _letters.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final l = _letters[i];
          return _LetterCard(letter: l);
        },
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final Map<String, String> letter;
  const _LetterCard({required this.letter});

  Color get _statusColor {
    switch (letter['status']) {
      case 'Signed':     return const Color(0xFF10B981);
      case 'Generated':  return const Color(0xFF3B82F6);
      case 'Revoked':    return const Color(0xFFEF4444);
      default:           return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: Color(0xFF0F172A), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(letter['student']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text('${letter['id']}  ·  ${letter['company']}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(letter['date']!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(letter['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              _iconBtn(Icons.visibility_outlined, () {}),
              const SizedBox(width: 6),
              _iconBtn(Icons.download_rounded, () {}),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF475569)),
    ),
  );
}
