import 'package:flutter/material.dart';

class ReportsReviewScreen extends StatefulWidget {
  const ReportsReviewScreen({super.key});
  @override
  State<ReportsReviewScreen> createState() => _ReportsReviewScreenState();
}

class _ReportsReviewScreenState extends State<ReportsReviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  static const _weekly = [
    {'student': 'Arjun Mehta',  'week': 'Week 8',  'submitted': 'Mar 3, 2025', 'status': 'Reviewed'},
    {'student': 'Priya Sharma', 'week': 'Week 8',  'submitted': 'Mar 4, 2025', 'status': 'Pending'},
    {'student': 'Rahul Kumar',  'week': 'Week 7',  'submitted': 'Feb 24, 2025','status': 'Reviewed'},
    {'student': 'Dev Patel',    'week': 'Week 8',  'submitted': '—',            'status': 'Missing'},
    {'student': 'Ananya Singh', 'week': 'Week 8',  'submitted': 'Mar 3, 2025', 'status': 'Pending'},
  ];

  static const _monthly = [
    {'student': 'Rahul Kumar',  'month': 'February', 'submitted': 'Mar 1, 2025',  'status': 'Reviewed'},
    {'student': 'Sneha Roy',    'month': 'February', 'submitted': 'Feb 28, 2025', 'status': 'Reviewed'},
    {'student': 'Kiran Joshi',  'month': 'February', 'submitted': '—',             'status': 'Missing'},
    {'student': 'Meera Nair',   'month': 'February', 'submitted': 'Mar 2, 2025',  'status': 'Pending'},
  ];

  Color _sc(String s) {
    switch (s) {
      case 'Reviewed': return const Color(0xFF10B981);
      case 'Missing':  return const Color(0xFFEF4444);
      default:         return const Color(0xFFF59E0B);
    }
  }

  Widget _reportCard(Map<String, String> r) {
    final sc = _sc(r['status']!);
    final sub = r.containsKey('week') ? r['week']! : r['month']!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.article_outlined, color: sc, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['student']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('$sub  ·  Submitted: ${r['submitted']}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(r['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports Review',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(color: const Color(0xFFE2E8F0), height: 1),
            TabBar(
              controller: _tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0F172A),
              indicatorWeight: 2.5,
              tabs: const [Tab(text: 'Weekly'), Tab(text: 'Monthly')],
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: _weekly.map(_reportCard).toList(),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: _monthly.map(_reportCard).toList(),
          ),
        ],
      ),
    );
  }
}
