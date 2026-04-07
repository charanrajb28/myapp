import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'edit_posting_screen.dart';
import '../../../utils/session_expiry_handler.dart';

class PostingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> posting;

  const PostingDetailsScreen({super.key, required this.posting});

  @override
  State<PostingDetailsScreen> createState() => _PostingDetailsScreenState();
}

class _PostingDetailsScreenState extends State<PostingDetailsScreen> {
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  late Map<String, dynamic> _posting;
  List<Map<String, dynamic>> _applications = [];
  final Set<String> _selectedApplicationIds = {};

  @override
  void initState() {
    super.initState();
    _posting = Map<String, dynamic>.from(widget.posting);
    _fetchPostingDetails();
  }

  Future<void> _fetchPostingDetails() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final internshipId = widget.posting['id'];

      final internshipRes = await supabase
          .from('internships')
          .select('*, companies(name)')
          .eq('id', internshipId)
          .single();

      final applicationsRes = await supabase
          .from('applications')
          .select(
            'id, student_id, status, progress, start_date, end_date, '
            'mentor_name, mentor_email, offer_letter_id, created_at, '
            'students(id, name, college, department, semester, contact_email, '
            'phone_number, resume_url, graduation_year, gpa)',
          )
          .eq('internship_id', internshipId)
          .order('created_at', ascending: false);

      final applications = (applicationsRes as List)
          .map((raw) => _applicationViewModel(raw as Map<String, dynamic>))
          .toList();

      final status = _resolvedPostingStatus(internshipRes);
      final postingWithUi = {
        ...internshipRes,
        'status': status,
        'color': _parseColor(internshipRes['brand_color']?.toString()),
        'company_name': internshipRes['companies']?['name'] ?? 'Partner Company',
      };

