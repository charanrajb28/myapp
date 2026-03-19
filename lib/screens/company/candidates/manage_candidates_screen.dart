import 'package:flutter/material.dart';

class ManageCandidatesScreen extends StatelessWidget {
  const ManageCandidatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Applications', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded, color: Color(0xFF64748B)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _dummyApplicants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _CandidateCard(applicant: _dummyApplicants[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'New', 'Shortlisted', 'Rejected', 'Hired'];
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilterChip(
            label: Text(filters[index]),
            selected: index == 0,
            onSelected: (_) {},
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFF0F172A),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: index == 0 ? Colors.white : const Color(0xFF64748B),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> applicant;
  const _CandidateCard({required this.applicant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: (applicant['color'] as Color).withValues(alpha: 0.1),
                child: Text(
                  applicant['initials'],
                  style: TextStyle(fontWeight: FontWeight.w900, color: applicant['color']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(applicant['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(applicant['targetRole'], style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: (applicant['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(applicant['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: applicant['color'])),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info(Icons.school_outlined, applicant['college']),
              _info(Icons.calendar_today_outlined, applicant['appliedDate']),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('VIEW RESUME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF020617),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SHORTLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

final _dummyApplicants = [
  {
    'name': 'Rahul Sharma',
    'initials': 'RS',
    'targetRole': 'Full Stack Developer',
    'college': 'IIT Delhi',
    'appliedDate': '2h ago',
    'status': 'NEW',
    'color': const Color(0xFF6366F1),
  },
  {
    'name': 'Ananya Iyer',
    'initials': 'AI',
    'targetRole': 'UI/UX Design',
    'college': 'NID Ahmedabad',
    'appliedDate': 'Yesterday',
    'status': 'REVIEWED',
    'color': const Color(0xFF10B981),
  },
  {
    'name': 'Vikram Singh',
    'initials': 'VS',
    'targetRole': 'DevOps Intern',
    'college': 'VIT Vellore',
    'appliedDate': '2 days ago',
    'status': 'PENDING',
    'color': const Color(0xFF8B5CF6),
  },
];
