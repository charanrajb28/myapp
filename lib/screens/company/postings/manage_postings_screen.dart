import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'posting_details_screen.dart';
import 'create_posting_screen.dart';
import 'edit_posting_screen.dart';
import '../../../utils/qr_payload_security.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
class ManagePostingsScreen extends StatefulWidget {
  const ManagePostingsScreen({super.key});

  @override
  State<ManagePostingsScreen> createState() => _ManagePostingsScreenState();
}

class _ManagePostingsScreenState extends State<ManagePostingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPostings = [];

  @override
  void initState() {
    super.initState();
    _fetchPostings();
  }

  Future<void> _fetchPostings() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final companyRes = await supabase
          .from('companies')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final companyId = companyRes['id'];

      final res = await supabase
          .from('internships')
          .select('*, applications(id, status)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      for (var p in (res as List)) {
        final apps = p['applications'] as List;
        final pool = apps.length;
        final String status = p['status'] ?? 'INTERVIEWING';

        processed.add({
          ...p,
          'status': status,
          'applicants': pool.toString(),
          'completion': pool > 0 ? (apps.where((a) => a['status'] == 'Completed').length / pool).clamp(0.0, 1.0) : 0.05,
          'color': _parseColor(p['brand_color'] ?? '#6366F1'),
        });
      }

      if (mounted) {
        setState(() {
          _allPostings = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching postings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      final today = DateTime.now();
      final todayLabel = today.toIso8601String().split('T')[0];
      final posting = _allPostings.firstWhere(
        (item) => item['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final plannedEndDate = _plannedEndDateFromDuration(
        today,
        posting['duration'],
      );
      final Map<String, dynamic> updateData = {'status': newStatus};
      
      if (newStatus == 'ACTIVE') {
        updateData['start_date'] = todayLabel;
        updateData['end_date'] = plannedEndDate;
      } else if (newStatus == 'CLOSED') {
        updateData['end_date'] = todayLabel;
      } else if (newStatus == 'INTERVIEWING') {
        updateData['start_date'] = null;
        updateData['end_date'] = null;
      }

      await Supabase.instance.client
          .from('internships')
          .update(updateData)
          .eq('id', id);

      if (newStatus == 'ACTIVE') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'status': 'Active',
              'start_date': todayLabel,
              'end_date': null,
            })
            .eq('internship_id', id)
            .inFilter('status', ['Accepted', 'Active', 'Completed']);
      } else if (newStatus == 'CLOSED') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'end_date': todayLabel,
            })
            .eq('internship_id', id)
            .eq('status', 'Active');
      } else if (newStatus == 'INTERVIEWING') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'status': 'Accepted',
              'start_date': null,
              'end_date': null,
            })
            .eq('internship_id', id)
            .eq('status', 'Active');
      }

      if (!mounted) return;
      setState(() {
        _allPostings = _allPostings
            .map(
              (item) => item['id'] == id
                  ? {
                      ...item,
                      ...updateData,
                    }
                  : item,
            )
            .toList();
      });

      _fetchPostings();
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> _discardPosting(String id) async {
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
          .eq('id', id);
      _fetchPostings();
    } catch (e) {
      debugPrint('Error discarding posting: $e');
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  String? _plannedEndDateFromDuration(DateTime startDate, dynamic rawDuration) {
    final value = rawDuration?.toString().trim() ?? '';
    final match = RegExp(r'\d+').firstMatch(value);
    final months = int.tryParse(match?.group(0) ?? '') ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostingScreen()));
            _fetchPostings();
          },
          backgroundColor: const Color(0xFF0F172A),
          elevation: 10,
          label: const Text('CREATE NEW JOB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _DotGrid()),
            SafeArea(
              child: NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(child: _JobsHeader()),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicatorColor: const Color(0xFF6366F1),
                          indicatorWeight: 4,
                          labelColor: const Color(0xFF0F172A),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                          unselectedLabelColor: const Color(0xFF94A3B8),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'INTERVIEWING'),
                            Tab(text: 'ACTIVE JOBS'),
                            Tab(text: 'CLOSED JOBS'),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ];
                },
                body: _isLoading 
                   ? const Center(child: CircularProgressIndicator())
                   : TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildListForStatus('INTERVIEWING'),
                          _buildListForStatus('ACTIVE'),
                          _buildListForStatus('CLOSED'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListForStatus(String filterStatus) {
    final filteredList = _allPostings.where((p) => p['status'] == filterStatus).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 48),
              SizedBox(height: 20),
              Text('NO JOBS FOUND', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
              SizedBox(height: 8),
              Text('No listings available in this category.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        return _JobIndustrialCard(
          posting: filteredList[index],
          onTap: () => _showPostDetail(context, filteredList[index]),
          onStatusChange: (newStatus) => _updateStatus(filteredList[index]['id'], newStatus),
          onDiscard: () => _discardPosting(filteredList[index]['id']),
          onShareQr: () => _showQRDialog(context, filteredList[index]),
          onEdit: () async {
            final edited = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostingScreen(posting: filteredList[index]),
              ),
            );
            if (edited == true && mounted) {
              _fetchPostings();
            }
          },
        );
      },
    );
  }

  Future<void> _showPostDetail(
    BuildContext context,
    Map<String, dynamic> posting,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostingDetailsScreen(posting: posting),
      ),
    );
    if (mounted) {
      _fetchPostings();
    }
  }

  void _showQRDialog(BuildContext context, Map<String, dynamic> posting) {
    showDialog(
      context: context,
      builder: (context) => _CompanyQrDialog(posting: posting),
    );
  }
}