      if (!mounted) return;
      setState(() {
        _posting = postingWithUi;
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching posting details: $e');
      if (!mounted) return;
      if (SessionExpiryHandler.isSessionExpiredError(e)) {
        setState(() => _isLoading = false);
        await SessionExpiryHandler.showAndRedirect();
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load job details: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Map<String, dynamic> _applicationViewModel(Map<String, dynamic> raw) {
    final student = (raw['students'] as Map<String, dynamic>?) ?? {};
    final status = raw['status']?.toString() ?? 'Applied';
    return {
      'id': raw['id'].toString(),
      'studentId': raw['student_id']?.toString(),
      'name': student['name']?.toString() ?? 'Unknown Student',
      'college': student['college']?.toString() ?? 'College not available',
      'department':
          student['department']?.toString() ?? 'Department not available',
      'semester': student['semester']?.toString() ?? 'Semester not available',
      'email': student['contact_email']?.toString() ?? 'Email not available',
      'phone': student['phone_number']?.toString() ?? 'Phone not available',
      'resumeUrl': student['resume_url']?.toString() ?? 'Resume not uploaded',
      'graduationYear': student['graduation_year']?.toString() ?? '-',
      'gpa': student['gpa']?.toString() ?? '-',
      'status': status,
      'progress': _toDouble(raw['progress']),
      'startDate': raw['start_date']?.toString(),
      'endDate': raw['end_date']?.toString(),
      'mentorName': raw['mentor_name']?.toString() ?? 'Not assigned',
      'mentorEmail': raw['mentor_email']?.toString() ?? 'Not assigned',
      'offerLetterId': raw['offer_letter_id']?.toString() ?? 'Not issued',
      'alerts': List<Map<String, dynamic>>.from(raw['alerts'] ?? []),
      'createdAt': raw['created_at']?.toString(),
    };
  }

  String _resolvedPostingStatus(Map<String, dynamic> posting) {
    return posting['status']?.toString() ?? 'INTERVIEWING';
  }

  Future<void> _updatePostingStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final plannedEndDate = plannedEndDateFromDuration(
        DateTime.now(),
        _posting['duration'],
      );
      final Map<String, dynamic> updateData = {'status': newStatus};
      
      if (newStatus == 'ACTIVE') {
        updateData['start_date'] = today;
        updateData['end_date'] = plannedEndDate;
      } else if (newStatus == 'CLOSED') {
        updateData['end_date'] = today;
      } else if (newStatus == 'INTERVIEWING') {
        updateData['start_date'] = null;
        updateData['end_date'] = null;
      }

      await Supabase.instance.client
          .from('internships')
          .update(updateData)
          .eq('id', _posting['id']);

      if (newStatus == 'ACTIVE') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'status': 'Active',
              'start_date': today,
              'end_date': null,
            })
            .eq('internship_id', _posting['id'])
            .inFilter('status', ['Accepted', 'Active', 'Completed']);
      } else if (newStatus == 'CLOSED') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'end_date': today,
            })
            .eq('internship_id', _posting['id'])
            .eq('status', 'Active');
      } else if (newStatus == 'INTERVIEWING') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'status': 'Accepted',
              'start_date': null,
              'end_date': null,
            })
            .eq('internship_id', _posting['id'])
            .eq('status', 'Active');
      }

      if (!mounted) return;
      setState(() {
        if (newStatus == 'CLOSED') {
          _applications = _applications
              .map(
                (item) => item['status'] == 'Active'
                    ? {
                        ...item,
                        'endDate': today,
                      }
                    : item,
              )
              .toList();
        } else if (newStatus == 'ACTIVE') {
          _applications = _applications
              .map(
                (item) => item['status'] == 'Accepted' ||
                        item['status'] == 'Active' ||
                        item['status'] == 'Completed'
                    ? {
                        ...item,
                        'status': 'Active',
                        'startDate': today,
                        'endDate': null,
                      }
                    : item,
              )
              .toList();
        } else if (newStatus == 'INTERVIEWING') {
          _applications = _applications
              .map(
                (item) => item['status'] == 'Active'
                    ? {
                        ...item,
                        'status': 'Accepted',
                        'startDate': null,
                        'endDate': null,
                      }
                    : item,
              )
              .toList();
        }
        _posting = {
          ..._posting, 
          ...updateData,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job moved to $newStatus'),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update status: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _discardPosting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('DISCARD INTERNSHIP?', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text('This will permanently delete the internship and all associated applications. This action cannot be undone.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('DISCARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('internships')
          .delete()
          .eq('id', _posting['id']);
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to discard internship: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _showBulkAlertDialog() async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('SEND BULK ALERT', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Enter alert message...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          _industrialBtnSmall('SEND', onTap: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true && controller.text.trim().isNotEmpty) {
      await _sendBulkAlert(controller.text.trim());
    }
  }

  Future<void> _sendBulkAlert(String message) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      // Update each selected application
      for (final appId in _selectedApplicationIds) {
        final application = _applications.firstWhere((a) => a['id'] == appId);
        final List<Map<String, dynamic>> currentAlerts = List<Map<String, dynamic>>.from(application['alerts'] ?? []);
        currentAlerts.add({
          'message': message,
          'timestamp': timestamp,
        });

        await Supabase.instance.client
            .from('applications')
            .update({'alerts': currentAlerts})
            .eq('id', appId);
        
        // Local update
        application['alerts'] = currentAlerts;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert sent to ${_selectedApplicationIds.length} candidates'), backgroundColor: const Color(0xFF10B981)),
      );
      setState(() {
        _selectedApplicationIds.clear();
      });
    } catch (e) {
      debugPrint('Error sending bulk alert: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _updateApplicationStatus(
    Map<String, dynamic> application,
    String newStatus,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final updateData = <String, dynamic>{'status': newStatus};

      if (newStatus == 'Active') {
        updateData['start_date'] = today;
        updateData['end_date'] = null;
      } else if (newStatus == 'Accepted' ||
          newStatus == 'Applied' ||
          newStatus == 'Under Review') {
        updateData['start_date'] = null;
        updateData['end_date'] = null;
      } else if (newStatus == 'Removed' ||
          newStatus == 'Rejected' ||
          newStatus == 'Completed') {
        updateData['end_date'] = today;
      }

      await Supabase.instance.client
          .from('applications')
          .update(updateData)
          .eq('id', application['id']);

      if (!mounted) return;
      setState(() {
        _applications = _applications
            .map(
              (item) => item['id'] == application['id']
                  ? {
                      ...item,
                      ...updateData,
                    }
                  : item,
            )
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${application['name']} updated to $newStatus'),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update candidate status: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _sendCertificateToCandidate(Map<String, dynamic> candidate) async {
    try {
      final existingAlerts = List<Map<String, dynamic>>.from(
        candidate['alerts'] ?? const [],
      );
      final alreadySent = existingAlerts.any(
        (item) =>
            item['type']?.toString().toLowerCase() == 'certificate' &&
            item['requires_ack'] == true,
      );

      if (alreadySent) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate alert already sent to this student'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
        return;
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final certificateAlert = <String, dynamic>{
        'id': 'certificate-${candidate['id']}-$now',
        'title': 'Internship Certificate Ready',
        'message':
            'Your internship certificate has been issued by the company. Please confirm once you have received it.',
        'type': 'certificate',
        'status': 'pending',
        'timestamp': now,
        'requires_ack': true,
        'acknowledged': false,
      };

      final updatedAlerts = [...existingAlerts, certificateAlert];

      await Supabase.instance.client
          .from('applications')
          .update({'alerts': updatedAlerts})
          .eq('id', candidate['id']);

      if (!mounted) return;
      setState(() {
        _applications = _applications.map((item) {
          if (item['id'] != candidate['id']) return item;
          return {
            ...item,
            'alerts': updatedAlerts,
          };
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certificate alert sent to ${candidate['name']}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send certificate alert: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  bool _hasPendingCertificateAlert(Map<String, dynamic> candidate) {
    final alerts = List<Map<String, dynamic>>.from(candidate['alerts'] ?? const []);
    return alerts.any(
      (item) =>
          item['type']?.toString().toLowerCase() == 'certificate' &&
          item['requires_ack'] == true &&
          item['acknowledged'] != true,
    );
  }

  bool _hasAcknowledgedCertificateAlert(Map<String, dynamic> candidate) {
    final alerts = List<Map<String, dynamic>>.from(candidate['alerts'] ?? const []);
    return alerts.any(
      (item) =>
          item['type']?.toString().toLowerCase() == 'certificate' &&
          item['acknowledged'] == true,
    );
  }

  String _certificateActionLabel(Map<String, dynamic> candidate) {
    if (_hasAcknowledgedCertificateAlert(candidate)) {
      return 'CERTIFICATE_RECEIVED';
    }
    if (_hasPendingCertificateAlert(candidate)) {
      return 'CERTIFICATE_SENT';
    }
    return 'SEND_CERTIFICATE';
  }

  Color _certificateActionColor(Map<String, dynamic> candidate) {
    if (_hasAcknowledgedCertificateAlert(candidate)) {
      return const Color(0xFF10B981);
    }
    if (_hasPendingCertificateAlert(candidate)) {
      return const Color(0xFF64748B);
    }
    return const Color(0xFF0F172A);
  }

  @override
  Widget build(BuildContext context) {
    final color = _posting['color'] as Color? ?? const Color(0xFF6366F1);
    final status = _posting['status']?.toString() ?? 'INTERVIEWING';
    final responsibilities = _stringList(_posting['responsibilities']);
    final requirements = _stringList(_posting['requirements']);
    final canBulkSelect = status != 'CLOSED' && _applications.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 24,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: 24,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(Icons.work_rounded, color: color, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 45)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_posting['role']?.toString() ?? 'Job Role')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _posting['company_name']?.toString() ??
                              'Partner Company',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _statusChip('STATUS: $status', color),
                            _statusChip(
                              'DEADLINE: ${formatDateLabel(_posting['deadline'])}',
                              const Color(0xFF6366F1),
                            ),
                            _statusChip(
                              '${_applications.length} APPLICATIONS',
                              const Color(0xFF0EA5E9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _bentoParam(
                            'START DATE',
                            status == 'INTERVIEWING' ? 'To be announced' : formatDateLabel(_posting['start_date']),
                            Icons.calendar_today_rounded,
                            const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _bentoParam(
                            'END DATE',
                            status == 'INTERVIEWING' ? 'To be announced' : (status == 'CLOSED' ? formatDateLabel(_posting['end_date']) : 'To be concluded'),
                            Icons.event_busy_rounded,
                            const Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _bentoParam(
                            'STIPEND',
                            _posting['stipend']?.toString() ?? 'Not specified',
                            Icons.payments_rounded,
                            color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _bentoParam(
                            'DURATION',
                            _posting['duration']?.toString() ?? 'Not specified',
                            Icons.timer_rounded,
                            const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _bentoParam(
                            'LOCATION',
                            _posting['location']?.toString() ?? 'Not specified',
                            Icons.place_rounded,
                            const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _bentoParam(
                            'INDUSTRY',
                            _posting['industry']?.toString() ?? 'Not specified',
                            Icons.apartment_rounded,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _narrativeCard(
                        'JOB_SUMMARY',
                        _posting['about']?.toString().trim().isNotEmpty == true
                            ? _posting['about'].toString()
                            : 'No job summary has been added yet.',
                      ),
                      const SizedBox(height: 20),
                      _responsibilitiesCard(
                        'RESPONSIBILITIES',
                        responsibilities.isEmpty
                            ? ['No responsibilities have been added yet.']
                            : responsibilities,
                      ),
                      const SizedBox(height: 20),
                      _responsibilitiesCard(
                        'REQUIREMENTS',
                        requirements.isEmpty
                            ? ['No requirements have been added yet.']
                            : requirements,
                      ),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
                if (canBulkSelect) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '> BATCH_SELECTION_HUB',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedApplicationIds.length ==
                                    _applications.length) {
                                  _selectedApplicationIds.clear();
                                } else {
                                  _selectedApplicationIds.addAll(
                                    _applications.map((c) => c['id'] as String),
                                  );
                                }
                              });
                            },
                            child: Text(
                              _selectedApplicationIds.length ==
                                      _applications.length
                                  ? 'DESELECT_ALL'
                                  : 'SELECT_ALL',
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: _industrialBtnSmall(
                        'SEND_ALERT_TO_SELECTED (${_selectedApplicationIds.length})',
                        onTap: () {
                          if (_selectedApplicationIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select at least one application first.'), backgroundColor: Color(0xFF64748B)),
                            );
                            return;
                          }
                          _showBulkAlertDialog();
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '> APPLICANT_REGISTRY_LOG',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_applications.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyApplicantsCard(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final application = _applications[index];
                          return _CandidateModernTile(
                            candidate: application,
                            isSelected:
                                _selectedApplicationIds.contains(application['id']),
                            showSelection: canBulkSelect,
                            onSelect: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedApplicationIds
                                      .add(application['id'] as String);
                                } else {
                                  _selectedApplicationIds
                                      .remove(application['id'] as String);
                                }
                              });
                            },
                            onTap: () =>
                                _showCandidateDetail(context, application, color),
                          );
                        },
                        childCount: _applications.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            'EDIT',
                            true,
                            color,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditPostingScreen(posting: _posting),
                              ),
                            ).then((_) => _fetchPostingDetails()),
                          ),
                        ),
                        ..._buildPostingStatusActions(status ?? 'INTERVIEWING', color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionBtn(
                            'DISCARD',
                            false,
                            const Color(0xFFEF4444),
                            _discardPosting,
                            isDestructive: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCandidateDetail(
    BuildContext context,
    Map<String, dynamic> candidate,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(
            context,
          ).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.14),
                      accentColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    child: Text(
                      getInitials(candidate['name'] as String),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate['name'] as String,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${candidate['college']} • ${candidate['department']}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 24),
              const Text(
                '> APPLICATION_OVERVIEW',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _applicationOverviewGrid(candidate, accentColor),
              _resumeActionCard(
                context,
                candidate['resumeUrl'] as String,
              ),
              if (candidate['status'] == 'Active' ||
                  candidate['status'] == 'Removed' ||
                  candidate['status'] == 'Completed') ...[
                const SizedBox(height: 32),
                const SizedBox(height: 32),
                _CheckInCalendar(
                  applicationId: candidate['id'] as String,
                  startDate: candidate['startDate']?.toString(),
                ),
                const SizedBox(height: 32),
              ],

              if ((_posting['status']?.toString() ?? 'INTERVIEWING') == 'CLOSED' &&
                  (candidate['status'] == 'Active' ||
                      candidate['status'] == 'Removed' ||
                      candidate['status'] == 'Completed')) ...[
                _actionBtnModal(
                  _certificateActionLabel(candidate),
                  _certificateActionColor(candidate),
                  () {
                    Navigator.pop(context);
                    if (_certificateActionLabel(candidate) ==
                        'SEND_CERTIFICATE') {
                      _sendCertificateToCandidate(candidate);
                    }
                  },
                ),
              ] else if (candidate['status'] == 'Active') ...[
                _actionBtnModal(
                  'REMOVE_CANDIDATE',
                  const Color(0xFFEF4444),
                  () {
                    Navigator.pop(context);
                    _updateApplicationStatus(candidate, 'Removed');
                  },
                ),
              ] else ...[
                _actionBtnModal(
                  (_posting['status']?.toString() ?? 'INTERVIEWING') == 'ACTIVE'
                      ? 'ACTIVATE_CANDIDATE'
                      : 'ACCEPT_CANDIDATE',
                  (_posting['status']?.toString() ?? 'INTERVIEWING') == 'ACTIVE'
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2563EB),
                  () {
                    Navigator.pop(context);
                    _updateApplicationStatus(
                      candidate,
                      (_posting['status']?.toString() ?? 'INTERVIEWING') ==
                              'ACTIVE'
                          ? 'Active'
                          : 'Accepted',
                    );
                  },
                ),
                const SizedBox(height: 12),
                _actionBtnModal(
                  'MOVE_TO_REJECTED',
                  const Color(0xFFEF4444),
                  () {
                    Navigator.pop(context);
                    _updateApplicationStatus(candidate, 'Rejected');
                  },
                ),
                const SizedBox(height: 12),
                _actionBtnModal(
                  'MOVE_TO_UNDER_REVIEW',
                  const Color(0xFF6366F1),
                  () {
                    Navigator.pop(context);
                    _updateApplicationStatus(candidate, 'Under Review');
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _narrativeCard(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> $label',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsibilitiesCard(String label, List<String> duties) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> $label',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: duties
                .map(
                  (duty) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.circle,
                            color: Color(0xFF6366F1),
                            size: 6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            duty,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _bentoParam(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    bool isPrimary,
    Color color,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    final borderColor = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    final bgColor = isPrimary ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isPrimary ? Colors.white : (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPostingStatusActions(String status, Color color) {
    if (_isUpdatingStatus) {
      return [
        const SizedBox(width: 8),
        Expanded(
          child: _actionBtn('UPDATING...', false, color, null),
        ),
      ];
    }

    switch (status) {
      case 'INTERVIEWING':
        return [
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              'MAKE_ACTIVE',
              false,
              color,
              () => _updatePostingStatus('ACTIVE'),
            ),
          ),
        ];
      case 'ACTIVE':
        return [
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              'SET_INTERVIEW',
              false,
              color,
              () => _updatePostingStatus('INTERVIEWING'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              'CLOSE',
              false,
              color,
              () => _updatePostingStatus('CLOSED'),
            ),
          ),
        ];
      case 'CLOSED':
        return [
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              'MAKE_ACTIVE',
              false,
              color,
              () => _updatePostingStatus('ACTIVE'),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _insightRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationOverviewGrid(
    Map<String, dynamic> candidate,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _overviewTile(
                  'Status',
                  candidate['status'] as String? ?? 'Applied',
                  accentColor,
                  Icons.flag_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _overviewTile(
                  'Applied On',
                  formatDateLabel(candidate['createdAt']),
                  const Color(0xFF3B82F6),
                  Icons.event_available_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _overviewTile(
            'Semester',
            candidate['semester'] as String? ?? 'Semester not available',
            const Color(0xFF8B5CF6),
            Icons.school_rounded,
          ),
        ],
      ),
    );
  }

  Widget _overviewTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeActionCard(BuildContext context, String resumeUrl) {
    final normalized = resumeUrl.trim();
    final hasResume =
        normalized.isNotEmpty &&
        normalized.toLowerCase() != 'resume not uploaded';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF0F172A),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESUME',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Open the saved resume for this applicant.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: hasResume
                    ? () => _openResume(context, normalized)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  hasResume ? 'VIEW RESUME' : 'NOT UPLOADED',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openResume(BuildContext context, String resumeUrl) async {
    final uri = Uri.tryParse(resumeUrl);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume link is invalid.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the resume file.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _industrialBtnSmall(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
  Widget _actionBtnModal(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _deepMetric(String label, String status, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Flexible(
              child: Text(
                status,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

}

String getInitials(String name) {
  final parts = name.split(' ').where((p) => p.trim().isNotEmpty).take(2).toList();
  if (parts.isEmpty) return '?';
  return parts.map((p) => p[0].toUpperCase()).join();
}

String formatDateLabel(dynamic value) {
  if (value == null) return 'Not set';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int durationMonths(dynamic rawDuration) {
  final value = rawDuration?.toString().trim() ?? '';
  final match = RegExp(r'\d+').firstMatch(value);
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

String? plannedEndDateFromDuration(DateTime startDate, dynamic rawDuration) {
  final months = durationMonths(rawDuration);
  if (months <= 0) {
    return null;
  }

  final plannedEnd = DateTime(
    startDate.year,
    startDate.month + months,
    startDate.day,
  );
  return plannedEnd.toIso8601String().split('T')[0];
}

_StatusMeta getStatusMeta(String status) {
  switch (status) {
    case 'Accepted':
      return const _StatusMeta(color: Color(0xFF2563EB), backgroundColor: Color(0xFFEFF6FF), icon: Icons.verified_rounded);
    case 'Active':
      return const _StatusMeta(color: Color(0xFF10B981), backgroundColor: Color(0xFFF0FDF4), icon: Icons.check);
    case 'Rejected':
      return const _StatusMeta(color: Color(0xFFEF4444), backgroundColor: Color(0xFFFEF2F2), icon: Icons.close);
    case 'Under Review':
      return const _StatusMeta(color: Color(0xFF6366F1), backgroundColor: Color(0xFFEEF2FF), icon: Icons.visibility_rounded);
    case 'Completed':
      return const _StatusMeta(color: Color(0xFF0EA5E9), backgroundColor: Color(0xFFF0F9FF), icon: Icons.workspace_premium_rounded);
    default:
      return const _StatusMeta(color: Color(0xFF64748B), backgroundColor: Colors.white, icon: Icons.schedule_rounded);
  }
}

class _StatusMeta {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  const _StatusMeta({required this.color, required this.backgroundColor, required this.icon});
}

class _CheckInCalendar extends StatefulWidget {
  final String applicationId;
  final String? startDate;
  const _CheckInCalendar({required this.applicationId, this.startDate});

  @override
  State<_CheckInCalendar> createState() => _CheckInCalendarState();
}

class _CheckInCalendarState extends State<_CheckInCalendar> {
  DateTime _viewDate = DateTime.now();
  List<Map<String, dynamic>> _checkins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCheckins();
  }

  Future<void> _fetchCheckins() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('applications')
          .select('checkins')
          .eq('id', widget.applicationId)
          .maybeSingle();

      final rawCheckins = (res?['checkins'] as List?) ?? const [];
      final monthPrefix =
          '${_viewDate.year.toString().padLeft(4, '0')}-${_viewDate.month.toString().padLeft(2, '0')}';
        final parsedCheckins = rawCheckins
            .whereType<Map>()
            .map(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
          )
          .where(
            (item) =>
                (item['checkin_date']?.toString() ?? '').startsWith(monthPrefix),
          )
          .toList();

      if (mounted) {
        setState(() {
          _checkins = parsedCheckins;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching checkins: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    final firstDayWeekday = DateTime(_viewDate.year, _viewDate.month, 1).weekday;
    
    // Adjust for Monday start (weekday is 1-7, Mon-Sun)
    final paddingDays = firstDayWeekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '> APPLICATION_CHECKINS',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1));
                    _fetchCheckins();
                  },
                  icon: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF64748B)),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_viewDate).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1));
                    _fetchCheckins();
                  },
                  icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2)))
            : Table(
                children: [
                   _buildTableWeekDays(),
                   ..._buildCalendarRows(paddingDays, daysInMonth),
                ],
              ),
        ),
      ],
    );
  }

  TableRow _buildTableWeekDays() {
    final labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return TableRow(
      children: labels.map((l) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      )).toList(),
    );
  }

  List<TableRow> _buildCalendarRows(int padding, int days) {
    final List<TableRow> rows = [];
    final List<Widget> items = [];

    // Padding for empty start
    for (int i = 0; i < padding; i++) {
        items.add(const SizedBox.shrink());
    }

    // Days
    for (int day = 1; day <= days; day++) {
        final date = DateTime(_viewDate.year, _viewDate.month, day);
        final dateStr = date.toIso8601String().split('T')[0];
        final checkin = _checkins.firstWhere(
          (c) => c['checkin_date'] == dateStr,
          orElse: () => {},
        );
        final isAbsent = _isMissedCheckinDay(date, checkin);

        items.add(
          _CalendarDay(
            day: day,
            status: checkin['status'],
            isAbsent: isAbsent,
          ),
        );
    }

    // Grid split by weeks (7 days)
    for (int i = 0; i < items.length; i += 7) {
        final end = (i + 7 > items.length) ? items.length : i + 7;
        final weekItems = items.sublist(i, end);
        while (weekItems.length < 7) {
            weekItems.add(const SizedBox.shrink());
        }
        rows.add(TableRow(children: weekItems));
    }

    return rows;
  }

  bool _isMissedCheckinDay(DateTime date, Map<dynamic, dynamic> checkin) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }

    final startDate = _parseDate(widget.startDate);
    if (startDate == null) {
      return false;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (normalizedDate.isBefore(normalizedStart) ||
        normalizedDate.isAfter(normalizedToday)) {
      return false;
    }

    final status = checkin['status']?.toString().toLowerCase();
    final hasCheckIn = checkin['check_in_at'] != null;

    if (hasCheckIn || status == 'present') {
      return false;
    }

    return checkin.isEmpty || status == 'absent';
  }

  DateTime? _parseDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == 'null') {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final match = RegExp(r'^(\d{1,2}) ([A-Za-z]{3}) (\d{4})$').firstMatch(value);
    if (match == null) {
      return null;
    }

    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final day = int.tryParse(match.group(1) ?? '');
    final month = months[match.group(2)];
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final dynamic status;
  final bool isAbsent;
  const _CalendarDay({required this.day, this.status, this.isAbsent = false});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.transparent;
    Color textColor = const Color(0xFF0F172A);
    bool isMarked = false;

    if (status == 'Present') {
        color = const Color(0xFF10B981);
        textColor = Colors.white;
        isMarked = true;
    } else if (status == 'Absent' || isAbsent) {
        color = const Color(0xFFEF4444);
        textColor = Colors.white;
        isMarked = true;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: !isMarked ? Border.all(color: const Color(0xFFE2E8F0), width: 1) : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateIndustrialTile extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final bool isSelected;
  final bool showSelection;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onTap;

  const _CandidateIndustrialTile({
    required this.candidate,
    required this.onTap,
    required this.isSelected,
    required this.showSelection,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final status = candidate['status'] as String? ?? 'Applied';
    final statusUi = _statusMeta(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusUi.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: statusUi.color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusUi.color.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showSelection) ...[
              Checkbox(
                value: isSelected,
                onChanged: onSelect,
                activeColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusUi.color.withValues(alpha: 0.12),
                  child: Text(
                    getInitials(candidate['name'] as String),
                    style: TextStyle(
                      color: statusUi.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: statusUi.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(statusUi.icon, color: Colors.white, size: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate['name'] as String,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${candidate['college']} • ${candidate['department']}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusUi.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusUi.color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _CandidateModernTile extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final bool isSelected;
  final bool showSelection;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onTap;

  const _CandidateModernTile({
    required this.candidate,
    required this.onTap,
    required this.isSelected,
    required this.showSelection,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final status = candidate['status'] as String? ?? 'Applied';
    final statusUi = _statusMeta(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusUi.color.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusUi.color.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                if (showSelection) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelect,
                    activeColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: statusUi.color.withValues(alpha: 0.12),
                      child: Text(
                        getInitials(candidate['name'] as String),
                        style: TextStyle(
                          color: statusUi.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: statusUi.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(statusUi.icon, color: Colors.white, size: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate['name'] as String,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${candidate['college']} • ${candidate['department']}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusUi.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusUi.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metaPill(
                    Icons.school_rounded,
                    candidate['semester'] as String? ?? 'Semester not set',
                    const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metaPill(
                    Icons.event_available_rounded,
                    formatDateLabel(candidate['createdAt']),
                    const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _metaPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'Accepted':
      return const _StatusMeta(
        color: Color(0xFF2563EB),
        backgroundColor: Color(0xFFEFF6FF),
        icon: Icons.verified_rounded,
      );
    case 'Active':
      return const _StatusMeta(
        color: Color(0xFF10B981),
        backgroundColor: Color(0xFFF0FDF4),
        icon: Icons.check,
      );
    case 'Removed':
      return const _StatusMeta(
        color: Color(0xFF7C3AED),
        backgroundColor: Color(0xFFF5F3FF),
        icon: Icons.person_remove_alt_1_rounded,
      );
    case 'Rejected':
      return const _StatusMeta(
        color: Color(0xFFEF4444),
        backgroundColor: Color(0xFFFEF2F2),
        icon: Icons.close,
      );
    case 'Under Review':
      return const _StatusMeta(
        color: Color(0xFF6366F1),
        backgroundColor: Color(0xFFEEF2FF),
        icon: Icons.visibility_rounded,
      );
    case 'Completed':
      return const _StatusMeta(
        color: Color(0xFF0EA5E9),
        backgroundColor: Color(0xFFF0F9FF),
        icon: Icons.workspace_premium_rounded,
      );
    default:
      return const _StatusMeta(
        color: Color(0xFF64748B),
        backgroundColor: Colors.white,
        icon: Icons.schedule_rounded,
      );
  }
}


class _EmptyApplicantsCard extends StatelessWidget {
  const _EmptyApplicantsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.groups_rounded,
            size: 42,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'No applications yet',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Applications for this internship will appear here once students apply.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect),
      child: CustomPaint(painter: _DotPainter()),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
