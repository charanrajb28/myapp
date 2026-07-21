import 'package:flutter/material.dart';
import '../feedbacks/admin_form_builder_screen.dart';
import '../../company/postings/posting_details_screen.dart';
import '../../company/postings/edit_posting_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoleDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  final String deadline;
  final String slots;
  final String startDate;
  final String duration;
  final String description;
  final List<String> responsibilities;
  final List<String> activeDays;
  final List<String> eligibleDepartments;
  final String stipend;
  final String location;
  final String notes;
  final String status;
  final List<Map<String, dynamic>> applicants;

  const RoleDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.deadline,
    required this.slots,
    required this.startDate,
    required this.duration,
    required this.description,
    required this.responsibilities,
    this.activeDays = const [],
    this.eligibleDepartments = const [],
    this.stipend = '',
    this.location = '',
    this.notes = '',
    this.status = 'INTERVIEWING',
    required this.applicants,
  });

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  bool _hasForm = false;
  bool _isLoadingForm = true;

  late String _currentStatus;
  bool _isUpdatingStatus = false;

  final _broadcastTitleController = TextEditingController();
  final _broadcastMessageController = TextEditingController();
  bool _sendingBroadcast = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status.toUpperCase();
    _checkForm();
  }

  Future<void> _updatePostingStatus(String newStatus) async {
    if (widget.id.isEmpty) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await Supabase.instance.client
          .from('internships')
          .update({'status': newStatus})
          .eq('id', widget.id);

      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'INTERVIEWING' ? 'Posting Approved and moved to Open!' : 'Posting Rejected.'),
            backgroundColor: newStatus == 'INTERVIEWING' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating posting status: $e');
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  void dispose() {
    _broadcastTitleController.dispose();
    _broadcastMessageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcastAlert() async {
    final title = _broadcastTitleController.text.trim();
    final message = _broadcastMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and message'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _sendingBroadcast = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      String senderName = 'System Admin';
      if (user != null) {
        final adminRes = await supabase
            .from('sub_admins')
            .select('users!sub_admins_user_id_fkey(name)')
            .eq('user_id', user.id)
            .maybeSingle();
        if (adminRes != null && adminRes['users'] != null) {
          senderName = adminRes['users']['name']?.toString() ?? 'System Admin';
        }
      }

      // Get all application IDs under this internship that are active or accepted
      final targetApps = widget.applicants.where((a) {
        final status = a['status']?.toString().toLowerCase() ?? '';
        return status == 'active' || status == 'accepted';
      }).toList();
      
      if (targetApps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active/accepted students in this internship to broadcast to.'), backgroundColor: Color(0xFFEA580C)),
        );
        setState(() => _sendingBroadcast = false);
        return;
      }

      for (final app in targetApps) {
        final appId = app['application_id']?.toString() ?? '';
        if (appId.isEmpty) continue;

        // Fetch current alerts
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
          'type': 'warning',
          'sender': senderName,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });

        await supabase
            .from('applications')
            .update({'alerts': currentAlerts})
            .eq('id', appId);
      }

      if (mounted) {
        _broadcastTitleController.clear();
        _broadcastMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent successfully to all active students!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send broadcast: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingBroadcast = false);
      }
    }
  }

  void _showBroadcastDialog() {
    _broadcastTitleController.clear();
    _broadcastMessageController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.campaign_rounded, color: Color(0xFF6366F1)),
                SizedBox(width: 10),
                Text('Broadcast to Interns', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This announcement will be sent to all active/accepted students under this role.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _broadcastTitleController,
                  decoration: InputDecoration(
                    labelText: 'Announcement Title',
                    hintText: 'e.g. Weekly Report Reminder',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _broadcastMessageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message Body',
                    hintText: 'Type your message details here...',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: _sendingBroadcast
                    ? null
                    : () async {
                        setDialogState(() => _sendingBroadcast = true);
                        await _sendBroadcastAlert();
                        setDialogState(() => _sendingBroadcast = false);
                        if (mounted) Navigator.pop(ctx);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _sendingBroadcast
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('SEND BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          );
        }
      ),
    );
  }

  String _gformUrl = '';

  Future<void> _checkForm() async {
    if (widget.id.isEmpty) {
      if (mounted) setState(() => _isLoadingForm = false);
      return;
    }
    if (mounted) setState(() => _isLoadingForm = true);
    try {
      final res = await Supabase.instance.client
          .from('internships')
          .select('feedback_form_schema')
          .eq('id', widget.id)
          .single();
      final schema = res['feedback_form_schema'];
      if (mounted) {
        setState(() {
          if (schema is List && schema.isNotEmpty && schema.first is Map && schema.first['gform_url'] != null) {
            _gformUrl = schema.first['gform_url'].toString();
            _hasForm = _gformUrl.isNotEmpty;
          } else if (schema is List && schema.isNotEmpty) {
            _hasForm = true;
          } else {
            _hasForm = false;
            _gformUrl = '';
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking form: $e');
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  void _showGFormDialog() {
    final controller = TextEditingController(text: _gformUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Add Google Form Link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your Google Form URL for students to fill out when completing this internship.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://forms.gle/... or https://docs.google.com/forms/...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = controller.text.trim();
              if (link.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Google Form URL'), backgroundColor: Color(0xFFEF4444)),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isLoadingForm = true);
              try {
                final newSchema = [
                  {'gform_url': link, 'created_at': DateTime.now().toIso8601String()}
                ];
                await Supabase.instance.client
                    .from('internships')
                    .update({'feedback_form_schema': newSchema})
                    .eq('id', widget.id);

                if (mounted) {
                  setState(() {
                    _gformUrl = link;
                    _hasForm = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google Form link saved successfully!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                debugPrint('Error saving GForm link: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save link: $e'), backgroundColor: const Color(0xFFEF4444)),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoadingForm = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SAVE LINK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Google Form Link?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('This will remove the attached Google Form link for students. Are you sure?'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoadingForm = true);
              try {
                await Supabase.instance.client
                    .from('internships')
                    .update({'feedback_form_schema': []})
                    .eq('id', widget.id);
                setState(() {
                  _hasForm = false;
                  _gformUrl = '';
                });
              } catch (e) {
                debugPrint('Error clearing form: $e');
              } finally {
                if (mounted) setState(() => _isLoadingForm = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Remove Link'),
          ),
        ],
      ),
    );
  }

  // Derive counts from applicants
  int get _accepted     => widget.applicants.where((a) => a['status'] == 'Accepted').length;
  int get _underReview  => widget.applicants.where((a) => a['status'] == 'Under Review').length;
  int get _applied      => widget.applicants.where((a) => a['status'] == 'Applied').length;
  int get _rejected     => widget.applicants.where((a) => a['status'] == 'Rejected').length;

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Softer background to make white cards pop
      appBar: AppBar(
        title: const Text('Role Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Options',
            onSelected: (val) async {
              if (val == 'edit' && widget.id.isNotEmpty) {
                try {
                  final res = await Supabase.instance.client
                      .from('internships')
                      .select('*')
                      .eq('id', widget.id)
                      .single();
                  if (context.mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPostingScreen(posting: Map<String, dynamic>.from(res)),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error fetching posting for edit: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load posting details: $e'), backgroundColor: const Color(0xFFEF4444)),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F172A)),
                    SizedBox(width: 10),
                    Text('Edit Posting', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Review Action Card (when status is UNDER_REVIEW) ──
              if (_currentStatus == 'UNDER_REVIEW')
                _buildSectionCard(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.rate_review_outlined, color: Color(0xFFD97706), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Admin Review',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Review this company posting and approve or reject it.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_isUpdatingStatus)
                          const Center(child: CircularProgressIndicator())
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _updatePostingStatus('REJECTED'),
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: const Text('REJECT POSTING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _updatePostingStatus('INTERVIEWING'),
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('APPROVE & OPEN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Header Card ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.location.isNotEmpty ? widget.location.toUpperCase() : widget.type.toUpperCase(), 
                            style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${widget.slots} VACANCIES', 
                            style: const TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(widget.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5, height: 1.2),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _MetaBox(icon: Icons.payments_rounded, label: 'Stipend', value: widget.stipend.isNotEmpty ? widget.stipend : 'Unpaid', color: const Color(0xFF10B981))),
                        const SizedBox(width: 12),
                        Expanded(child: _MetaBox(icon: Icons.timer_rounded, label: 'Duration', value: widget.duration, color: const Color(0xFF8B5CF6))),
                        const SizedBox(width: 12),
                        Expanded(child: _MetaBox(icon: Icons.event_busy_rounded, label: 'Deadline', value: widget.deadline, color: const Color(0xFFF43F5E))),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Eligible Departments Card ──
              if (widget.eligibleDepartments.isNotEmpty)
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Eligible Departments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.eligibleDepartments.map((dept) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_rounded, size: 14, color: Color(0xFF6366F1)),
                                const SizedBox(width: 6),
                                Text(
                                  dept,
                                  style: const TextStyle(color: Color(0xFF4338CA), fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              
              // ── Details Card (About, Responsibilities, Task List) ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About the Role', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                    const SizedBox(height: 14),
                    Text(widget.description,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w400),
                    ),
                    
                    if (widget.responsibilities.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 24),
                      const Text('Responsibilities', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                      const SizedBox(height: 16),
                      ...widget.responsibilities.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(r, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.5)),
                                ),
                              ],
                            ),
                          )),
                    ],

                    if (widget.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 24),
                      const Text('Task List', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD97706), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(widget.notes,
                                    style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500, height: 1.6)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Active Days Card ──
              if (widget.activeDays.isNotEmpty)
                _buildSectionCard(
                  child: Builder(builder: (context) {
                    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final sortedDays = allDays.where((d) => widget.activeDays.contains(d)).toList();

                    String daysSummary = '';
                    if (sortedDays.length == 7) {
                      daysSummary = 'All days — 7 days/week';
                    } else if (sortedDays.length == 5 && !widget.activeDays.contains('Sat') && !widget.activeDays.contains('Sun')) {
                      daysSummary = 'Monday to Friday — 5 days/week';
                    } else {
                      daysSummary = '${sortedDays.join(', ')} — ${sortedDays.length} day${sortedDays.length == 1 ? '' : 's'}/week';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Days Active in the Week', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: allDays.map((day) {
                                  final isActive = widget.activeDays.contains(day);
                                  final isWeekend = day == 'Sat' || day == 'Sun';
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          day.substring(0, isWeekend ? 3 : 1),
                                          style: TextStyle(color: isActive ? const Color(0xFF047857) : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(daysSummary, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

              // ── Feedback Configuration Card ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Google Form Feedback', 
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasForm 
                          ? 'Attached Form: $_gformUrl' 
                          : 'Attach a Google Form URL for students to complete their feedback response upon internship completion.',
                      style: TextStyle(
                        color: _hasForm ? const Color(0xFF10B981) : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: _hasForm ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.id.isNotEmpty)
                      _isLoadingForm 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showGFormDialog,
                                icon: Icon(_hasForm ? Icons.edit_rounded : Icons.add_link_rounded, size: 16),
                                label: Text(_hasForm ? 'Edit GForm Link' : 'Add GForm Link'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasForm ? const Color(0xFF1D4ED8) : const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              if (_hasForm) ...[
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: _clearForm,
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Remove'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ],
                ),
              ),

              // ── Broadcast Notification Card ──
              _buildSectionCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broadcast Announcement',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Send a notification to all active students in this internship.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showBroadcastDialog,
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('BROADCAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Applicants Card ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Applicants', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                          child: Text('Total ${widget.applicants.length}',
                            style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ]
                    ),
                    const SizedBox(height: 20),
                    
                    // Summary pills (scrollable horizontally if needed)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (_accepted > 0) _summaryPill('$_accepted Accepted', const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)),
                          if (_underReview > 0) _summaryPill('$_underReview Reviewing', const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
                          if (_applied > 0) _summaryPill('$_applied New', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFFFED7AA)),
                          if (_rejected > 0) _summaryPill('$_rejected Rejected', const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFFFECACA)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // applicant list
                    if (widget.applicants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No applicants yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      )
                    else
                      ...widget.applicants.map((a) => _ApplicantRow(
                            applicant: a,
                            onStatusUpdate: (appId, newStatus) async {
                              try {
                                await Supabase.instance.client
                                    .from('applications')
                                    .update({'status': newStatus})
                                    .eq('id', appId);
                                setState(() {
                                  a['status'] = newStatus;
                                });
                              } catch (e) {
                                debugPrint('Error updating status: $e');
                              }
                            },
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryPill(String label, Color text, Color bg, Color border) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text)),
    );
  }
}

class _MetaBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _MetaBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, 
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  final Map<String, dynamic> applicant;
  final Function(String appId, String newStatus)? onStatusUpdate;

  const _ApplicantRow({required this.applicant, this.onStatusUpdate});

  static const _avatarColors = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFEA580C), Color(0xFF8B5CF6), Color(0xFFF43F5E),
  ];

  @override
  Widget build(BuildContext context) {
    final name   = applicant['name']?.toString() ?? 'Unknown';
    final id     = applicant['id']?.toString() ?? 'N/A';
    final dept   = applicant['dept']?.toString() ?? 'CS';
    final status = applicant['status']?.toString() ?? 'Applied';
    final appId  = applicant['application_id']?.toString() ?? applicant['id']?.toString() ?? '';
    final avatarColor = _avatarColors[name.codeUnitAt(0) % _avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (appId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentInfoScreen(
                        applicationId: appId,
                        studentName: name,
                        progress: double.tryParse(applicant['progress']?.toString() ?? '0') ?? 0.0,
                        checkins: applicant['checkins'] as List? ?? [],
                        showSendAlert: false,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // Avatar
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(name[0],
                        style: TextStyle(fontWeight: FontWeight.w800, color: avatarColor, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 15, letterSpacing: -0.3),
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('$id • $dept', 
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  ])),
                  const SizedBox(width: 12),
                  _StatusBadge(status: status),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                ]),
              ),
            ),
          ),
          if (onStatusUpdate != null && (status == 'Applied' || status == 'Under Review')) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => onStatusUpdate!(appId, 'Rejected'),
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text('REJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => onStatusUpdate!(appId, 'Accepted'),
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (onStatusUpdate != null && (status == 'Accepted' || status == 'Rejected')) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onStatusUpdate!(appId, 'Applied'),
                  icon: const Icon(Icons.undo_rounded, size: 13),
                  label: const Text('RESET STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    IconData icon;

    switch (status) {
      case 'Accepted':
        bg = const Color(0xFFECFDF5); text = const Color(0xFF059669); icon = Icons.check_circle_rounded;
        break;
      case 'Under Review':
        bg = const Color(0xFFEFF6FF); text = const Color(0xFF2563EB); icon = Icons.hourglass_top_rounded;
        break;
      case 'Rejected':
        bg = const Color(0xFFFEF2F2); text = const Color(0xFFDC2626); icon = Icons.cancel_rounded;
        break;
      default: // Applied
        bg = const Color(0xFFFFF7ED); text = const Color(0xFFEA580C); icon = Icons.auto_awesome_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: text),
        const SizedBox(width: 6),
        Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
      ]),
    );
  }
}
