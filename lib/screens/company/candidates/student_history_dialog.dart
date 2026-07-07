import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentHistoryDialog extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentHistoryDialog({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentHistoryDialog> createState() => _StudentHistoryDialogState();
}

class _StudentHistoryDialogState extends State<StudentHistoryDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _current = [];
  List<Map<String, dynamic>> _past = [];
  List<Map<String, dynamic>> _applied = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('applications')
          .select('status, created_at, internships(role, start_date, end_date, companies(name))')
          .eq('student_id', widget.studentId);

      final List<Map<String, dynamic>> currentList = [];
      final List<Map<String, dynamic>> pastList = [];
      final List<Map<String, dynamic>> appliedList = [];

      for (var app in (res as List)) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        final internship = app['internships'] as Map<String, dynamic>?;
        if (internship == null) continue;

        final roleName = internship['role'] ?? 'Unknown Role';
        final companyName = internship['companies']?['name'] ?? 'Company';

        final item = {
          'role': roleName,
          'company': companyName,
          'status': app['status'] ?? 'Pending',
        };

        if (status == 'active' || status == 'accepted') {
          currentList.add(item);
        } else if (status == 'completed') {
          pastList.add(item);
        } else if (status == 'applied' || status == 'under review' || status == 'pending') {
          appliedList.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _current = currentList;
          _past = pastList;
          _applied = appliedList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const SizedBox(
          height: 200,
          width: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Internship Registry History',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // TabBar
              TabBar(
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFF6366F1),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                tabs: [
                  Tab(text: 'CURRENT (${_current.length})'),
                  Tab(text: 'APPLIED (${_applied.length})'),
                  Tab(text: 'PAST (${_past.length})'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 16),

              // TabBarView / Content
              Expanded(
                child: _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)))
                    : TabBarView(
                        children: [
                          _buildTabList(_current, const Color(0xFF10B981)),
                          _buildTabList(_applied, const Color(0xFFF59E0B)),
                          _buildTabList(_past, const Color(0xFF6366F1)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabList(List<Map<String, dynamic>> items, Color themeColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 40, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'No records found',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['role'],
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['company'],
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (item['status'] as String).toUpperCase(),
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
