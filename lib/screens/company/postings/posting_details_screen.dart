import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import '../candidates/student_history_dialog.dart';
import '../../../utils/qr_payload_security.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
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
  bool _isBroadcastMode = false;
  final Set<String> _selectedBroadcastAppIds = {};
  late PageController _pageController;

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
    _pageController = PageController(initialPage: _tabIndex);
    _fetchApplicants();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        final String startDateStr = (_posting['start_date'] ?? DateTime.now().toIso8601String().split('T')[0]).toString();
        String? endDateStr = _posting['end_date']?.toString();
        if (endDateStr == null) {
          try {
            final startDate = DateTime.parse(startDateStr);
            final durationStr = (_posting['duration']?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            final durationMonths = int.tryParse(durationStr) ?? 3;
            endDateStr = DateTime(startDate.year, startDate.month + durationMonths, startDate.day).toIso8601String().split('T')[0];
          } catch (_) {
            endDateStr = DateTime.now().add(const Duration(days: 90)).toIso8601String().split('T')[0];
          }
        }

        await supabase
            .from('applications')
            .update({
              'status': 'Active',
              'start_date': startDateStr,
              'end_date': endDateStr,
            })
            .eq('internship_id', _posting['id'])
            .eq('status', 'Accepted');
      } else if (newStatus == 'INTERVIEWING') {
        await supabase
            .from('applications')
            .update({
              'status': 'Applied',
              'start_date': null,
              'end_date': null,
            })
            .eq('internship_id', _posting['id']);
      } else if (newStatus == 'CLOSED') {
        await supabase
            .from('applications')
            .update({
              'status': 'Completed',
              'end_date': DateTime.now().toIso8601String().split('T')[0],
            })
            .eq('internship_id', _posting['id'])
            .eq('status', 'Active');
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

  Future<void> _showBroadcastAlertDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String type = 'warning';
    bool sending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, color: Color(0xFF6366F1), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'BROADCAST (${_selectedBroadcastAppIds.length} SELECTED)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: type,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'info', child: Text('Info')),
                          DropdownMenuItem(value: 'warning', child: Text('Warning')),
                          DropdownMenuItem(value: 'danger', child: Text('Danger')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => type = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Alert Title',
                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Message details...',
                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: sending ? null : () => Navigator.pop(context),
                    child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: sending
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final message = messageController.text.trim();
                            if (title.isEmpty || message.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter both title and message'), backgroundColor: Color(0xFFEF4444)),
                              );
                              return;
                            }

                            setDialogState(() => sending = true);
                            try {
                              final supabase = Supabase.instance.client;
                              for (final appId in _selectedBroadcastAppIds) {
                                final res = await supabase
                                    .from('applications')
                                    .select('alerts')
                                    .eq('id', appId)
                                    .maybeSingle();

                                List<dynamic> currentAlerts = [];
                                if (res != null && res['alerts'] is List) {
                                  currentAlerts = List.from(res['alerts']);
                                }

                                currentAlerts.add({
                                  'title': title,
                                  'message': message,
                                  'type': type,
                                  'created_at': DateTime.now().toUtc().toIso8601String(),
                                });

                                await supabase
                                    .from('applications')
                                    .update({'alerts': currentAlerts})
                                    .eq('id', appId);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                setState(() {
                                  _isBroadcastMode = false;
                                  _selectedBroadcastAppIds.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Broadcast sent successfully!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send broadcast: $e'),
                                    backgroundColor: const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            } finally {
                              setDialogState(() => sending = false);
                            }
                          },
                    icon: sending
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 12),
                    label: const Text('SEND BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
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
        height: 42,
        child: ElevatedButton.icon(
          onPressed: () => _updateJobStatus('ACTIVE'),
          icon: const Icon(Icons.play_circle_fill_rounded, size: 14),
          label: const Text(
            'START MISSION (ACTIVATE)',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 9.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), // Emerald 500
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      );
    } else if (status == 'ACTIVE') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () => _updateJobStatus('INTERVIEWING'),
                icon: const Icon(Icons.undo_rounded, size: 14),
                label: const Text(
                  'REVERT TO INTERVIEW',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3, fontSize: 9.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  foregroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus('CLOSED'),
                icon: const Icon(Icons.cancel_rounded, size: 14),
                label: const Text(
                  'CLOSE MISSION',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3, fontSize: 9.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () => _updateJobStatus('INTERVIEWING'),
                icon: const Icon(Icons.people_outline_rounded, size: 14),
                label: const Text(
                  'INTERVIEWING',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3, fontSize: 9.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                  foregroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus('ACTIVE'),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text(
                  'REOPEN MISSION',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3, fontSize: 9.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _payload {
    return jsonEncode(
      QrPayloadSecurity.buildRolePayload(
        internshipId: _posting['id']?.toString() ?? '',
        role: _posting['role']?.toString() ?? '',
        status: _posting['status']?.toString() ?? '',
        issuerId: _posting['company_id']?.toString() ?? '',
        company: _posting['company_name']?.toString() ?? '',
        startDate: _posting['start_date']?.toString() ?? '',
        endDate: _posting['end_date']?.toString() ?? '',
        date: _todayIso(),
      ),
    );
  }

  Widget _buildContent(Color color) {
    final status = _posting['status']?.toString().toUpperCase() ?? 'INTERVIEWING';
    final hasQrTab = status == 'ACTIVE' || status == 'CLOSED';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: _tabButton(0, 'APPLICANTS', _displayedApplicants.length.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _tabButton(1, 'DESCRIPTION', null),
              ),
              if (hasQrTab) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _tabButton(2, 'CHECK-IN QR', null),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
            children: [
              _buildApplicantsList(color),
              _buildDescription(color),
              if (hasQrTab) _buildQrCodeTab(color),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, String? count) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _tabIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
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
    final activeInterns = list.where((app) => app['status']?.toString().toLowerCase() == 'active').toList();
    final hasActiveInterns = activeInterns.isNotEmpty;

    return Column(
      children: [
        if (hasActiveInterns) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isBroadcastMode ? const Color(0xFFEEF2F6) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isBroadcastMode ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                  width: _isBroadcastMode ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isBroadcastMode
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          child: const Icon(Icons.campaign_rounded, color: Color(0xFF6366F1), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Broadcast Alert',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedBroadcastAppIds.length} interns selected',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 32,
                          width: 80,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isBroadcastMode = false;
                                _selectedBroadcastAppIds.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                              foregroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          width: 80,
                          child: ElevatedButton(
                            onPressed: _selectedBroadcastAppIds.isEmpty ? null : _showBroadcastAlertDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'SEND',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          child: const Icon(Icons.campaign_rounded, color: Color(0xFF6366F1), size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Broadcast Alert',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Send updates to multiple interns at once',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 32,
                          width: 80,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isBroadcastMode = true;
                                _selectedBroadcastAppIds.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'START',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final app = list[index];
              final student = app['students'] as Map<String, dynamic>?;
              final name = student?['name'] ?? 'Candidate';
              final status = app['status'] ?? 'Applied';
              final appId = app['id']?.toString() ?? '';
              
              final avatarColor = _getAvatarColor(name);
              final isCandidateActive = status.toLowerCase() == 'active';
              final isSelectedForBroadcast = _selectedBroadcastAppIds.contains(appId);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isBroadcastMode && isCandidateActive && isSelectedForBroadcast
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFE2E8F0),
                    width: _isBroadcastMode && isCandidateActive && isSelectedForBroadcast ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_isBroadcastMode && isCandidateActive) ...[
                      Checkbox(
                        value: isSelectedForBroadcast,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedBroadcastAppIds.add(appId);
                            } else {
                              _selectedBroadcastAppIds.remove(appId);
                            }
                          });
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
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
                          if (status.toLowerCase() == 'active' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'removed') ...[
                            Builder(
                              builder: (context) {
                                double rawProgress = double.tryParse(app['progress']?.toString() ?? '0') ?? 0.0;
                                if (rawProgress > 1.0) {
                                  rawProgress = rawProgress / 100.0;
                                }
                                final progressValue = rawProgress;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'INTERNSHIP PROGRESS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          '${(progressValue * 100).round()}%',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: progressValue,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              }
                            ),
                          ],
                          _buildCandidateActionButtons(jobStatus, status, app, name),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

  Widget _buildCandidateActionButtons(String jobStatus, String status, Map<String, dynamic> app, String name) {
    jobStatus = jobStatus.toUpperCase();
    final applicationId = app['id']?.toString() ?? '';
    
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
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentInfoScreen(
                        applicationId: applicationId,
                        studentName: name,
                        progress: double.tryParse(app['progress']?.toString() ?? '0') ?? 0.0,
                        checkins: app['checkins'] as List? ?? [],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('VIEW INFO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
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

  Widget _buildQrCodeTab(Color color) {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final todayDisplay = '${now.day} ${months[now.month - 1]} ${now.year}';
    final role = _posting['role']?.toString() ?? 'Role';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'CHECK-IN QR CODE',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scan to register daily check-in',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: QrImageView(
                    data: _payload,
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0F172A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Role', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(role, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('${_posting['duration'] ?? 'N/A'} Months', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('QR Date', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(todayDisplay, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadQrCode(context),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareQrCode(context),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share Payload'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQrCode(BuildContext context) async {
    try {
      final name = _posting['role']?.toString().replaceAll(' ', '_') ?? 'internship';
      final fileName = '${name}_qr.png';
      
      final url = 'https://api.qrserver.com/v1/create-qr-code/?size=1024x1024&format=png&margin=12&data=${Uri.encodeComponent(_payload)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final bytes = response.bodyBytes;

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download not supported on web preview'), backgroundColor: Colors.orange),
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        String? selectedDirectory;
        try {
          selectedDirectory = await FilePicker.getDirectoryPath();
        } catch (e) {
          debugPrint('Directory picker error: $e');
        }
        if (selectedDirectory == null) {
          // User cancelled
          return;
        }
        final file = File('$selectedDirectory/$fileName');
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: ${file.path}'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        // Desktop / Save File Dialog using file_selector
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'Images',
              extensions: ['png'],
              mimeTypes: ['image/png'],
            )
          ],
        );
        if (result != null) {
          final file = File(result.path);
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QR Code saved successfully'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download QR code: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _shareQrCode(BuildContext context) async {
    try {
      final name = _posting['role']?.toString().replaceAll(' ', '_') ?? 'internship';
      final fileName = '${name}_qr.png';
      
      final url = 'https://api.qrserver.com/v1/create-qr-code/?size=1024x1024&format=png&margin=12&data=${Uri.encodeComponent(_payload)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final bytes = response.bodyBytes;

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code image link copied to clipboard!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check-in QR Code for ${_posting['role']}',
        );
      }
    } catch (e) {
      // Fallback: copy QR image link to clipboard if native share fails or is unsupported
      try {
        final url = 'https://api.qrserver.com/v1/create-qr-code/?size=1024x1024&format=png&margin=12&data=${Uri.encodeComponent(_payload)}';
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Native share unavailable. QR Image URL copied to clipboard!'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
      } catch (clipError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share or copy: $clipError'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
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

class StudentInfoScreen extends StatefulWidget {
  final String applicationId;
  final String studentName;
  final double progress;
  final List<dynamic> checkins;

  const StudentInfoScreen({
    super.key,
    required this.applicationId,
    required this.studentName,
    required this.progress,
    required this.checkins,
  });

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  late DateTime _selectedMonth;
  late DateTime _activeSelectedDate;
  
  bool _sendingAlert = false;
  final _alertTitleController = TextEditingController();
  final _alertMessageController = TextEditingController();
  String _alertType = 'warning';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _activeSelectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _alertTitleController.dispose();
    _alertMessageController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getCheckinForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    for (final checkin in widget.checkins) {
      if (checkin is Map) {
        final checkinDate = checkin['checkin_date']?.toString();
        if (checkinDate == dateStr) {
          return Map<String, dynamic>.from(checkin);
        }
      }
    }
    return null;
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _sendAlert() async {
    final title = _alertTitleController.text.trim();
    final message = _alertMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and message'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _sendingAlert = true);
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('applications')
          .select('alerts')
          .eq('id', widget.applicationId)
          .maybeSingle();

      List<dynamic> currentAlerts = [];
      if (res != null && res['alerts'] is List) {
        currentAlerts = List.from(res['alerts']);
      }

      currentAlerts.add({
        'title': title,
        'message': message,
        'type': _alertType,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      await supabase
          .from('applications')
          .update({'alerts': currentAlerts})
          .eq('id', widget.applicationId);

      if (mounted) {
        _alertTitleController.clear();
        _alertMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship Alert sent successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingAlert = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7; // 0 for Sunday

    final cells = <Widget>[];

    // Day labels
    const daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final day in daysOfWeek) {
      cells.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    // Weekday padding
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Days grid
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final checkin = _getCheckinForDate(date);
      final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
      final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_activeSelectedDate);

      Color bgColor = Colors.transparent;
      Color textColor = const Color(0xFF0F172A);
      IconData? icon;

      if (checkin != null) {
        final status = checkin['status']?.toString().toLowerCase() ?? '';
        if (status == 'present') {
          bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
          textColor = const Color(0xFF059669);
          icon = Icons.check_circle_rounded;
        } else if (status == 'absent') {
          bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
          textColor = const Color(0xFFDC2626);
          icon = Icons.cancel_rounded;
        } else {
          bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
          textColor = const Color(0xFFD97706);
          icon = Icons.watch_later_rounded;
        }
      } else if (isToday) {
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF0F172A);
      }

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _activeSelectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.15) : bgColor,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                  : (isToday ? Border.all(color: const Color(0xFFCBD5E1), width: 1.5) : null),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday || checkin != null || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF6366F1) : textColor,
                  ),
                ),
                if (icon != null)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(
                      icon,
                      size: 8,
                      color: isSelected ? const Color(0xFF6366F1) : textColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Safely normalize progress
    double rawProgress = widget.progress;
    if (rawProgress > 1.0) {
      rawProgress = rawProgress / 100.0;
    }
    final progressValue = rawProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'STUDENT INFO',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    child: Text(
                      widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Active Intern',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progress Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'OVERALL PROGRESS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${(progressValue * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar UI Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Navigator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ATTENDANCE LOG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                              });
                            },
                          ),
                          Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Grid of Days
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: cells.length,
                    itemBuilder: (context, index) => cells[index],
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(const Color(0xFF10B981), 'Present'),
                      const SizedBox(width: 16),
                      _legendItem(const Color(0xFFEF4444), 'Absent'),
                      const SizedBox(width: 16),
                      _legendItem(const Color(0xFFF59E0B), 'Late/Leave'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Check-in Details card
            Builder(
              builder: (context) {
                final selectedCheckin = _getCheckinForDate(_activeSelectedDate);
                final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(_activeSelectedDate);
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (selectedCheckin != null) ...[
                        Row(
                          children: [
                            _timeTile(
                              'CHECK-IN',
                              _formatTime(selectedCheckin['check_in_at']?.toString()),
                              Icons.login_rounded,
                              const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 16),
                            _timeTile(
                              'CHECK-OUT',
                              _formatTime(selectedCheckin['check_out_at']?.toString()),
                              Icons.logout_rounded,
                              const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        if (selectedCheckin['notes']?.toString().trim().isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 12),
                          const Text(
                            'NOTES',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedCheckin['notes'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ] else ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 32, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 8),
                                Text(
                                  'No check-in record for this date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 20),

            // Send Alert Form Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_alert_rounded, size: 18, color: Color(0xFF6366F1)),
                          SizedBox(width: 8),
                          Text(
                            'SEND INTERNSHIP ALERT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 32,
                        width: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _alertType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF64748B)),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'info', child: Text('Info')),
                              DropdownMenuItem(value: 'warning', child: Text('Warning')),
                              DropdownMenuItem(value: 'danger', child: Text('Danger')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _alertType = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _alertTitleController,
                    decoration: InputDecoration(
                      labelText: 'Alert Title',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alertMessageController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Message details...',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _sendingAlert ? null : _sendAlert,
                      icon: _sendingAlert
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 14),
                      label: const Text('SEND INTERN ALERT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _timeTile(String label, String time, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