class _JobIndustrialCard extends StatelessWidget {
  final Map<String, dynamic> posting;
  final VoidCallback onTap;
  final Function(String) onStatusChange;
  final VoidCallback onDiscard;
  final VoidCallback onShareQr;
  final VoidCallback onEdit;
  const _JobIndustrialCard({
    required this.posting,
    required this.onTap,
    required this.onStatusChange,
    required this.onDiscard,
    required this.onShareQr,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = posting['color'] as Color;
    final status = posting['status'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.work_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(posting['role'].toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      _statusChip('${posting['applicants']} APPLICANTS', color),
                    ],
                  ),
                ),
                _statusMenu(context),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CREATED: ${_formatDate(posting['created_at'])}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
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
    );
  }

  Widget _statusMenu(BuildContext context) {
    final status = posting['status'] as String? ?? 'INTERVIEWING';
    final isInterviewing = status == 'INTERVIEWING';
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
      onSelected: (val) {
        if (val == 'DISCARD') {
          onDiscard();
        } else if (val == 'SHARE_QR') {
          onShareQr();
        } else if (val == 'EDIT') {
          onEdit();
        } else {
          onStatusChange(val);
        }
      },
      itemBuilder: (context) => [
        ..._statusMenuItems(status),
        if (isInterviewing)
          const PopupMenuItem(
            value: 'EDIT',
            child: Text('Edit Posting'),
          ),
        if (!isInterviewing)
          const PopupMenuItem(
            value: 'SHARE_QR',
            child: Text('Share QR Code'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'DISCARD',
          child: Text('Discard Internship', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _statusMenuItems(String status) {
    switch (status) {
      case 'INTERVIEWING':
        return const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Move to Active')),
        ];
      case 'ACTIVE':
        return const [
          PopupMenuItem(
            value: 'INTERVIEWING',
            child: Text('Move to Interviewing'),
          ),
          PopupMenuItem(value: 'CLOSED', child: Text('Move to Closed')),
        ];
      case 'CLOSED':
        return const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Move to Active')),
        ];
      default:
        return const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Move to Active')),
        ];
    }
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

class _JobsHeader extends StatelessWidget {
  const _JobsHeader();
  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ADMINISTRATION PANEL', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      SizedBox(height: 12),
      Text('Job Listings', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
      SizedBox(height: 8),
      Text('Manage and create new internship opportunities', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect), child: CustomPaint(painter: _DotPainter()));
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompanyQrDialog extends StatefulWidget {
  final Map<String, dynamic> posting;

  const _CompanyQrDialog({required this.posting});

  @override
  State<_CompanyQrDialog> createState() => _CompanyQrDialogState();
}

class _CompanyQrDialogState extends State<_CompanyQrDialog> {
  bool _downloading = false;

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == 'null') return 'N/A';
    try {
      final d = DateTime.parse(raw.trim());
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw.trim();
    }
  }

  String get _payload => jsonEncode(
        QrPayloadSecurity.buildRolePayload(
          internshipId: widget.posting['id']?.toString() ?? '',
          role: widget.posting['role']?.toString() ?? '',
          status: widget.posting['status']?.toString() ?? '',
          issuerId: widget.posting['company_id']?.toString() ?? '',
          company: widget.posting['company_name']?.toString() ?? '',
          startDate: widget.posting['start_date']?.toString() ?? '',
          endDate: widget.posting['end_date']?.toString() ?? '',
          date: _todayIso(),
        ),
      );

  String get _qrImageUrl =>
      'https://api.qrserver.com/v1/create-qr-code/?size=1024x1024&format=png&margin=12&data=${Uri.encodeComponent(_payload)}';

  Future<void> _downloadQr() async {
    try {
      setState(() => _downloading = true);
      final response = await http.get(Uri.parse(_qrImageUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QR service returned ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final name = widget.posting['role']?.toString().replaceAll(' ', '_') ?? 'internship';
      final fileName = '${name}_qr.png';

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download not supported on web preview'), backgroundColor: Colors.orange),
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: ${file.path}'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
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
            Navigator.of(context).pop();
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
            content: Text('Unable to download QR: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _shareQr() async {
    try {
      final name = widget.posting['role']?.toString().replaceAll(' ', '_') ?? 'internship';
      final fileName = '${name}_qr.png';
      
      final response = await http.get(Uri.parse(_qrImageUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QR service returned ${response.statusCode}');
      }

      final bytes = response.bodyBytes;

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: _qrImageUrl));
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
          text: 'Check-in QR Code for ${widget.posting['role']}',
        );
      }
    } catch (e) {
      try {
        await Clipboard.setData(ClipboardData(text: _qrImageUrl));
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

  @override
  Widget build(BuildContext context) {
    final role = widget.posting['role']?.toString() ?? 'Role';
    final status = widget.posting['status']?.toString() ?? '';
    final startDate = _formatDisplayDate(widget.posting['start_date']?.toString());
    final endDate = _formatDisplayDate(widget.posting['end_date']?.toString());
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final todayDisplay = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Check-In QR Code',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
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

            // QR Code (rendered locally via qr_flutter)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: _payload,
                version: QrVersions.auto,
                size: 220,
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
            const SizedBox(height: 16),

            // Internship detail info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status == 'ACTIVE'
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'ACTIVE'
                                ? const Color(0xFF059669)
                                : const Color(0xFF6366F1),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Generated: $todayDisplay',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 10),
                  _infoRow(Icons.work_outline_rounded, 'Role', role),
                  const SizedBox(height: 6),
                  _infoRow(Icons.fingerprint_rounded, 'Internship ID',
                      widget.posting['id']?.toString() ?? 'N/A'),
                  const SizedBox(height: 6),
                  if (widget.posting['start_date'] != null && widget.posting['end_date'] != null) ...[
                    _infoRow(Icons.calendar_today_outlined, 'Period', '$startDate → $endDate'),
                    const SizedBox(height: 6),
                  ] else ...[
                    _infoRow(Icons.timelapse_rounded, 'Duration', '${widget.posting['duration'] ?? 'N/A'} Months'),
                    const SizedBox(height: 6),
                  ],
                  _infoRow(Icons.event_note_outlined, 'QR Date', todayDisplay),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SCAN WITH STUDENT APP TO CHECK IN',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Download and Share buttons row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _downloading ? null : _downloadQr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _downloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        _downloading ? 'SAVING...' : 'DOWNLOAD',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _shareQr,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'SHARE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
