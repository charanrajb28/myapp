import 'package:flutter/material.dart';
import '../../../models/internship.dart';
import '../internship/my_internship_screen.dart';
import '../internship/student_internship_detail_screen.dart';
import '../internship/student_internship_alerts_screen.dart';
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

                // ── Internship Carousel ──
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(child: _InternshipCarousel()),


                // ── Quick actions ──
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _QuickActions()),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),
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
class _InternshipCarousel extends StatefulWidget {
  const _InternshipCarousel();

  @override
  State<_InternshipCarousel> createState() => _InternshipCarouselState();
}

class _InternshipCarouselState extends State<_InternshipCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = kStudentInternships.where((i) => i.status == 'Active').toList();
    
    if (active.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _noActiveInternshipCard(context),
      );
    }

    final currentIntern = active[_currentPage];

    return Column(
      children: [
        // Top Carousel: Company Header
        SizedBox(
          height: 160, // Increased height to prevent vertical overflow with more details
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: active.length,
            itemBuilder: (context, index) {
              final intern = active[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentInternshipDetailScreen(internship: intern),
                          ),
                        );
                      },
                      child: _CompanyHeaderCard(internship: intern),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (active.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              active.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Bottom Section: 3 Stat Cards (Linked to Selection)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SmallStatCard(
                      title: 'Check-ins',
                      value: '42',
                      icon: Icons.qr_code_scanner_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => StudentShell.of(context)?.setIndex(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SmallStatCard(
                      title: 'Alerts',
                      value: '2',
                      icon: Icons.error_outline_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentInternshipAlertsScreen(internship: currentIntern),
                          ),
                        );
                      },
                    ),
                  ),


                ],
              ),
              const SizedBox(height: 14),
              _LargeStatCard(
                title: 'Days Remaining',
                value: '${currentIntern.daysLeft}',
                icon: Icons.hourglass_bottom_rounded,
                color: const Color(0xFFF59E0B),
                onAction: null, // Disabled
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noActiveInternshipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.work_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'No Active Internship',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check Internships tab for upcoming offers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeaderCard extends StatelessWidget {
  final StudentInternship internship;
  const _CompanyHeaderCard({required this.internship});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),

      child: Stack(
        children: [
          // Subtle background decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Logo Container with glassmorphism style
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Text(
                      internship.logoInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _activeBadge(),
                          const SizedBox(width: 8),
                          Text(
                            internship.id,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        internship.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        internship.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // New details row
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              internship.location,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.payments_rounded, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              internship.stipend,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;

  const _LargeStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'SUBMIT FINAL REPORT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                    ),
                  ),


                ],
              ),
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
          title: 'View Notifications',
          subtitle: 'You have 2 unread alerts',
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF3B82F6),
          badge: 'NEW',
          badgeColor: const Color(0xFFEF4444),
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
        color: color.withValues(alpha: 0.03), // Subtle shade
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
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
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF3B82F6),
      title: 'New Grade Published',
      subtitle: '2 hours ago • Industrial Training Phase 1',
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
      title: 'Company Visit Scheduled',
      subtitle: 'Upcoming on Mar 25',
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
