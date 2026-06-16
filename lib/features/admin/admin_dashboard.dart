import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/module_icon_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final q = TextEditingController();
  late final Future<_AdminDashboardCounts> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
  }

  Future<_AdminDashboardCounts> _loadCounts() async {
    final students = await FirebaseService.instance.getAllStudents();
    final teachers = await FirebaseService.instance.getAllTeachers();
    final subjects = await FirebaseService.instance.getAllSubjects();
    final pending = await FirebaseService.instance.getPendingEnrollmentsCount();
    return _AdminDashboardCounts(
      students: students.length,
      teachers: teachers.length,
      subjects: subjects.length,
      pendingEnrollments: pending,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      ('Profile', Icons.person, '/admin/profile'),
      ('Enrollments', Icons.assignment, '/admin/enrollments'),
      ('Notifications', Icons.notifications, '/admin/notifications'),
      ('Payment', Icons.payments, '/admin/payments'),
      ('Teachers', Icons.people, '/admin/teachers'),
      ('Students', Icons.school, '/admin/students'),
      ('Subjects', Icons.menu_book, '/admin/subjects'),
      ('Timetable', Icons.calendar_month, '/admin/timetable'),
    ];
    final filtered = modules
        .where((m) => m.$1.toLowerCase().contains(q.text.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE5E4E9),
      body: SafeArea(
        child: Column(children: [
          Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFFF1800), Color.fromARGB(255, 184, 66, 66)]),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(36))),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ACME Institute',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const Text('Welcome, Admin',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 14),
              TextField(
                  controller: q,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search modules...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none))),
            ]),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 18)
                  ]),
              child: ListView(children: [
                const Text('Welcome, Admin!',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                FutureBuilder<_AdminDashboardCounts>(
                  future: _countsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final counts = snapshot.data ??
                        _AdminDashboardCounts(
                          students: 0,
                          teachers: 0,
                          subjects: 0,
                          pendingEnrollments: 0,
                        );

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _stat(Icons.school, '${counts.students}', 'Total Students'),
                        _stat(Icons.people, '${counts.teachers}', 'Total Teachers'),
                        _stat(Icons.menu_book, '${counts.subjects}', 'Total Subjects'),
                        _stat(Icons.notifications, '${counts.pendingEnrollments}',
                            'Pending Enrollments'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ...filtered.map((m) => ModuleIconCard(
                        icon: m.$2,
                        label: m.$1,
                        onTap: () => Navigator.pushNamed(context, m.$3))),
                  ],
                )
              ]),
            ),
          )
        ]),
      ),
    );
  }

  Widget _stat(IconData i, String n, String l) => Card(
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, color: const Color(0xFFFF1800)),
        Text(n,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey))
      ])));
}

class _AdminDashboardCounts {
  final int students;
  final int teachers;
  final int subjects;
  final int pendingEnrollments;

  _AdminDashboardCounts({
    required this.students,
    required this.teachers,
    required this.subjects,
    required this.pendingEnrollments,
  });
}
