import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SemesterPromotionScreen extends StatefulWidget {
  const SemesterPromotionScreen({super.key});

  @override
  State<SemesterPromotionScreen> createState() => _SemesterPromotionScreenState();
}

class _SemesterPromotionScreenState extends State<SemesterPromotionScreen> {
  bool _isLoading = true;
  
  // Student counts map: { "1st Semester": 10, "2nd Semester": 5, ... }
  final Map<String, int> _semesterCounts = {
    '1st Semester': 0,
    '2nd Semester': 0,
    '3rd Semester': 0,
    '4th Semester': 0,
    '5th Semester': 0,
    '6th Semester': 0,
  };

  final List<String> _semesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSemesterData();
  }

  Future<void> _fetchSemesterData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('students').select('semester');
      
      // Reset counts
      _semesterCounts.updateAll((key, value) => 0);
      
      for (var row in response) {
        final sem = row['semester'] as String?;
        if (sem != null && _semesterCounts.containsKey(sem)) {
          _semesterCounts[sem] = (_semesterCounts[sem] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint('Error fetching semester data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promoteSemester(String currentSem) async {
    final currentIndex = _semesters.indexOf(currentSem);
    if (currentIndex == -1) return;

    final targetSem = (currentIndex < _semesters.length - 1) 
        ? _semesters[currentIndex + 1] 
        : 'Completed (Alumni)';
    
    final count = _semesterCounts[currentSem] ?? 0;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Promote $currentSem?'),
        content: Text('This will move $count students from $currentSem → $targetSem.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promote Now')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('students')
            .update({'semester': targetSem})
            .eq('semester', currentSem);
            
        _fetchSemesterData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully promoted $currentSem to $targetSem!'))
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to promote: $e'), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _promoteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Global Semester Promotion?'),
        content: const Text('Every active student (Sem 1 to 5) will advance by one semester. Sem 6 students will be marked as Completed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promote ALL Students')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final supabase = Supabase.instance.client;
        
        // We go BACKWARDS from 6 to 1 to avoid double-promoting
        for (int i = _semesters.length - 1; i >= 0; i--) {
          final current = _semesters[i];
          final target = (i < _semesters.length - 1) ? _semesters[i+1] : 'Completed (Alumni)';
          
          await supabase
              .from('students')
              .update({'semester': target})
              .eq('semester', current);
        }

        _fetchSemesterData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Global promotion complete! All students advanced.'))
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Global promotion failed: $e'), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6366F1);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('System Promotion', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _promoteAll,
            icon: const Icon(Icons.double_arrow_rounded),
            label: const Text('Promote ALL'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildStatCard('Total Active', _semesterCounts.values.fold(0, (a, b) => a + b).toString(), primaryColor),
                      const SizedBox(width: 16),
                      _buildStatCard('Last Sync', 'Just now', const Color(0xFF10B981)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _semesters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final sem = _semesters[index];
                      final count = _semesterCounts[sem] ?? 0;
                      
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              child: Text(sem.substring(0, 1), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sem, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  Text('$count students enrolled', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: count > 0 ? () => _promoteSemester(sem) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Advance →'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
