import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminEnrollments extends StatefulWidget {
  const AdminEnrollments({super.key});

  @override
  State<AdminEnrollments> createState() => _AdminEnrollmentsState();
}

class _AdminEnrollmentsState extends State<AdminEnrollments>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  // Manual enrollment form
  Student? _selectedStudent;
  Subject? _selectedSubject;
  Teacher? _selectedTeacher;
  List<Student> _allStudents = [];
  List<Subject> _allSubjects = [];
  List<Teacher> _allTeachers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFormData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    final students = await FirebaseService.instance.getAllStudents();
    final subjects = await FirebaseService.instance.getAllSubjects();
    final teachers = await FirebaseService.instance.getAllTeachers();

    if (mounted) {
      setState(() {
        _allStudents = students;
        _allSubjects = subjects;
        _allTeachers = teachers;
      });
    }
  }

  List<Teacher> _getTeachersForSubject(String subId) {
    final subject = _allSubjects.firstWhere(
      (s) => s.subId == subId,
      orElse: () => Subject(subId: '', subName: '', grades: [], teacherIds: []),
    );

    if (subject.teacherIds.isNotEmpty) {
      return _allTeachers.where((t) => subject.teacherIds.contains(t.tId)).toList();
    }

    // Fallback for older data shapes: match subject name to teacher.subject
    return _allTeachers.where((t) => t.subject == subject.subName).toList();
  }

  Future<void> _handleMarkAsPaid(
    String payId,
    String enrId,
    String sId,
    String subId,
    String subName,
  ) async {
    final admin = context.read<AuthProvider>().currentUser;
    if (admin?.profileId == null) return;

    setState(() => _isProcessing = true);

    try {
      await FirebaseService.instance.markPaymentAsPaid(
        payId: payId,
        enrId: enrId,
        sId: sId,
        subId: subId,
        subName: subName,
        adminAId: admin!.profileId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed. Student enrolled!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleManualEnrollment() async {
    if (_selectedStudent == null ||
        _selectedSubject == null ||
        _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final admin = context.read<AuthProvider>().currentUser;
    if (admin?.profileId == null) return;

    setState(() => _isProcessing = true);

    try {
      await FirebaseService.instance.manuallyEnrollStudent(
        sId: _selectedStudent!.sId,
        sName: _selectedStudent!.sName,
        subId: _selectedSubject!.subId,
        subName: _selectedSubject!.subName,
        tId: _selectedTeacher!.tId,
        amount: _selectedTeacher!.monthlyFee,
        adminAId: admin!.profileId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student enrolled successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedStudent = null;
        _selectedSubject = null;
        _selectedTeacher = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Enrollment Management',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFF1800),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFF1800),
            tabs: const [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Approved'),
              Tab(text: 'Manual Enroll'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildApprovedTab(),
                _buildManualEnrollTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return StreamBuilder<List<dynamic>>(
      stream: FirebaseService.instance.getPendingEnrollments(),
      builder: (context, enrollmentSnapshot) {
        if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (enrollmentSnapshot.hasError) {
          return Center(
            child: Text('Error: ${enrollmentSnapshot.error}'),
          );
        }

        final enrollments = enrollmentSnapshot.data ?? [];

        if (enrollments.isEmpty) {
          return const Center(
            child: Text('No pending enrollment requests'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            return FutureBuilder<dynamic>(
              future:
                  FirebaseService.instance.getPaymentByEnrId(enrollment['enrId']),
              builder: (context, paymentSnapshot) {
                final payment = paymentSnapshot.data;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                enrollment['sName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFF1800),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${enrollment['subName']} • ${enrollment['tId']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Requested',
                          enrollment['requestedAt'] != null
                              ? _formatDate(enrollment['requestedAt'])
                              : 'N/A',
                        ),
                        _buildDetailRow(
                          'Amount',
                          payment?.amount ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Payment',
                          payment == null ? 'Missing payment' : 'Pending',
                          color: payment == null ? Colors.red : Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1800),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isProcessing || payment?.payId?.trim().isEmpty == true
                                ? null
                                : () => _handleMarkAsPaid(
                                      payment?.payId ?? '',
                                      enrollment['enrId'] ?? '',
                                      enrollment['sId'] ?? '',
                                      enrollment['subId'] ?? '',
                                      enrollment['subName'] ?? '',
                                    ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Mark as Paid',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildApprovedTab() {
    return StreamBuilder<List<dynamic>>(
      stream: FirebaseService.instance.getAllEnrollments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final enrollments = (snapshot.data ?? [])
            .where((e) => e['status'] == 'approved')
            .toList();

        if (enrollments.isEmpty) {
          return const Center(
            child: Text('No approved enrollments'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            return FutureBuilder<dynamic>(
              future:
                  FirebaseService.instance.getPaymentByEnrId(enrollment['enrId']),
              builder: (context, paymentSnapshot) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                enrollment['sName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1A00FF00),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Approved',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${enrollment['subName']} • ${enrollment['tId']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Approved',
                          enrollment['approvedAt'] != null
                              ? _formatDate(enrollment['approvedAt'])
                              : 'N/A',
                        ),
                        _buildDetailRow(
                          'Payment',
                          'Paid',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildManualEnrollTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Student',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Student>(
            initialValue: _selectedStudent,
            hint: const Text('Select a student'),
            items: _allStudents.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s.sName),
              );
            }).toList(),
            onChanged: (student) {
              setState(() {
                _selectedStudent = student;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Subject',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Subject>(
            initialValue: _selectedSubject,
            hint: const Text('Select a subject'),
            items: _allSubjects.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s.subName),
              );
            }).toList(),
            onChanged: (subject) {
              setState(() {
                _selectedSubject = subject;
                _selectedTeacher = null;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Teacher',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Teacher>(
            initialValue: _selectedTeacher,
            hint: const Text('Select a teacher'),
            items: _selectedSubject != null
                ? _getTeachersForSubject(_selectedSubject!.subId).map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList()
                : [],
            onChanged: (teacher) {
              setState(() {
                _selectedTeacher = teacher;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enrollment Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Student',
                    _selectedStudent?.sName ?? '-',
                  ),
                  _buildDetailRow(
                    'Subject',
                    _selectedSubject?.subName ?? '-',
                  ),
                  _buildDetailRow(
                    'Teacher',
                    _selectedTeacher?.name ?? '-',
                  ),
                  _buildDetailRow(
                    'Monthly Fee',
                    _selectedTeacher?.monthlyFee ?? '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1800),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isProcessing ? null : _handleManualEnrollment,
              child: _isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Enroll Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day} ${_monthName(date.month)}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
