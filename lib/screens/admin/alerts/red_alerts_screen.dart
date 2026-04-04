import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedAlertsScreen extends StatelessWidget {
  const RedAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Red Alerts',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            )),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), // Very light red
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2), // Light red
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Alert Logic',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF991B1B), // Dark red
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Students who miss 3 consecutive check-ins during an active internship are automatically flagged here requiring your review.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB91C1C), // Medium red
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder(
              future: Supabase.instance.client
                  .from('red_alerts')
                  .select('*, students(name), companies(name)')
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        const Text('Zero Red Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('No students are currently flagged for missing check-ins.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                final items = snapshot.data as List;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final alert = items[index];
                    return _buildAlertCard(
                      studentName: alert['students']?['name'] ?? 'Unknown Student',
                      companyName: alert['companies']?['name'] ?? 'Unknown Company',
                      missedDates: alert['missed_dates'] ?? 'Recent check-ins missed',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({required String studentName, required String companyName, required String missedDates}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF0F172A),
                  radius: 24,
                  child: const Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Interning at $companyName',
                        style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Icon(Icons.event_busy_rounded, size: 14, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Missed check-ins: $missedDates',
                                  style: const TextStyle(
                                    fontSize: 12, 
                                    color: Color(0xFFDC2626), 
                                    fontWeight: FontWeight.w600,
                                  ),
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A), // Slate 900
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Resolve Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
