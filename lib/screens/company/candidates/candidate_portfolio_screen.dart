import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CandidatePortfolioScreen extends StatefulWidget {
  final Map<String, dynamic> candidate;
  final String applicationId;
  final String applicationStatus;
  final String jobStatus;
  final VoidCallback onStatusUpdated;

  const CandidatePortfolioScreen({
    super.key,
    required this.candidate,
    required this.applicationId,
    required this.applicationStatus,
    required this.jobStatus,
    required this.onStatusUpdated,
  });

  @override
  State<CandidatePortfolioScreen> createState() => _CandidatePortfolioScreenState();
}

class _CandidatePortfolioScreenState extends State<CandidatePortfolioScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.applicationStatus;
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': newStatus})
          .eq('id', widget.applicationId);
      
      setState(() {
        _currentStatus = newStatus;
      });
      widget.onStatusUpdated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _issueCertificate(String certificateUrl) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Fetch existing alerts to prevent overwriting, along with company name
      final appRes = await supabase
          .from('applications')
          .select('alerts, internships(companies(name))')
          .eq('id', widget.applicationId)
          .maybeSingle();
          
      List<dynamic> currentAlerts = [];
      String companyName = 'the company';
      
      if (appRes != null) {
        if (appRes['alerts'] != null) {
          currentAlerts = List<dynamic>.from(appRes['alerts']);
        }
        final internship = appRes['internships'] as Map<String, dynamic>?;
        if (internship != null) {
          final company = internship['companies'] as Map<String, dynamic>?;
          if (company != null && company['name'] != null) {
            companyName = company['name'].toString();
          }
        }
      }
      
      // Create the certificate alert
      final newAlert = {
        'id': 'cert-alert-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Certificate of Excellence Issued',
        'message': 'Congratulations! Your Certificate of Excellence has been issued by $companyName. You can view or download it here: $certificateUrl',
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
          .eq('id', widget.applicationId);
      
      setState(() {
        _currentStatus = 'Completed';
      });
      widget.onStatusUpdated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate of Excellence issued successfully!'),
            backgroundColor: Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error giving certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue certificate: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showIssueCertificateDialog() {
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
              await _issueCertificate(link);
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

  void _showRemoveInternDialog() {
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
              try {
                await Supabase.instance.client
                    .from('applications')
                    .update({'status': 'Removed'})
                    .eq('id', widget.applicationId);
                
                setState(() {
                  _currentStatus = 'Removed';
                });
                widget.onStatusUpdated();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.candidate['name']} has been removed from the registry.'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error removing intern: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove intern: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.jobStatus.toUpperCase() == 'INTERVIEWING'
              ? 'PORTFOLIO: MASKED CANDIDATE'
              : 'PORTFOLIO: ${widget.candidate['name'].toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IDENTITY_PULSE ──
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: widget.jobStatus.toUpperCase() != 'INTERVIEWING'
                        ? NetworkImage(widget.candidate['avatar'])
                        : null,
                    backgroundColor: const Color(0xFF1E293B),
                    child: widget.jobStatus.toUpperCase() == 'INTERVIEWING'
                        ? const Icon(Icons.lock_rounded, color: Colors.white70, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobStatus.toUpperCase() == 'INTERVIEWING'
                              ? 'Masked Candidate'
                              : widget.candidate['name'],
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        if (widget.jobStatus.toUpperCase() != 'INTERVIEWING') ...[
                          Text(widget.candidate['college'], style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                            child: const Text('SCH_NODE_ID: 8829-AX', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ] else ...[
                          Text('SCH_NODE_ID: MASKED_STAGE_1', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            if (widget.jobStatus.toUpperCase() == 'INTERVIEWING') ...[
              // Locked placeholder card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STUDENT DETAILS OBSCURED',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To promote a fair and unbiased screening process, academic records, portfolio links, and skill metrics are hidden during the Interviewing stage. These details will unlock immediately when accepted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],

            if (widget.jobStatus.toUpperCase() != 'INTERVIEWING') ...[
              // ── PERFORMANCE_CORE ──
              const Text('> PERFORMANCE_INSIGHTS_v2.0', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statBox('RESUME', 'DOWNLOAD_PDF', Icons.description_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 12),
                  Expanded(child: _statBox('ATTENDANCE', '98.5%', Icons.verified_user_rounded, const Color(0xFF10B981))),
                ],
              ),
              const SizedBox(height: 32),
              _attendanceHeatmap(),

              const SizedBox(height: 48),

              // ── SKILL_MATRIX ──
              const Text('> TECHNICAL_SKILL_BREAKDOWN', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  _skillPulse('Flutter / Dart', 0.95),
                  _skillPulse('Firebase Cloud', 0.85),
                  _skillPulse('Node.js Backend', 0.70),
                  _skillPulse('DevOps Workflow', 0.50),
                  _skillPulse('RESTful APIs', 0.90),
                  _skillPulse('UI/UX Design', 0.75),
                ],
              ),
              const SizedBox(height: 60),
            ],
            
            // ── ACTIONS ──
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final jobStatus = widget.jobStatus.toUpperCase();
    final appStatus = _currentStatus;

    if (jobStatus == 'INTERVIEWING') {
      if (appStatus == 'Applied' || appStatus == 'Under Review') {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _updateStatus('Rejected'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    foregroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('REJECT CANDIDATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _updateStatus('Accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('ACCEPT CANDIDATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
          ],
        );
      } else if (appStatus == 'Accepted') {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _updateStatus('Rejected'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    foregroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('REJECT CANDIDATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    disabledForegroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('ACCEPTED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
          ],
        );
      } else if (appStatus == 'Rejected') {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    disabledForegroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('REJECTED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _updateStatus('Accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('ACCEPT CANDIDATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
                ),
              ),
            ),
          ],
        );
      }
    } else if (jobStatus == 'ACTIVE') {
      if (appStatus == 'Active') {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _showRemoveInternDialog,
            icon: const Icon(Icons.person_remove_rounded),
            label: const Text('REMOVE INTERN FROM MISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              foregroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        );
      }
    } else if (jobStatus == 'CLOSED') {
      if (appStatus == 'Active') {
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _showIssueCertificateDialog,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('GIVE CERTIFICATE OF EXCELLENCE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
          ),
        );
      } else if (appStatus == 'Completed') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 8),
                Text('CERTIFICATE OF EXCELLENCE ISSUED', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
        );
      }
    }

    // Default status label
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          'STATUS: ${appStatus.toUpperCase()}',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _attendanceHeatmap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ATTENDANCE_LOG_AUDIT (LAST 30 DAYS)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(30, (i) {
               bool absent = i == 7 || i == 14 || i == 21;
               return Container(
                 width: 14, height: 14,
                 decoration: BoxDecoration(
                   color: absent ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.2),
                   borderRadius: BorderRadius.circular(3),
                   border: Border.all(color: absent ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.2)),
                 ),
               );
            }),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text('AVG_LOGIN_TIME: 09:14 AM', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w800)),
              Spacer(),
              Text('STATUS: HIGH_CONSISTENCY', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _skillPulse(String label, double strength) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: strength > 0.7 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
