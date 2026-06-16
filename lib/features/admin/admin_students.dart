import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/student_avatar.dart';

class AdminStudents extends StatefulWidget {
  const AdminStudents({super.key});
  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  final q = TextEditingController();

  String initials(String n) =>
      n.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

  void addStudent() {
    final sIdCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final gNameCtrl = TextEditingController();
    final gContactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add New Student',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _buildTextField(sIdCtrl, 'Student ID (e.g., S001)'),
              _buildTextField(nameCtrl, 'Full Name'),
              _buildTextField(ageCtrl, 'Age (e.g., 13 years old)'),
              _buildTextField(gradeCtrl, 'Grade'),
              _buildTextField(schoolCtrl, 'School'),
              _buildTextField(gNameCtrl, 'Guardian Name'),
              _buildTextField(gContactCtrl, 'Guardian Contact'),
              const Divider(height: 20),
              _buildTextField(emailCtrl, 'Email (for Firebase Auth)'),
              _buildTextField(passCtrl, 'Password (for Firebase Auth)',
                  obscure: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveStudent(
                    context,
                    sIdCtrl.text,
                    nameCtrl.text,
                    ageCtrl.text,
                    gradeCtrl.text,
                    schoolCtrl.text,
                    gNameCtrl.text,
                    gContactCtrl.text,
                    emailCtrl.text,
                    passCtrl.text,
                  ),
                  child: const Text('Create Student'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void editStudent(Student student) {
    final nameCtrl = TextEditingController(text: student.sName);
    final ageCtrl = TextEditingController(text: student.age);
    final gradeCtrl = TextEditingController(text: student.grade);
    final schoolCtrl = TextEditingController(text: student.school);
    final gNameCtrl = TextEditingController(text: student.guardianName);
    final gContactCtrl = TextEditingController(text: student.guardianContact);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Student',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _buildTextField(nameCtrl, 'Full Name'),
              _buildTextField(ageCtrl, 'Age'),
              _buildTextField(gradeCtrl, 'Grade'),
              _buildTextField(schoolCtrl, 'School'),
              _buildTextField(gNameCtrl, 'Guardian Name'),
              _buildTextField(gContactCtrl, 'Guardian Contact'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStudent(
                    context,
                    student.sId,
                    nameCtrl.text,
                    ageCtrl.text,
                    gradeCtrl.text,
                    schoolCtrl.text,
                    gNameCtrl.text,
                    gContactCtrl.text,
                  ),
                  child: const Text('Update Student'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void deleteStudent(Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.sName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudentConfirmed(student.sId, student.email);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStudent(
    BuildContext context,
    String sId,
    String name,
    String age,
    String grade,
    String school,
    String gName,
    String gContact,
    String email,
    String pass,
  ) async {
    if (sId.isEmpty || name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final data = {
        'sId': sId,
        'sName': name,
        'age': age,
        'grade': grade,
        'school': school,
        'guardianName': gName,
        'guardianContact': gContact,
        'email': email,
        'password': pass,
        'enrolledSubject': [],
        'enrolledTeacher': [],
      };

      await FirebaseService.instance.addStudent(data, email, pass);
      Navigator.pop(context);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Student created successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateStudent(
    BuildContext context,
    String sId,
    String name,
    String age,
    String grade,
    String school,
    String gName,
    String gContact,
  ) async {
    try {
      final data = {
        'sName': name,
        'age': age,
        'grade': grade,
        'school': school,
        'guardianName': gName,
        'guardianContact': gContact,
      };

      await FirebaseService.instance.updateStudent(sId, data);
      Navigator.pop(context);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Student updated successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteStudentConfirmed(String sId, String email) async {
    try {
      await FirebaseService.instance.deleteStudent(sId, email);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Student deleted successfully'),
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
      title: 'Students Management',
      floating: FloatingActionButton(
        onPressed: addStudent,
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
                hintText: 'Search by name, grade, school...',
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
            child: FutureBuilder<List<Student>>(
              future: FirebaseService.instance.getAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var students = snapshot.data ?? [];
                students = students
                    .where((s) =>
                        s.sName
                            .toLowerCase()
                            .contains(q.text.toLowerCase()) ||
                        s.school
                            .toLowerCase()
                            .contains(q.text.toLowerCase()) ||
                        s.grade.contains(q.text))
                    .toList();

                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final student = students[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/admin/student/detail',
                            arguments: student.sId,
                          );
                        },
                        leading: StudentAvatar(sId: student.sId, radius: 24),
                        title: Text(student.sName),
                        subtitle: Text(
                            '${student.school} | Grade ${student.grade}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: const Text('View Profile'),
                              onTap: () => Future(() {
                                Navigator.pushNamed(
                                  context,
                                  '/admin/student/detail',
                                  arguments: student.sId,
                                );
                              }),
                            ),
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () =>
                                  Future(() => editStudent(student)),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () =>
                                  Future(() => deleteStudent(student)),
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

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}