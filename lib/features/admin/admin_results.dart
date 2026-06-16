import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../models/result_model.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminResults extends StatefulWidget {
  const AdminResults({super.key});

  @override
  State<AdminResults> createState() => _AdminResultsState();
}

class _AdminResultsState extends State<AdminResults> {
  late Future<List<Student>> _studentsFuture;
  Future<List<Subject>>? _studentSubjectsFuture;
  Future<ResultModel?>? _existingResultFuture;

  String? _selectedStudentId;
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  final _term1Marks = TextEditingController();
  final _term1Grade = TextEditingController();
  final _term2Marks = TextEditingController();
  final _term2Grade = TextEditingController();
  final _term3Marks = TextEditingController();
  final _term3Grade = TextEditingController();

  final _gradeOptions = ['A+', 'A', 'B', 'C', 'D', 'F'];

  @override
  void initState() {
    super.initState();
    _studentsFuture = FirebaseService.instance.getAllStudents();
  }

  @override
  void dispose() {
    _term1Marks.dispose();
    _term1Grade.dispose();
    _term2Marks.dispose();
    _term2Grade.dispose();
    _term3Marks.dispose();
    _term3Grade.dispose();
    super.dispose();
  }

  void _resetResultFields() {
    _term1Marks.clear();
    _term1Grade.clear();
    _term2Marks.clear();
    _term2Grade.clear();
    _term3Marks.clear();
    _term3Grade.clear();
  }

  void _applyExistingResult(ResultModel result) {
    _term1Marks.text = result.term1.marks;
    _term1Grade.text = result.term1.grade;
    _term2Marks.text = result.term2.marks;
    _term2Grade.text = result.term2.grade;
    _term3Marks.text = result.term3.marks;
    _term3Grade.text = result.term3.grade;
  }

  Future<void> _saveResults() async {
    if (_selectedStudentId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student and subject first.')),
      );
      return;
    }

    final student = await FirebaseService.instance.getStudentById(_selectedStudentId!);
    if (!mounted) return;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected student was not found.')),
      );
      return;
    }

    final resultId = '${student.sId}_$_selectedSubjectId';
    final result = ResultModel(
      resultId: resultId,
      sId: student.sId,
      subId: _selectedSubjectId!,
      subName: _selectedSubjectName ?? '',
      term1: TermResult(
          marks: _term1Marks.text.trim().isEmpty ? '' : _term1Marks.text.trim(),
          grade: _term1Grade.text.trim().isEmpty ? '' : _term1Grade.text.trim()),
      term2: TermResult(
          marks: _term2Marks.text.trim().isEmpty ? '' : _term2Marks.text.trim(),
          grade: _term2Grade.text.trim().isEmpty ? '' : _term2Grade.text.trim()),
      term3: TermResult(
          marks: _term3Marks.text.trim().isEmpty ? '' : _term3Marks.text.trim(),
          grade: _term3Grade.text.trim().isEmpty ? '' : _term3Grade.text.trim()),
    );

    try {
      await FirebaseService.instance.saveResult(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Results saved successfully')),
      );
      _resetResultFields();
      setState(() {
        _selectedStudentId = null;
        _selectedSubjectId = null;
        _selectedSubjectName = null;
        _studentSubjectsFuture = null;
        _existingResultFuture = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save results. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Results Management',
      subtitle: 'Add or update results for students',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final students = studentSnapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Student', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStudentId,
                      hint: const Text('Choose a student'),
                      items: students
                          .map(
                            (student) => DropdownMenuItem(
                              value: student.sId,
                              child: Text('${student.sName} (${student.sId})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final student = students.firstWhere(
                            (s) => s.sId == value,
                            orElse: () => students.first);
                        setState(() {
                          _selectedStudentId = value;
                          _selectedSubjectId = null;
                          _selectedSubjectName = null;
                          _existingResultFuture = null;
                          _studentSubjectsFuture = FirebaseService.instance.getSubjectsByIds(student.enrolledSubject);
                          _resetResultFields();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_studentSubjectsFuture != null)
                      FutureBuilder<List<Subject>>(
                        future: _studentSubjectsFuture,
                        builder: (context, subjectSnapshot) {
                          if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final subjects = subjectSnapshot.data ?? [];
                          if (subjects.isEmpty) {
                            return const Text('This student has no enrolled subjects.');
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSubjectId,
                                hint: const Text('Choose a subject'),
                                items: subjects
                                    .map(
                                      (subject) => DropdownMenuItem(
                                        value: subject.subId,
                                        child: Text('${subject.subName} (${subject.subId})'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  final subject = subjects.firstWhere(
                                      (s) => s.subId == value,
                                      orElse: () => subjects.first);
                                final fetchResultFuture = FirebaseService.instance.getStudentResult(
                                  _selectedStudentId!,
                                  value,
                                );
                                setState(() {
                                  _selectedSubjectId = value;
                                  _selectedSubjectName = subject.subName;
                                  _existingResultFuture = fetchResultFuture;
                                  _resetResultFields();
                                });
                                fetchResultFuture.then((result) {
                                  if (!mounted) return;
                                  if (_existingResultFuture != fetchResultFuture) return;
                                  if (result != null) {
                                    setState(() {
                                      _applyExistingResult(result);
                                    });
                                  }
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    if (_selectedSubjectId != null) ...[
                      if (_existingResultFuture != null)
                        FutureBuilder<ResultModel?>(
                          future: _existingResultFuture,
                          builder: (context, resultSnapshot) {
                            if (resultSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      const Text('1st Term', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _term1Marks,
                              decoration: InputDecoration(
                                labelText: 'Marks',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _term1Grade.text.isEmpty ? null : _term1Grade.text,
                              decoration: InputDecoration(
                                labelText: 'Grade',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _gradeOptions
                                  .map((grade) => DropdownMenuItem(
                                        value: grade,
                                        child: Text(grade),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _term1Grade.text = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('2nd Term', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _term2Marks,
                              decoration: InputDecoration(
                                labelText: 'Marks',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _term2Grade.text.isEmpty ? null : _term2Grade.text,
                              decoration: InputDecoration(
                                labelText: 'Grade',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _gradeOptions
                                  .map((grade) => DropdownMenuItem(
                                        value: grade,
                                        child: Text(grade),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _term2Grade.text = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('3rd Term', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _term3Marks,
                              decoration: InputDecoration(
                                labelText: 'Marks',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _term3Grade.text.isEmpty ? null : _term3Grade.text,
                              decoration: InputDecoration(
                                labelText: 'Grade',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _gradeOptions
                                  .map((grade) => DropdownMenuItem(
                                        value: grade,
                                        child: Text(grade),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _term3Grade.text = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveResults,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFFF1800),
                        ),
                        child: const Text('Save Results'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
