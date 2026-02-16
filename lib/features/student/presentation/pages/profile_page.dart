import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: _ProfileHeaderDelegate(),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                children: [
                  _buildSectionCard(
                    context,
                    title: 'About Me',
                    child: const Text(
                      'A passionate software engineer with a love for creating beautiful and functional mobile applications.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSkillsSection(context, ['Flutter', 'Dart', 'Firebase', 'UI/UX Design']),
                  const SizedBox(height: 16),
                  _buildResumeSection(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(height: 1.5, color: Colors.grey[700]),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context, List<String> skills) {
    return _buildSectionCard(
      context,
      title: 'Skills',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map((skill) => Chip(label: Text(skill))).toList(),
      ),
    );
  }

  Widget _buildResumeSection(BuildContext context) {
    final theme = Theme.of(context);
    return _buildSectionCard(
      context,
      title: 'Resume',
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'jane_doe_resume.pdf',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated: July 15, 2024',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {},
            tooltip: 'Download',
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const _maxHeaderExtent = 320.0;
  static const _minHeaderExtent = 180.0;
  static const _maxAvatarRadius = 60.0;
  static const _minAvatarRadius = 30.0;
  static const _maxStatsExtent = 80.0;
  static const _minStatsExtent = 50.0;

  @override
  double get maxExtent => _maxHeaderExtent;

  @override
  double get minExtent => _minHeaderExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final progress = min(1.0, shrinkOffset / (_maxHeaderExtent - _minHeaderExtent));

    final double avatarRadius = (1 - progress) * _maxAvatarRadius + progress * _minAvatarRadius;
    final double statsExtent = (1 - progress) * _maxStatsExtent + progress * _minStatsExtent;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // Background Cover Image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const NetworkImage('https://images.unsplash.com/photo-1579546929518-9e396f3a8034?w=1200&q=80'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.primary.withOpacity(0.6 + (progress * 0.2)),
                BlendMode.dstATop,
              ),
            ),
          ),
        ),
        // Title and Settings button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Opacity(
              opacity: progress,
              child: const Text("Jane's Profile"),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                onPressed: () => context.go('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
        // Profile Info
        Positioned(
          top: (minExtent - statsExtent) / 2 - avatarRadius + 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundImage: const NetworkImage('https://randomuser.me/api/portraits/women/68.jpg'),
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: 1.0 - progress,
                child: Column(
                  children: [
                    Text(
                      'Jane',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [const Shadow(blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Software Engineer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        shadows: [const Shadow(blurRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Stats Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: statsExtent,
            color: theme.scaffoldBackgroundColor,
            child: _buildStatsRow(context, progress),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, double progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStatItem(context, Icons.work_outline, '5', 'Internships', progress),
        _buildStatItem(context, Icons.file_copy_outlined, '12', 'Applications', progress),
        _buildStatItem(context, Icons.verified_outlined, '4', 'Certificates', progress),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label, double progress) {
    final theme = Theme.of(context);
    final double iconSize = (1 - progress) * 28.0 + progress * 24.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: iconSize),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: progress > 0.5 ? 0 : 4),
        Opacity(
          opacity: 1.0 - progress,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
