import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../candidates/candidate_portfolio_screen.dart';
import '../candidates/student_history_dialog.dart';

class PostingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> posting;
  const PostingDetailsScreen({super.key, required this.posting});

  @override
  State<PostingDetailsScreen> createState() => _PostingDetailsScreenState();
}

class _PostingDetailsScreenState extends State<PostingDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _applicants = [];
  int _tabIndex = 0;
  late Map<String, dynamic> _posting;

  List<Map<String, dynamic>> get _displayedApplicants {
    final jobStatus = (_posting['status'] ?? 'INTERVIEWING').toString().toUpperCase();
    if (jobStatus == 'ACTIVE') {
      return _applicants.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'active' || status == 'removed';
      }).toList();
    }
    return _applicants;
  }

  @override
  void initState() {
    super.initState();
    _posting = Map<String, dynamic>.from(widget.posting);
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      // Fetch applications along with student profiles
      final res = await supabase
          .from('applications')
          .select('*, students(*)')
          .eq('internship_id', _posting['id'])
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _applicants = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching applicants: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': newStatus})
          .eq('id', applicationId);
      
      _fetchApplicants();
    } catch (e) {
      debugPrint('Error updating application status: $e');
    }
  }

  Future<void> _updateJobStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final oldStatus = _posting['status'] ?? 'INTERVIEWING';
      
      // 1. Update the internships table status
      await supabase
          .from('internships')
          .update({'status': newStatus})
          .eq('id', _posting['id']);
          
      // 2. Perform applicant status conversions
      if (newStatus == 'ACTIVE' && oldStatus == 'INTERVIEWING') {
        await supabase
            .from('applications')
            .update({
              'status': 'Active',
              'start_date': DateTime.now().toIso8601String().split('T')[0]
            })
            .eq('internship_id', _posting['id'])
            .eq('status', 'Accepted');
      } else if (newStatus == 'INTERVIEWING') {
        await supabase
            .from('applications')
            .update({
              'status': 'Applied',
              'start_date': null
            })
            .eq('internship_id', _posting['id']);
      }
      
      // Update local state
      setState(() {
        _posting['status'] = newStatus;
      });
      
      // 3. Fetch applicants again to sync lists
      await _fetchApplicants();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job transitioned to ${newStatus.toUpperCase()} successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating job status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transition job status: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRemoveInternDialog(String applicationId, String candidateName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('REMOVE INTERN FROM MISSION', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SPECIFY REASON FOR TERMINATION', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter mission termination log...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _updateApplicationStatus(applicationId, 'Removed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$candidateName has been removed from the registry.'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('CONFIRM REMOVAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> _issueCertificate(String applicationId, String candidateName, String certificateUrl) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // Fetch existing alerts to prevent overwriting
      final appRes = await supabase
          .from('applications')
          .select('alerts')
          .eq('id', applicationId)
          .maybeSingle();
          
      List<dynamic> currentAlerts = [];
      if (appRes != null && appRes['alerts'] != null) {
        currentAlerts = List<dynamic>.from(appRes['alerts']);
      }
      
      // Create the certificate alert
      final newAlert = {
        'id': 'cert-alert-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Certificate of Excellence Issued',
        'message': 'Congratulations! Your Certificate of Excellence has been issued by ${widget.posting['companies']?['name'] ?? 'the company'}. You can view or download it here: $certificateUrl',
        'type': 'success',
        'status': 'completed',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'requires_ack': true,
        'acknowledged': false,
        'certificate_url': certificateUrl,
      };
      
      currentAlerts.add(newAlert);
      
      // Update application
      await supabase
          .from('applications')
          .update({
            'status': 'Completed',
            'alerts': currentAlerts,
          })
          .eq('id', applicationId);
          
      await _fetchApplicants();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate of Excellence issued to $candidateName!'),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error issuing certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue certificate: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showIssueCertificateDialog(String applicationId, String candidateName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ISSUE CERTIFICATE OF EXCELLENCE', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ENTER CERTIFICATE GOOGLE DRIVE LINK', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'https://drive.google.com/file/d/...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = controller.text.trim();
              if (link.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid certificate link.'),
                    backgroundColor: Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(context); // Close dialog
              await _issueCertificate(applicationId, candidateName, link);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ISSUE NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _posting['color'] as Color? ?? const Color(0xFF6366F1);
    final role = _posting['role']?.toString() ?? 'Unknown Role';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, color, role),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color, String role) {
    final status = _posting['status'] ?? 'INTERVIEWING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white70),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const Spacer(),
              _statusChip(status, color),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(Icons.work_rounded, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          'POSTED ${_formatDate(_posting['created_at'])}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 20),
          _buildJobStatusActionBar(status),
        ],
      ),
    );
  }

  Widget _buildJobStatusActionBar(String status) {
    status = status.toUpperCase();
    if (status == 'INTERVIEWING') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _updateJobStatus('ACTIVE'),
          icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
          label: const Text(
            'START MISSION (ACTIVATE)',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), // Emerald 500
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    } else if (status == 'ACTIVE') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _updateJobStatus('INTERVIEWING'),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text(
                  'REVERT TO INTERVIEW',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  foregroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus('CLOSED'),
                icon: const Icon(Icons.cancel_rounded, size: 18),
                label: const Text(
                  'CLOSE MISSION',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'CLOSED') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _updateJobStatus('INTERVIEWING'),
                icon: const Icon(Icons.people_outline_rounded, size: 18),
                label: const Text(
                  'INTERVIEWING',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                  foregroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus('ACTIVE'),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'REOPEN MISSION',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContent(Color color) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              _tabButton(0, 'APPLICANTS', _displayedApplicants.length.toString()),
              const SizedBox(width: 16),
              _tabButton(1, 'DESCRIPTION', null),
            ],
          ),
        ),
        Expanded(
          child: _tabIndex == 0 ? _buildApplicantsList(color) : _buildDescription(color),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, String? count) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsList(Color color) {
    final list = _displayedApplicants;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'NO APPLICANTS YET',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    final jobStatus = _posting['status'] ?? 'INTERVIEWING';

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final app = list[index];
        final student = app['students'] as Map<String, dynamic>?;
        final name = student?['name'] ?? 'Candidate';
        final status = app['status'] ?? 'Applied';
        
        final avatarColor = _getAvatarColor(name);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: avatarColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildApplicantStatusChip(status),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => StudentHistoryDialog(
                          studentId: student?['id'] ?? '',
                          studentName: name,
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, color: Color(0xFF6366F1), size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCandidateActionButtons(jobStatus, status, app['id'], name),
            ],
          ),
        );
      },
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  Widget _buildApplicantStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'applied':
        color = const Color(0xFF3B82F6); // Blue
        break;
      case 'accepted':
        color = const Color(0xFF10B981); // Emerald
        break;
      case 'active':
        color = const Color(0xFF06B6D4); // Cyan
        break;
      case 'completed':
        color = const Color(0xFFD97706); // Amber/Gold
        break;
      case 'rejected':
        color = const Color(0xFFEF4444); // Red
        break;
      case 'removed':
        color = const Color(0xFF7F1D1D); // Dark Red
        break;
      default:
        color = const Color(0xFF64748B); // Slate
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCandidateActionButtons(String jobStatus, String status, String applicationId, String name) {
    jobStatus = jobStatus.toUpperCase();
    
    if (jobStatus == 'INTERVIEWING') {
      if (status == 'Applied' || status == 'Under Review') {
        return Row(
          children: [
            Expanded(
              child: _actionBtn(
                'REJECT',
                const Color(0xFFEF4444),
                () => _updateApplicationStatus(applicationId, 'Rejected'),
                false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionBtn(
                'ACCEPT',
                const Color(0xFF10B981),
                () => _updateApplicationStatus(applicationId, 'Accepted'),
                false,
              ),
            ),
          ],
        );
      } else if (status == 'Accepted') {
        return Row(
          children: [
            Expanded(
              child: _actionBtn(
                'REJECT',
                const Color(0xFFEF4444),
                () => _updateApplicationStatus(applicationId, 'Rejected'),
                false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionBtn(
                'ACCEPTED',
                const Color(0xFF10B981),
                () {},
                true,
              ),
            ),
          ],
        );
      } else if (status == 'Rejected') {
        return Row(
          children: [
            Expanded(
              child: _actionBtn(
                'REJECTED',
                const Color(0xFFEF4444),
                () {},
                true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionBtn(
                'ACCEPT',
                const Color(0xFF10B981),
                () => _updateApplicationStatus(applicationId, 'Accepted'),
                false,
              ),
            ),
          ],
        );
      }
    } else if (jobStatus == 'ACTIVE') {
      if (status == 'Active') {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRemoveInternDialog(applicationId, name),
                icon: const Icon(Icons.person_remove_rounded, size: 16),
                label: const Text('REMOVE INTERN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      }
    } else if (jobStatus == 'CLOSED') {
      if (status == 'Active') {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showIssueCertificateDialog(applicationId, name),
                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                label: const Text('ISSUE CERTIFICATE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
              ),
            ),
          ],
        );
      } else if (status == 'Completed') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
                SizedBox(width: 8),
                Text('CERTIFICATE ISSUED', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
        );
      }
    }

    // Default: Return a nice status description label
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          'CANDIDATE STATUS: ${status.toUpperCase()}',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w900,
            fontSize: 10.5,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap, bool active) {
    return GestureDetector(
      onTap: active ? null : onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(Color color) {
    final tasks = (widget.posting['responsibilities'] as List? ?? [])
        .map((t) => t.toString())
        .where((t) => t.isNotEmpty)
        .toList();
    final notes = widget.posting['notes']?.toString() ?? '';
    final rawDays = widget.posting['active_days'];
    final days = rawDays is List
        ? rawDays.map((d) => d.toString()).toList()
        : <String>[];

    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = allDays.where((d) => days.contains(d)).toList();

    String daysSummary = '';
    if (sortedDays.length == 7) {
      daysSummary = 'All days — 7 days/week';
    } else if (sortedDays.length == 5 &&
        !days.contains('Sat') &&
        !days.contains('Sun')) {
      daysSummary = 'Monday to Friday — 5 days/week';
    } else if (sortedDays.isNotEmpty) {
      daysSummary =
          '${sortedDays.join(', ')} — ${sortedDays.length} day${sortedDays.length == 1 ? '' : 's'}/week';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── About ────────────────────────────────────────────────────
          _sectionTitle('ABOUT THE ROLE'),
          const SizedBox(height: 12),
          Text(
            widget.posting['about'] ?? 'No description provided.',
            style: const TextStyle(
                color: Color(0xFF64748B), fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 32),

          // ── Task List ───────────────────────────────────────────────
          _sectionTitle('TASK LIST'),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text('No tasks specified.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: color.withValues(alpha: 0.25)),
                          ),
                          child: Center(
                            child: Text('${index + 1}',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(tasks[index],
                              style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // ── Notes ────────────────────────────────────────────────────
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 32),
            _sectionTitle('NOTES'),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sticky_note_2_rounded,
                        color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(notes,
                        style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.6)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          Row(
            children: [
              _infoTile('STIPEND', '₹${widget.posting['stipend']}/mo'),
              const SizedBox(width: 16),
              _infoTile('DURATION', '${widget.posting['duration']} Months'),
            ],
          ),

          // ── Active Days in the Week ──────────────────────────────────
          if (sortedDays.isNotEmpty) ...[
            const SizedBox(height: 32),
            _sectionTitle('DAYS ACTIVE IN THE WEEK'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: allDays.map((day) {
                      final isActive = days.contains(day);
                      final isWeekend = day == 'Sat' || day == 'Sun';
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              day.substring(0, isWeekend ? 3 : 1),
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(daysSummary,
                          style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'active':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'under review':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    try {
      final date = DateTime.parse(value.toString());
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
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
      ..color = const Color(0xFFCBD5E1)
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
