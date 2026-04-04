import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackModel {
  final String id;
  final String studentName;
  final String companyName;
  final String type; // 'Compliment', 'Complaint', 'Suggestion'
  final String comment;
  final DateTime date;

  FeedbackModel({
    required this.id,
    required this.studentName,
    required this.companyName,
    required this.type,
    required this.comment,
    required this.date,
  });
}

class AdminFeedbacksScreen extends StatefulWidget {
  const AdminFeedbacksScreen({super.key});

  @override
  State<AdminFeedbacksScreen> createState() => _AdminFeedbacksScreenState();
}

class _AdminFeedbacksScreenState extends State<AdminFeedbacksScreen> {
  DateTime _selectedDate = DateTime.now();
  
  List<FeedbackModel> _allFeedbacks = [];
  Map<DateTime, List<FeedbackModel>> _groupedFeedbacks = {};
  List<DateTime> _sortedDates = [];
  Map<DateTime, GlobalKey> _dateKeys = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    try {
      final res = await Supabase.instance.client
          .from('feedbacks')
          .select('*, students(name), companies(name)')
          .order('created_at', ascending: false);
          
      final mapped = (res as List).map((f) {
        return FeedbackModel(
          id: f['id'].toString(),
          studentName: f['students']?['name'] ?? 'Unknown Student',
          companyName: f['companies']?['name'] ?? 'Unknown Company',
          type: f['type'] ?? 'Suggestion',
          comment: f['comment'] ?? '',
          date: DateTime.tryParse(f['created_at'].toString()) ?? DateTime.now(),
        );
      }).toList();

      _allFeedbacks = mapped;

    } catch (e) {
      debugPrint('No feedbacks table or error fetching: $e');
      // If table doesnt exist or errors out, keep list empty as requested
      _allFeedbacks = [];
    }

    if (mounted) {
      setState(() {
        _groupedFeedbacks = {};
        for (var f in _allFeedbacks) {
          final dateOnly = DateTime(f.date.year, f.date.month, f.date.day);
          _groupedFeedbacks.putIfAbsent(dateOnly, () => []).add(f);
        }
        
        _sortedDates = _groupedFeedbacks.keys.toList()..sort((a, b) => b.compareTo(a));
        _dateKeys = {for (var d in _sortedDates) d: GlobalKey()};
        _isLoading = false;
      });
    }
  }

  void _scrollToDate(DateTime date) {
    setState(() => _selectedDate = date);
    
    if (_sortedDates.isEmpty) return;

    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Find the nearest date in our list of feedbacks
    DateTime nearestDate = _sortedDates.first;
    int minDifference = (dateOnly.difference(nearestDate).inDays).abs();

    for (var d in _sortedDates) {
      final diff = (dateOnly.difference(d).inDays).abs();
      if (diff < minDifference) {
        minDifference = diff;
        nearestDate = d;
      }
    }

    if (_dateKeys.containsKey(nearestDate)) {
      final key = _dateKeys[nearestDate];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutQuart,
          alignment: 0.05, // 5% down from the top to allow header spacing
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      _scrollToDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Student Feedbacks',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Calendar Strip ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(DateFormat('MMMM yyyy').format(_selectedDate), 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 18),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE))
                        ),
                        child: Text(
                          _selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month 
                            ? 'Today' 
                            : DateFormat('E, MMM d').format(_selectedDate),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ── Feedbacks List Grouped by Date ──
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _sortedDates.isEmpty
                  ? const _EmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _sortedDates.map((dateKey) {
                        final feedbacksForDate = _groupedFeedbacks[dateKey]!;

                        return Column(
                          key: _dateKeys[dateKey],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12, top: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4, height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, MMMM d').format(dateKey),
                                    style: const TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.w800, 
                                      color: Color(0xFF94A3B8), 
                                      letterSpacing: 0.5
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...feedbacksForDate.map((feedback) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _FeedbackTile(feedback: feedback),
                                )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text('No Feedbacks Received Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text("Students haven't posted any feedback.", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final FeedbackModel feedback;

  const _FeedbackTile({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final bool isCompliment = feedback.type == 'Compliment';
    final bool isComplaint = feedback.type == 'Complaint';
    
    final Color color = isCompliment 
        ? const Color(0xFF10B981) 
        : (isComplaint ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
        
    final IconData icon = isCompliment 
        ? Icons.favorite_rounded 
        : (isComplaint ? Icons.warning_rounded : Icons.lightbulb_rounded);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feedback.studentName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.domain_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(feedback.companyName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feedback.type.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9))
            ),
            child: Text(
              '""${feedback.comment}""',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(DateFormat('hh:mm a').format(feedback.date),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
              const Spacer(),
              _buildActionButton('Reply', Icons.reply_rounded, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _buildActionButton('Resolve', Icons.check_circle_outline_rounded, const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
