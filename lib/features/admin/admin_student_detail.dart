import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../models/result_model.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminStudentDetail extends StatefulWidget {
  final String studentId;

  const AdminStudentDetail({super.key, required this.studentId});

  @override
  State<AdminStudentDetail> createState() => _AdminStudentDetailState();
}

class _AdminStudentDetailState extends State<AdminStudentDetail> {
  late Future<Student?> _studentFuture;
  late Future<List<Subject>> _subjectsFuture;
  Future<List<Teacher>>? _subjectTeachersFuture;
  List<Teacher> _subjectTeachers = [];
  Future<ResultModel?>? _existingResultFuture;
  late Future<List<ResultModel>> _studentResultsFuture;

  String? _selectedSubjectId;
  String? _selectedTeacherId;

  final _term1Marks = TextEditingController();
  String? _term1Grade;
  final _term2Marks = TextEditingController();
  String? _term2Grade;
  final _term3Marks = TextEditingController();
  String? _term3Grade;

  final _gradeOptions = ['A+', 'A', 'B', 'C', 'D', 'F'];

  @override
  void initState() {
    super.initState();
    _studentFuture = FirebaseService.instance.getStudentById(widget.studentId);
    _subjectsFuture = FirebaseService.instance.getAllSubjects();
    _studentResultsFuture = FirebaseService.instance.getAllResultsForStudent(widget.studentId);
  }

  @override
  void dispose() {
    _term1Marks.dispose();
    _term2Marks.dispose();
    _term3Marks.dispose();
    super.dispose();
  }

  void _resetResultFields() {
    _term1Marks.clear();
    _term1Grade = null;
    _term2Marks.clear();
    _term2Grade = null;
    _term3Marks.clear();
    _term3Grade = null;
  }

  void _applyExistingResult(ResultModel result) {
    _term1Marks.text = result.term1.marks;
    _term1Grade = result.term1.grade;
    _term2Marks.text = result.term2.marks;
    _term2Grade = result.term2.grade;
    _term3Marks.text = result.term3.marks;
    _term3Grade = result.term3.grade;
  }

  Future<void> _saveResult(Student student, Subject subject, Teacher teacher) async {
    if (_selectedSubjectId == null || _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select subject and teacher before saving results.')),
      );
      return;
    }

    debugPrint('GRADE_LOG: Save called - Current state: T1=$_term1Grade, T2=$_term2Grade, T3=$_term3Grade');

    final resultId = '${student.sId}_$_selectedSubjectId';
    final result = ResultModel(
      resultId: resultId,
      sId: student.sId,
      subId: subject.subId,
      subName: subject.subName,
      teacherId: teacher.tId,
      teacherName: teacher.name,
      term1: TermResult(
        marks: _term1Marks.text.trim(),
        grade: (_term1Grade ?? '').trim(),
      ),
      term2: TermResult(
        marks: _term2Marks.text.trim(),
        grade: (_term2Grade ?? '').trim(),
      ),
      term3: TermResult(
        marks: _term3Marks.text.trim(),
        grade: (_term3Grade ?? '').trim(),
      ),
    );

    debugPrint('GRADE_LOG: ResultModel created - T1: m=${result.term1.marks} g=${result.term1.grade}, T2: m=${result.term2.marks} g=${result.term2.grade}, T3: m=${result.term3.marks} g=${result.term3.grade}');
    debugPrint('GRADE_LOG: ResultModel.toMap()=${result.toMap()}');

