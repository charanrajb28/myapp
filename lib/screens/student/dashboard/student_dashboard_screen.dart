import 'package:flutter/material.dart';
import '../internship/my_internship_screen.dart';
import '../student_shell.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              slivers: [
                // ── App bar with greeting ──
                SliverToBoxAdapter(child: _Header()),

                // ── Status banner ──
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(child: _InternshipStatusBanner()),
                ),

                // ── Stat cards ──
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _StatCardGrid(constraints: constraints),
                  ),
                ),

                // ── Quick actions ──
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _QuickActions()),
                ),

                // ── Recent Activity ──
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _RecentActivity()),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: const Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning 👋',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Arjun Mehta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF2563EB),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _InternshipStatusBanner extends StatelessWidget {
  const _InternshipStatusBanner();

  @override
  Widget build(BuildContext context) {
    // Pull the single active internship from shared data
    final active = kStudentInternships.where((i) => i.status == 'Active').toList();
    if (active.isEmpty) {
      return _noActiveInternshipCard(context);
    }
    final intern = active.first;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InternshipDetailScreen(internship: intern),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle light leak effects
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: intern.brandColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              // Main Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Company logo avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Center(
                            child: Text(
                              intern.logoInitial,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                intern.company,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                intern.role,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _activeBadge(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Completion',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(intern.progress * 100).round()}% ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: intern.progress,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [intern.brandColor, intern.brandColor.withValues(alpha: 0.8)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: intern.brandColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _statusChip(Icons.calendar_today_rounded, '${intern.startDate} – ${intern.endDate}'),
                        const SizedBox(width: 12),
                        _statusChip(Icons.timer_outlined, '${intern.daysLeft}d left'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text(
            'ACTIVE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _noActiveInternshipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(children: [
        Icon(Icons.work_off_rounded, size: 32, color: Color(0xFF94A3B8)),
        SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('No Active Internship',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          Text('Check Internships tab for upcoming offers.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _StatCardGrid extends StatelessWidget {
  final BoxConstraints constraints;
  const _StatCardGrid({required this.constraints});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          title: 'Check-ins Done',
          value: '42',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          constraints: constraints,
        ),
        _StatCard(
          title: 'Reports Filed',
          value: '8',
          icon: Icons.article_rounded,
          color: const Color(0xFF3B82F6),
          constraints: constraints,
        ),
        _StatCard(
          title: 'Days Remaining',
          value: '42',
          icon: Icons.hourglass_bottom_rounded,
          color: const Color(0xFFF59E0B),
          constraints: constraints,
        ),
        _StatCard(
          title: 'Alerts',
          value: '0',
          icon: Icons.notifications_none_rounded,
          color: const Color(0xFF64748B),
          constraints: constraints,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final BoxConstraints constraints;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = (constraints.maxWidth - 40 - 12) / 2;

    return Container(
      width: cardWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15, top: -15,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 24),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.0, letterSpacing: -1),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          title: 'Mark Today\'s Check-In',
          subtitle: 'Log your attendance for today',
          icon: Icons.qr_code_scanner_rounded,
          color: const Color(0xFF10B981),
          badge: 'DUE TODAY',
          badgeColor: const Color(0xFF10B981),
          onTap: () => StudentShell.of(context)?.setIndex(2),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Submit Weekly Report',
          subtitle: 'Week 8 report due in 2 days',
          icon: Icons.article_rounded,
          color: const Color(0xFF3B82F6),
          badge: 'WEEK 8',
          badgeColor: const Color(0xFF3B82F6),
          onTap: () => StudentShell.of(context)?.setIndex(3),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'Browse Internships',
          subtitle: 'Explore new opportunities',
          icon: Icons.explore_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => StudentShell.of(context)?.setIndex(1),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'View Consent Letter',
          subtitle: 'Download your authorization document',
          icon: Icons.document_scanner_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => StudentShell.of(context)?.setIndex(1), // Links to internship/documents
        ),

      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor!.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: badgeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  static const _activities = [
    _Activity(
      icon: Icons.check_circle_rounded,
      color: Color(0xFF10B981),
      title: 'Check-in submitted',
      subtitle: 'Today at 9:14 AM',
    ),
    _Activity(
      icon: Icons.article_rounded,
      color: Color(0xFF3B82F6),
      title: 'Week 7 report reviewed',
      subtitle: 'Mar 10 • Reviewed by Admin',
    ),
    _Activity(
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFF59E0B),
      title: 'Mid-term certificate issued',
      subtitle: 'Mar 5 • Download available',
    ),
    _Activity(
      icon: Icons.notifications_rounded,
      color: Color(0xFF8B5CF6),
      title: 'Reminder: Week 8 report due',
      subtitle: 'Due Mar 16',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            separatorBuilder: (_, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
              indent: 60,
            ),
            itemBuilder: (_, i) => _ActivityTile(activity: _activities[i]),
          ),
        ),
      ],
    );
  }
}

class _Activity {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Activity({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _ActivityTile extends StatelessWidget {
  final _Activity activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, color: activity.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
