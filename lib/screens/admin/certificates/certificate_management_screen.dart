import 'package:flutter/material.dart';

class CertificateManagementScreen extends StatelessWidget {
  const CertificateManagementScreen({super.key});

  static const _certs = [
    {'student': 'Rahul Kumar',   'id': 'S2020089', 'company': 'FinEdge Corp',       'duration': '6 months', 'status': 'Issued',    'issued': 'Mar 1, 2025'},
    {'student': 'Arjun Mehta',   'id': 'S2021001', 'company': 'TechNova Solutions', 'duration': '3 months', 'status': 'Pending',   'issued': '—'},
    {'student': 'Sneha Roy',     'id': 'S2021055', 'company': 'MediCore Health',     'duration': '6 months', 'status': 'Issued',    'issued': 'Feb 20, 2025'},
    {'student': 'Kiran Joshi',   'id': 'S2022011', 'company': 'DataStream Inc',      'duration': '4 months', 'status': 'Revoked',   'issued': 'Jan 15, 2025'},
    {'student': 'Meera Nair',    'id': 'S2021088', 'company': 'Aero Dynamics Ltd',   'duration': '5 months', 'status': 'Pending',   'issued': '—'},
  ];

  Color _statusColor(String s) {
    switch (s) {
      case 'Issued':  return const Color(0xFF10B981);
      case 'Revoked': return const Color(0xFFEF4444);
      default:        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Certificates',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _certs.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final c = _certs[i];
          final sc = _statusColor(c['status']!);
          return Container(
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
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: sc, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['student']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('${c['id']}  ·  ${c['company']}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(c['duration']!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ]),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c['status']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
                ),
                const SizedBox(height: 6),
                if (c['issued'] != '—')
                  Text('Issued ${c['issued']}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))
                else
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF3B82F6),
                    ),
                    child: const Text('Issue Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