    try {
      await FirebaseService.instance.saveResult(result);
      if (!mounted) return;

      if (!student.enrolledSubject.contains(subject.subId) ||
          !student.enrolledTeacher.contains(teacher.tId)) {
        await FirebaseService.instance.enrollStudentInSubject(
          student.sId,
          subject.subId,
          teacher.tId,
        );
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result saved successfully.')),
      );
      _resetResultFields();
      setState(() {
        _studentFuture = FirebaseService.instance.getStudentById(widget.studentId);
        _studentResultsFuture = FirebaseService.instance.getAllResultsForStudent(widget.studentId);
        _existingResultFuture = FirebaseService.instance.getStudentResult(student.sId, subject.subId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save result: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Student Profile',
      subtitle: 'View student information and add results',
      body: FutureBuilder<Student?>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final student = snapshot.data;
          if (student == null) {
            return const Center(child: Text('Student not found.'));
          }

          return FutureBuilder<List<Subject>>(
            future: _subjectsFuture,
            builder: (context, subjectSnapshot) {
              if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final subjects = subjectSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(student),
                  const SizedBox(height: 16),
                  const Text('Add / Update Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId != null && subjects.any((s) => s.subId == _selectedSubjectId)
                        ? _selectedSubjectId
                        : null,
                    hint: const Text('Choose subject'),
                    items: _distinctDropdownItems(subjects
                        .map((subject) => DropdownMenuItem(
                              value: subject.subId,
                              child: Text(subject.subName),
                            ))
                        .toList()),
                    onChanged: (value) {
                      if (value == null) return;
                      final subject = subjects.firstWhere((subject) => subject.subId == value);
                      final fetchResultFuture = FirebaseService.instance.getStudentResult(student.sId, value);
                      setState(() {
                        _selectedSubjectId = value;
                        _selectedTeacherId = null;
                        _subjectTeachersFuture = FirebaseService.instance.getTeachersByIds(subject.teacherIds);
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
                  const SizedBox(height: 12),
                  FutureBuilder<List<Teacher>>( 
                    future: _subjectTeachersFuture,
                    builder: (context, teacherSnapshot) {
                      if (_subjectTeachersFuture == null) {
                        return const SizedBox.shrink();
                      }
                      if (teacherSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final teachers = teacherSnapshot.data ?? [];
                      _subjectTeachers = teachers;
                      if (teachers.isEmpty) {
                        return const Text('No teachers are linked to this subject.');
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedTeacherId != null && teachers.any((t) => t.tId == _selectedTeacherId)
                            ? _selectedTeacherId
                            : null,
                        hint: const Text('Choose teacher'),
                        items: _distinctDropdownItems(teachers
                            .map((teacher) => DropdownMenuItem(
                                  value: teacher.tId,
                                  child: Text(teacher.name),
                                ))
                            .toList()),
                        onChanged: (value) {
                          setState(() {
                            _selectedTeacherId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedSubjectId != null && _existingResultFuture != null)
                    FutureBuilder<ResultModel?>(
                      future: _existingResultFuture,
                      builder: (context, resultSnapshot) {
                        if (resultSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildTermRow('1st Term', _term1Marks, _term1Grade, (value) {
                    debugPrint('GRADE_LOG: Term1 selected: $value');
                    setState(() {
                      _term1Grade = value;
                      debugPrint('GRADE_LOG: Term1 state updated to: $_term1Grade');
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildTermRow('2nd Term', _term2Marks, _term2Grade, (value) {
                    debugPrint('GRADE_LOG: Term2 selected: $value');
                    setState(() {
                      _term2Grade = value;
                      debugPrint('GRADE_LOG: Term2 state updated to: $_term2Grade');
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildTermRow('3rd Term', _term3Marks, _term3Grade, (value) {
                    debugPrint('GRADE_LOG: Term3 selected: $value');
                    setState(() {
                      _term3Grade = value;
                      debugPrint('GRADE_LOG: Term3 state updated to: $_term3Grade');
                    });
                  }),
                  const SizedBox(height: 20),
                                  ElevatedButton(
                      onPressed: () {
                        if (_selectedSubjectId == null || _selectedTeacherId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select subject and teacher.')),
                          );
                          return;
                        }

                        final subject = subjects.firstWhere(
                          (subject) => subject.subId == _selectedSubjectId,
                          orElse: () => Subject(subId: '', subName: '', grades: [], teacherIds: []),
                        );
                        final teacher = _subjectTeachers.firstWhere(
                          (t) => t.tId == _selectedTeacherId,
                          orElse: () => Teacher(
                            tId: '',
                            name: '',
                            subject: '',
                            grades: [],
                            experience: '',
                            qualification: '',
                            whatsapp: '',
                            monthlyFee: '',
                            email: '',
                            password: '',
                          ),
                        );
                        if (teacher.tId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a valid teacher.')),
                          );
                          return;
                        }
                        _saveResult(student, subject, teacher);
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Results'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Student Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<ResultModel>>(
                    future: _studentResultsFuture,
                    builder: (context, resultsSnapshot) {
                      if (resultsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final results = resultsSnapshot.data ?? [];
                      if (results.isEmpty) {
                        return const Text('No results entered yet.');
                      }
                      return Column(
                        children: results.map((result) => _buildResultCard(result)).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Student student) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.sName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ID: ${student.sId}'),
            Text('Grade: ${student.grade}'),
            Text('School: ${student.school}'),
            const SizedBox(height: 8),
            Text('Guardian: ${student.guardianName}'),
            Text('Contact: ${student.guardianContact}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTermRow(String label, TextEditingController marksCtrl, String? gradeValue, Function(String?) onGradeChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: marksCtrl,
                decoration: InputDecoration(
                  labelText: 'Marks',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: (gradeValue == null || gradeValue.isEmpty || !_gradeOptions.contains(gradeValue))
                    ? null
                    : gradeValue,
                decoration: InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                hint: const Text('Select grade'),
                items: _gradeOptions
                    .map((grade) => DropdownMenuItem(value: grade, child: Text(grade)))
                    .toList(),
                onChanged: onGradeChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<DropdownMenuItem<T>> _distinctDropdownItems<T>(List<DropdownMenuItem<T>> items) {
    final seen = <T?>{};
    return items.where((item) => seen.add(item.value)).toList();
  }

  Widget _buildResultCard(ResultModel result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.subName, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (result.teacherName != null && result.teacherName!.isNotEmpty)
              Text('Teacher: ${result.teacherName}'),
            const SizedBox(height: 8),
            Text('1st Term: ${result.term1.marks} (${result.term1.grade})'),
            Text('2nd Term: ${result.term2.marks} (${result.term2.grade})'),
            Text('3rd Term: ${result.term3.marks} (${result.term3.grade})'),
          ],
        ),
      ),
    );
  }
}
