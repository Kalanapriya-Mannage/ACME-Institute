import 'package:flutter/material.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminSubjects extends StatefulWidget {
  const AdminSubjects({super.key});
  @override
  State<AdminSubjects> createState() => _AdminSubjectsState();
}

class _AdminSubjectsState extends State<AdminSubjects> {
  final q = TextEditingController();

  void addSubject() {
    final subIdCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final gradesCtrl = TextEditingController();
    List<String> selectedTeacherIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TeacherSelectionModal(
        title: 'Add New Subject',
        subIdCtrl: subIdCtrl,
        nameCtrl: nameCtrl,
        gradesCtrl: gradesCtrl,
        selectedTeacherIds: selectedTeacherIds,
        onSave: (subId, name, grades, teacherIds) =>
            _saveSubject(context, subId, name, grades, teacherIds),
      ),
    );
  }

  void editSubject(Subject subject) {
    final nameCtrl = TextEditingController(text: subject.subName);
    final gradesCtrl = TextEditingController(text: subject.grades.join(','));
    List<String> selectedTeacherIds = List.from(subject.teacherIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TeacherSelectionModal(
        title: 'Edit Subject',
        subId: subject.subId,
        nameCtrl: nameCtrl,
        gradesCtrl: gradesCtrl,
        selectedTeacherIds: selectedTeacherIds,
        onSave: (_, name, grades, teacherIds) =>
            _updateSubject(context, subject.subId, name, grades, teacherIds),
        isEditing: true,
      ),
    );
  }

  void deleteSubject(Subject subject) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Are you sure you want to delete ${subject.subName}? Students enrolled in this subject will be automatically unenrolled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubjectConfirmed(subject.subId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSubject(
    BuildContext context,
    String subId,
    String name,
    String grades,
    List<String> teacherIds,
  ) async {
    if (subId.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final gradesList =
          grades.split(',').map((g) => g.trim()).toList();

      final data = {
        'subId': subId,
        'subName': name,
        'grades': gradesList,
        'teacherIds': teacherIds,
      };

      await FirebaseService.instance.addSubject(data);
      Navigator.pop(context);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Subject created successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateSubject(
    BuildContext context,
    String subId,
    String name,
    String grades,
    List<String> teacherIds,
  ) async {
    try {
      final gradesList =
          grades.split(',').map((g) => g.trim()).toList();

      final data = {
        'subName': name,
        'grades': gradesList,
        'teacherIds': teacherIds,
      };

      await FirebaseService.instance.updateSubject(subId, data);
      Navigator.pop(context);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Subject updated successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteSubjectConfirmed(String subId) async {
    try {
      await FirebaseService.instance.deleteSubject(subId);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Subject deleted successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Subjects Management',
      floating: FloatingActionButton(
        onPressed: addSubject,
        backgroundColor: const Color(0xFFFF1800),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: q,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search subjects...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Subject>>(
              future: FirebaseService.instance.getAllSubjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var subjects = snapshot.data ?? [];
                subjects = subjects
                    .where((s) =>
                        s.subName
                            .toLowerCase()
                            .contains(q.text.toLowerCase()))
                    .toList();

                if (subjects.isEmpty) {
                  return const Center(child: Text('No subjects found.'));
                }

                return ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (_, i) {
                    final subject = subjects[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.menu_book,
                            color: Color(0xFFFF1800)),
                        title: Text(subject.subName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject.gradesDisplay),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () =>
                                  Future(() => editSubject(subject)),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () =>
                                  Future(() => deleteSubject(subject)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _TeacherSelectionModal extends StatefulWidget {
  final String title;
  final String? subId;
  final TextEditingController? subIdCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController gradesCtrl;
  final List<String> selectedTeacherIds;
  final Function(String, String, String, List<String>) onSave;
  final bool isEditing;

  const _TeacherSelectionModal({
    required this.title,
    this.subId,
    this.subIdCtrl,
    required this.nameCtrl,
    required this.gradesCtrl,
    required this.selectedTeacherIds,
    required this.onSave,
    this.isEditing = false,
  });

  @override
  State<_TeacherSelectionModal> createState() => _TeacherSelectionModalState();
}

class _TeacherSelectionModalState extends State<_TeacherSelectionModal> {
  late List<String> _selectedTeachers;

  @override
  void initState() {
    super.initState();
    _selectedTeachers = List.from(widget.selectedTeacherIds);
  }

  void _handleSave() {
    final subIdValue = widget.subId ?? widget.subIdCtrl?.text ?? '';
    if (subIdValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject ID cannot be empty')));
      return;
    }
    widget.onSave(
        subIdValue, widget.nameCtrl.text, widget.gradesCtrl.text, _selectedTeachers);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            if (!widget.isEditing && widget.subIdCtrl != null)
              TextField(
                controller: widget.subIdCtrl,
                decoration: const InputDecoration(labelText: 'Subject ID'),
              ),
            TextField(
              controller: widget.nameCtrl,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            TextField(
              controller: widget.gradesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Grades (comma-separated: 6,7,8,9,10,11)'),
            ),
            const SizedBox(height: 12),
            const Text('Select Teachers:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FutureBuilder<List<Teacher>>(
              future: FirebaseService.instance.getAllTeachers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final teachers = snapshot.data ?? [];
                return Column(
                  children: teachers.map((teacher) {
                    return CheckboxListTile(
                      value: _selectedTeachers.contains(teacher.tId),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedTeachers.add(teacher.tId);
                          } else {
                            _selectedTeachers.remove(teacher.tId);
                          }
                        });
                      },
                      title: Text(teacher.name),
                      subtitle: Text(teacher.subject),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: Text(
                    widget.isEditing ? 'Update Subject' : 'Create Subject'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
