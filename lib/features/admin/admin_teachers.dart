import 'package:flutter/material.dart';
import '../../models/teacher.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminTeachers extends StatefulWidget {
  const AdminTeachers({super.key});
  @override
  State<AdminTeachers> createState() => _AdminTeachersState();
}

class _AdminTeachersState extends State<AdminTeachers> {
  final q = TextEditingController();
  String initials(String n) =>
      n.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

  void addTeacher() {
    final tIdCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final gradesCtrl = TextEditingController();
    final qualCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
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
              const Text('Add New Teacher',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _buildTextField(tIdCtrl, 'Teacher ID (e.g., T001)'),
              _buildTextField(nameCtrl, 'Full Name'),
              _buildTextField(subjectCtrl, 'Subject'),
              _buildTextField(gradesCtrl, 'Grades (comma-separated: 6,7,8,9,10,11)'),
              _buildTextField(qualCtrl, 'Qualifications'),
              _buildTextField(expCtrl, 'Experience'),
              _buildTextField(contactCtrl, 'WhatsApp Contact'),
              _buildTextField(feeCtrl, 'Monthly Fee (e.g., Rs. 1200/=)'),
              const Divider(height: 20),
              _buildTextField(emailCtrl, 'Email (for Firebase Auth)'),
              _buildTextField(passCtrl, 'Password (for Firebase Auth)',
                  obscure: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveTeacher(
                    context,
                    tIdCtrl.text,
                    nameCtrl.text,
                    subjectCtrl.text,
                    gradesCtrl.text,
                    qualCtrl.text,
                    expCtrl.text,
                    contactCtrl.text,
                    feeCtrl.text,
                    emailCtrl.text,
                    passCtrl.text,
                  ),
                  child: const Text('Create Teacher'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void editTeacher(Teacher teacher) {
    final tIdCtrl = TextEditingController(text: teacher.tId);
    final nameCtrl = TextEditingController(text: teacher.name);
    final subjectCtrl = TextEditingController(text: teacher.subject);
    final gradesCtrl = TextEditingController(text: teacher.grades.join(','));
    final qualCtrl = TextEditingController(text: teacher.qualification);
    final expCtrl = TextEditingController(text: teacher.experience);
    final contactCtrl = TextEditingController(text: teacher.whatsapp);
    final feeCtrl = TextEditingController(text: teacher.monthlyFee);

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
              const Text('Edit Teacher',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              _buildTextField(nameCtrl, 'Full Name'),
              _buildTextField(subjectCtrl, 'Subject'),
              _buildTextField(gradesCtrl, 'Grades (comma-separated)'),
              _buildTextField(qualCtrl, 'Qualifications'),
              _buildTextField(expCtrl, 'Experience'),
              _buildTextField(contactCtrl, 'WhatsApp Contact'),
              _buildTextField(feeCtrl, 'Monthly Fee'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateTeacher(
                    context,
                    teacher.tId,
                    nameCtrl.text,
                    subjectCtrl.text,
                    gradesCtrl.text,
                    qualCtrl.text,
                    expCtrl.text,
                    contactCtrl.text,
                    feeCtrl.text,
                  ),
                  child: const Text('Update Teacher'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void deleteTeacher(Teacher teacher) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTeacherConfirmed(teacher.tId, teacher.email);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTeacher(
    BuildContext context,
    String tId,
    String name,
    String subject,
    String grades,
    String qual,
    String exp,
    String contact,
    String fee,
    String email,
    String pass,
  ) async {
    if (tId.isEmpty ||
        name.isEmpty ||
        subject.isEmpty ||
        email.isEmpty ||
        pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final gradesList =
          grades.split(',').map((g) => g.trim()).toList();

      final data = {
        'tId': tId,
        'name': name,
        'subject': subject,
        'grades': gradesList,
        'experience': exp,
        'qualification': qual,
        'whatsapp': contact,
        'monthlyFee': fee,
        'email': email,
        'password': pass,
      };

      await FirebaseService.instance.addTeacher(data, email, pass);
      Navigator.pop(context);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Teacher created successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateTeacher(
    BuildContext context,
    String tId,
    String name,
    String subject,
    String grades,
    String qual,
    String exp,
    String contact,
    String fee,
  ) async {
    try {
      final gradesList =
          grades.split(',').map((g) => g.trim()).toList();

      final data = {
        'name': name,
        'subject': subject,
        'grades': gradesList,
        'experience': exp,
        'qualification': qual,
        'whatsapp': contact,
        'monthlyFee': fee,
      };

      await FirebaseService.instance.updateTeacher(tId, data);
      Navigator.pop(context);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Teacher updated successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteTeacherConfirmed(String tId, String email) async {
    try {
      await FirebaseService.instance.deleteTeacher(tId, email);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Teacher deleted successfully'),
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
      title: 'Teachers Management',
      floating: FloatingActionButton(
        onPressed: addTeacher,
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
                hintText: 'Search by name or subject...',
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
            child: FutureBuilder<List<Teacher>>(
              future: FirebaseService.instance.getAllTeachers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var teachers = snapshot.data ?? [];
                teachers = teachers
                    .where((t) =>
                        t.name.toLowerCase().contains(q.text.toLowerCase()) ||
                        t.subject.toLowerCase().contains(q.text.toLowerCase()))
                    .toList();

                if (teachers.isEmpty) {
                  return const Center(child: Text('No teachers found.'));
                }

                return ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (_, i) {
                    final teacher = teachers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD4D5D7),
                          child: Text(initials(teacher.name),
                              style: const TextStyle(
                                  color: Color(0xFFFF1800))),
                        ),
                        title: Text(teacher.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacher.subject),
                            const SizedBox(height: 4),
                            Text('Fee: ${teacher.monthlyFee}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () =>
                                  Future(() => editTeacher(teacher)),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () =>
                                  Future(() => deleteTeacher(teacher)),
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
