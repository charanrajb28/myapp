import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';

class AdminFormResponsesScreen extends StatefulWidget {
  final String internshipId;
  final String companyId;
  final String roleTitle;
  final String companyName;
  final List<dynamic> schema;

  const AdminFormResponsesScreen({
    super.key,
    required this.internshipId,
    required this.companyId,
    required this.roleTitle,
    required this.companyName,
    required this.schema,
  });

  @override
  State<AdminFormResponsesScreen> createState() => _AdminFormResponsesScreenState();
}

class _AdminFormResponsesScreenState extends State<AdminFormResponsesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _responses = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchResponses();
  }

  Future<void> _fetchResponses() async {
    try {
      final client = Supabase.instance.client;
      // Fetch feedbacks for the given company_id and type = 'Final Feedback'
      // Since we don't have internship_id in feedbacks, this is the closest we can get.
      final res = await client
          .from('feedbacks')
          .select('id, form_responses, created_at, students(name, enrollment_id)')
          .eq('company_id', widget.companyId)
          .eq('type', 'Final Feedback')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          // Filter to only include responses that match the current form schema
          final schemaIds = widget.schema.map((q) => q['id'].toString()).toSet();
          
          _responses = (res as List).where((fb) {
            final formResponses = fb['form_responses'] as Map<String, dynamic>?;
            if (formResponses == null) return false;
            
            // Check if at least one key in formResponses matches our schema
            bool matchesSchema = false;
            for (final key in formResponses.keys) {
              if (schemaIds.contains(key)) {
                matchesSchema = true;
                break;
              }
            }
            return matchesSchema;
          }).map((e) => e as Map<String, dynamic>).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching responses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading responses: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Responses'];
      excel.setDefaultSheet('Responses');
      
      // Header row
      List<String> headers = ['Date', 'Student Name', 'Enrollment ID'];
      for (var q in widget.schema) {
        headers.add(q['question'].toString());
      }
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Data rows
      for (var fb in _responses) {
        final student = fb['students'] as Map<String, dynamic>? ?? {};
        final formResponses = fb['form_responses'] as Map<String, dynamic>? ?? {};
        
        List<CellValue> row = [
          TextCellValue(fb['created_at']?.toString() ?? ''),
          TextCellValue(student['name']?.toString() ?? 'Unknown'),
          TextCellValue(student['enrollment_id']?.toString() ?? 'Unknown'),
        ];
        
        for (var q in widget.schema) {
          final qId = q['id'].toString();
          row.add(TextCellValue(formResponses[qId]?.toString() ?? ''));
        }
        
        sheetObject.appendRow(row);
      }

      final fileBytes = excel.encode()!;
      final String fileName = 'Feedback_${widget.roleTitle.replaceAll(' ', '_')}.xlsx';

      final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
      if (result == null) {
        setState(() => _isExporting = false);
        return; // User canceled
      }

      final Uint8List uint8ListBytes = Uint8List.fromList(fileBytes);
      final XFile xFile = XFile.fromData(
        uint8ListBytes,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: fileName,
      );
      
      await xFile.saveTo(result.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export successful!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.roleTitle} Responses', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_responses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportToExcel,
                icon: _isExporting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export .xlsx'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
              ? const Center(
                  child: Text('No responses yet for this form.', style: TextStyle(color: Color(0xFF64748B))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DataTable(
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          dataTextStyle: const TextStyle(color: Color(0xFF334155)),
                          columns: [
                            const DataColumn(label: Text('Student')),
                            const DataColumn(label: Text('Date')),
                            ...widget.schema.map((q) => DataColumn(label: Text(q['question'].toString()))).toList(),
                          ],
                          rows: _responses.map((fb) {
                            final student = fb['students'] as Map<String, dynamic>? ?? {};
                            final formResponses = fb['form_responses'] as Map<String, dynamic>? ?? {};
                            final dateStr = fb['created_at']?.toString() ?? '';
                            final date = DateTime.tryParse(dateStr);
                            final formattedDate = date != null ? '${date.day}/${date.month}/${date.year}' : 'Unknown';

                            return DataRow(
                              cells: [
                                DataCell(Text(student['name']?.toString() ?? 'Unknown')),
                                DataCell(Text(formattedDate)),
                                ...widget.schema.map((q) {
                                  final qId = q['id'].toString();
                                  return DataCell(Text(formResponses[qId]?.toString() ?? '-'));
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
