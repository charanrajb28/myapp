import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/internship.dart';

class StudentDynamicFeedbackScreen extends StatefulWidget {
  final StudentInternship internship;

  const StudentDynamicFeedbackScreen({super.key, required this.internship});

  @override
  State<StudentDynamicFeedbackScreen> createState() => _StudentDynamicFeedbackScreenState();
}

class _StudentDynamicFeedbackScreenState extends State<StudentDynamicFeedbackScreen> {
  bool _isSubmitting = false;
  bool _isSuccess = false;
  final _formKey = GlobalKey<FormState>();
  
  // Store responses where key is question id
  final Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    final schema = widget.internship.feedbackFormSchema;
    if (schema != null) {
      for (final q in schema) {
        if (q is Map) {
          final qId = q['id'].toString();
          if (q['type'] == 'multiple_choice') {
            _responses[qId] = null; // for radio button
          } else {
            _responses[qId] = '';
          }
        }
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check multiple choice required
    final schema = widget.internship.feedbackFormSchema ?? [];
    for (final q in schema) {
      if (q is Map && q['type'] == 'multiple_choice' && (q['required'] == true)) {
        if (_responses[q['id'].toString()] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please answer all required multiple choice questions')),
          );
          return;
        }
      }
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final studentRes = await Supabase.instance.client
          .from('students')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final companyRes = await Supabase.instance.client
          .from('internships')
          .select('company_id')
          .eq('id', widget.internship.id)
          .single();

      await Supabase.instance.client.from('feedbacks').insert({
        'student_id': studentRes['id'],
        'company_id': companyRes['company_id'],
        'type': 'Final Feedback',
        'comment': 'Final Internship Feedback form submitted.',
        'form_responses': _responses,
      });

      setState(() => _isSuccess = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton()),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              const Text('Thank You!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              const Text('Your final feedback has been submitted successfully.', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Return to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    final schema = widget.internship.feedbackFormSchema;
    if (schema == null || schema.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Final Feedback', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Feedback form is not yet available for this role.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Final Feedback', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('End of Internship Feedback',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Please complete this final feedback for your role at ${widget.internship.company}.',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 32),

              ...schema.map((qRaw) {
                if (qRaw is! Map) return const SizedBox.shrink();
                final q = qRaw;
                final qId = q['id'].toString();
                final bool isRequired = q['required'] == true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
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
                        children: [
                          Expanded(
                            child: Text(
                              q['question']?.toString() ?? '',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ),
                          if (isRequired)
                            const Text('*', style: TextStyle(color: Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (q['type'] == 'multiple_choice')
                        ...((q['options'] as List?) ?? []).map((opt) {
                          final optText = opt.toString();
                          return RadioListTile<String>(
                            title: Text(optText, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                            value: optText,
                            groupValue: _responses[qId],
                            onChanged: (val) {
                              setState(() {
                                _responses[qId] = val;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF3B82F6),
                          );
                        })
                      else if (q['type'] == 'long_text')
                        TextFormField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter your answer',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (isRequired && (val == null || val.trim().isEmpty)) {
                              return 'This field is required';
                            }
                            return null;
                          },
                          onSaved: (val) => _responses[qId] = val,
                        )
                      else
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter your answer',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (isRequired && (val == null || val.trim().isEmpty)) {
                              return 'This field is required';
                            }
                            return null;
                          },
                          onSaved: (val) => _responses[qId] = val,
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Final Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
