import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFormBuilderScreen extends StatefulWidget {
  final String internshipId;

  const AdminFormBuilderScreen({super.key, required this.internshipId});

  @override
  State<AdminFormBuilderScreen> createState() => _AdminFormBuilderScreenState();
}

class _AdminFormBuilderScreenState extends State<AdminFormBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadFormSchema();
  }

  Future<void> _loadFormSchema() async {
    try {
      final res = await Supabase.instance.client
          .from('internships')
          .select('feedback_form_schema')
          .eq('id', widget.internshipId)
          .single();

      final schema = res['feedback_form_schema'];
      if (schema != null && schema is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(schema);
        });
      }
    } catch (e) {
      debugPrint('Error loading form schema: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFormSchema() async {
    if (_questions.isNotEmpty && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('internships')
          .update({'feedback_form_schema': _questions})
          .eq('id', widget.internshipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form schema saved successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving form: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'short_text', // short_text, long_text, multiple_choice
        'question': '',
        'options': <String>['Option 1'], // For multiple choice
        'required': true,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Configure Feedback Form',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveFormSchema,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Form', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined, size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      const Text('No Questions Added',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      const Text('Start building your feedback form.',
                          style: TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _questions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _questions.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 48.0),
                        child: OutlinedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Another Question'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                            foregroundColor: const Color(0xFF3B82F6),
                          ),
                        ),
                      );
                    }

                    final q = _questions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: const Center(
                              child: Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButton<String>(
                                    value: q['type'],
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                    items: const [
                                      DropdownMenuItem(value: 'short_text', child: Text('Short Text')),
                                      DropdownMenuItem(value: 'long_text', child: Text('Long Text')),
                                      DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => q['type'] = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: q['question'],
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  decoration: InputDecoration(
                                    hintText: 'Question Title',
                                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter a question';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) => q['question'] = val,
                                ),
                                const SizedBox(height: 16),
                                if (q['type'] == 'multiple_choice') ...[
                                  ...List.generate((q['options'] as List).length, (optIndex) {
                                    final options = q['options'] as List;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: options[optIndex].toString(),
                                              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                                border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                                              ),
                                              validator: (val) {
                                                if (val == null || val.trim().isEmpty) {
                                                  return 'Option cannot be empty';
                                                }
                                                return null;
                                              },
                                              onChanged: (val) => options[optIndex] = val,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                options.removeAt(optIndex);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  Row(
                                    children: [
                                      const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 18),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            (q['options'] as List).add('Option ${(q['options'] as List).length + 1}');
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF3B82F6),
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Add option', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      q['type'] == 'long_text' ? 'Long answer text' : 'Short answer text',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const Divider(color: Color(0xFFF1F5F9), height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () => _removeQuestion(index),
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF64748B), size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Delete Question',
                                    ),
                                    const SizedBox(width: 12),
                                    Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
                                    const SizedBox(width: 12),
                                    const Text('Required', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 13)),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch.adaptive(
                                        value: q['required'] ?? true,
                                        onChanged: (val) {
                                          setState(() => q['required'] = val);
                                        },
                                        activeColor: const Color(0xFF3B82F6),
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
                  },
                ),
              ),
    );
  }
}
