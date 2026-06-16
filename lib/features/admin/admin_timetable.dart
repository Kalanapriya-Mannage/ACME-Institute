import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../models/timetable_model.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../shared/widgets/app_shell.dart';

class AdminTimetable extends StatefulWidget {
  const AdminTimetable({super.key});
  @override
  State<AdminTimetable> createState() => _AdminTimetableState();
}

class _AdminTimetableState extends State<AdminTimetable> {
  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final List<String> timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'
  ];
  final List<String> grades = ['6', '7', '8', '9', '10', '11'];

  Future<List<Subject>> _loadSubjects(String? selectedGrade) async {
    if (selectedGrade == null || selectedGrade.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('subjects')
        .where('grades', arrayContains: selectedGrade)
        .get();
    return snapshot.docs.map((doc) => Subject.fromFirestore(doc.data())).toList();
  }

  Future<List<Teacher>> _loadTeachers(String? selectedSubName) async {
    if (selectedSubName == null || selectedSubName.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .where('subject', isEqualTo: selectedSubName)
        .get();
    return snapshot.docs.map((doc) => Teacher.fromFirestore(doc.data())).toList();
  }

  void _addEntry(String day, String time) {
    String selectedGrade = '';
    String selectedSubId = '';
    String selectedSubName = '';
    String selectedTId = '';
    List<Subject> filteredSubjects = [];
    List<Teacher> filteredTeachers = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Class to Timetable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$day at $time',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Grade dropdown
                DropdownButtonFormField<String>(
                  value: selectedGrade.isEmpty ? null : selectedGrade,
                  hint: const Text('Select Grade'),
                  items: grades
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) async {
                    setM(() {
                      selectedGrade = v ?? '';
                      selectedSubId = '';
                      selectedSubName = '';
                      selectedTId = '';
                      filteredTeachers = [];
                    });
                    if (v != null) {
                      final subjects = await _loadSubjects(v);
                      setM(() => filteredSubjects = subjects);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Grade'),
                ),
                const SizedBox(height: 12),
                // Subject dropdown
                DropdownButtonFormField<String>(
                  value: selectedSubId.isEmpty ? null : selectedSubId,
                  hint: const Text('Select Subject'),
                  items: filteredSubjects
                      .map((s) => DropdownMenuItem(
                            value: s.subId,
                            child: Text(s.subName),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    if (v != null) {
                      final subject = filteredSubjects.firstWhere(
                        (s) => s.subId == v,
                        orElse: () => Subject(
                          subId: '',
                          subName: '',
                          grades: [],
                          teacherIds: [],
                        ),
                      );
                      setM(() {
                        selectedSubId = v;
                        selectedSubName = subject.subName;
                        selectedTId = '';
                      });
                      final teachers = await _loadTeachers(subject.subName);
                      setM(() => filteredTeachers = teachers);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                // Teacher dropdown
                DropdownButtonFormField<String>(
                  value: selectedTId.isEmpty ? null : selectedTId,
                  hint: const Text('Select Teacher'),
                  items: filteredTeachers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setM(() => selectedTId = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Teacher'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedGrade.isEmpty ||
                        selectedSubId.isEmpty ||
                        selectedSubName.isEmpty ||
                        selectedTId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    try {
                      final entry = TimetableModel(
                        ttId: '',
                        subId: selectedSubId,
                        subName: selectedSubName,
                        tId: selectedTId,
                        grade: selectedGrade,
                        day: day,
                        time: time,
                      );
                      await FirebaseService.instance.addTimetableEntry(entry);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Class added successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Add Class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryOptions(TimetableModel entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.subName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Grade: ${entry.grade}'),
            Text('Teacher: ${entry.tId}'),
            Text('${entry.day} at ${entry.time}'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editEntry(entry);
                  },
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(entry);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editEntry(TimetableModel entry) {
    String selectedGrade = entry.grade;
    String selectedSubId = entry.subId;
    String selectedSubName = entry.subName;
    String selectedTId = entry.tId;
    List<Subject> filteredSubjects = [];
    List<Teacher> filteredTeachers = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Class',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGrade,
                  items: grades
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) async {
                    setM(() {
                      selectedGrade = v ?? '';
                      selectedSubId = '';
                      selectedSubName = '';
                      selectedTId = '';
                      filteredTeachers = [];
                    });
                    if (v != null) {
                      final subjects = await _loadSubjects(v);
                      setM(() => filteredSubjects = subjects);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Grade'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSubId.isEmpty ? null : selectedSubId,
                  hint: const Text('Select Subject'),
                  items: filteredSubjects
                      .map((s) => DropdownMenuItem(value: s.subId, child: Text(s.subName)))
                      .toList(),
                  onChanged: (v) async {
                    if (v != null) {
                      final subject = filteredSubjects.firstWhere(
                        (s) => s.subId == v,
                        orElse: () => Subject(
                          subId: '',
                          subName: '',
                          grades: [],
                          teacherIds: [],
                        ),
                      );
                      setM(() {
                        selectedSubId = v;
                        selectedSubName = subject.subName;
                        selectedTId = '';
                      });
                      final teachers = await _loadTeachers(subject.subName);
                      setM(() => filteredTeachers = teachers);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTId.isEmpty ? null : selectedTId,
                  hint: const Text('Select Teacher'),
                  items: filteredTeachers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setM(() => selectedTId = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Teacher'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedGrade.isEmpty ||
                        selectedSubId.isEmpty ||
                        selectedSubName.isEmpty ||
                        selectedTId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    try {
                      final updatedEntry = TimetableModel(
                        ttId: entry.ttId,
                        subId: selectedSubId,
                        subName: selectedSubName,
                        tId: selectedTId,
                        grade: selectedGrade,
                        day: entry.day,
                        time: entry.time,
                      );
                      await FirebaseService.instance.updateTimetableEntry(updatedEntry);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Class updated successfully')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Update Class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(TimetableModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete ${entry.subName} from ${entry.day} at ${entry.time}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseService.instance.deleteTimetableEntry(entry.ttId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class deleted successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Master Timetable',
      subtitle: 'Tap a cell to add or edit a class',
      body: StreamBuilder<List<TimetableModel>>(
        stream: FirebaseService.instance.getAllTimetableEntries(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];

          // Build grid
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Header row with days
                    Row(
                      children: [
                        const SizedBox(width: 60), // Time column
                        ...days.map((day) => SizedBox(
                              width: 80,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )),
                      ],
                    ),
                    // Grid rows
                    ...timeSlots.map((time) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              time,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          ...days.map((day) {
                            final dayEntries = entries
                                .where((e) => e.day == day && e.time == time)
                                .toList();
                            final hasEntry = dayEntries.isNotEmpty;

                            return GestureDetector(
                              onTap: () {
                                if (hasEntry) {
                                  _showEntryOptions(dayEntries.first);
                                } else {
                                  _addEntry(day, time);
                                }
                              },
                              child: Container(
                                width: 80,
                                height: 60,
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                  color: hasEntry ? Colors.blue.shade50 : Colors.white,
                                ),
                                child: hasEntry
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dayEntries.first.subName,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'G${dayEntries.first.grade}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      )
                                    : const Icon(Icons.add, size: 20, color: Colors.grey),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

