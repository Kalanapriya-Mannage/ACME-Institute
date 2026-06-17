import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/teacher.dart';
import '../models/student.dart';
import '../models/admin.dart';
import '../models/subject.dart';
import '../models/result_model.dart';
import '../models/attendance_model.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/timetable_model.dart';

class FirebaseService {
  FirebaseService._() {
    try {
      firestore.settings = const Settings(persistenceEnabled: true);
    } catch (_) {
      debugPrint('[FirebaseService] Firestore settings were already configured');
    }
  }
  static final instance = FirebaseService._();

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  /// Read user metadata from users/{uid} collection
  Future<Map<String, dynamic>?> getUserDataByUid(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        debugPrint('No users document found for uid: $uid');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('users document exists but has no data for uid: $uid');
        return null;
      }

      debugPrint('User data keys: ${data.keys.toList()}');
      return data;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Get teacher profile by ID
  Future<Teacher?> getTeacherById(String id) async {
    try {
      final doc = await firestore.collection('teachers').doc(id).get();
      if (!doc.exists) {
        debugPrint('Teacher document not found for id: $id');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('Teacher document exists but has no data for id: $id');
        return null;
      }

      debugPrint('Teacher data: $data');
      return Teacher.fromFirestore(data);
    } catch (e) {
      debugPrint('Error fetching teacher: $e');
      return null;
    }
  }

  /// Get student profile by ID
  Future<Student?> getStudentById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('Student document not found for id: $id');
        return null;
      }

      return Student.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching student: $e');
      return null;
    }
  }

  /// Get admin profile by ID
  Future<Admin?> getAdminById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('Admin document not found for id: $id');
        return null;
      }

      return Admin.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching admin: $e');
      return null;
    }
  }

  /// Get all subjects
  Future<List<Subject>> getAllSubjects() async {
    try {
      final docs = await firestore.collection('subjects').get();
      return docs.docs
          .map((doc) => Subject.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      return [];
    }
  }

  /// Get subject by ID
  Future<Subject?> getSubjectById(String id) async {
    try {
      final doc = await firestore.collection('subjects').doc(id).get();
      if (!doc.exists) {
        debugPrint('Subject document not found for id: $id');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('Subject document exists but has no data for id: $id');
        return null;
      }

      return Subject.fromFirestore(data);
    } catch (e) {
      debugPrint('Error fetching subject: $e');
      return null;
    }
  }

  /// Get subjects by list of subIds
  Future<List<Subject>> getSubjectsByIds(List<String> subIds) async {
    if (subIds.isEmpty) return [];
    try {
      final docs = await firestore
          .collection('subjects')
          .where(FieldPath.documentId, whereIn: subIds)
          .get();
      return docs.docs
          .map((doc) => Subject.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching subjects by ids: $e');
      return [];
    }
  }

  /// Get teachers by list of tIds
  Future<List<Teacher>> getTeachersByIds(List<String> tIds) async {
    if (tIds.isEmpty) return [];
    try {
      final docs = await firestore
          .collection('teachers')
          .where(FieldPath.documentId, whereIn: tIds)
          .get();
      return docs.docs
          .map((doc) => Teacher.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching teachers by ids: $e');
      return [];
    }
  }

  /// Get all teachers (for admin)
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final docs = await firestore.collection('teachers').get();
      return docs.docs
          .map((doc) => Teacher.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all teachers: $e');
      return [];
    }
  }

  /// Get all students (for admin)
  Future<List<Student>> getAllStudents() async {
    try {
      final docs = await firestore.collection('students').get();
      return docs.docs
          .map((doc) => Student.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all students: $e');
      return [];
    }
  }

  /// Count pending enrollment requests stored in enrollments collection
  Future<int> getPendingEnrollmentsCount() async {
    try {
      final snapshot = await firestore
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching pending enrollments count: $e');
      return 0;
    }
  }

  /// Enroll student in subject and associate with the teacher
  Future<void> enrollStudentInSubject(
      String sId, String subId, String teacherId) async {
    try {
      await firestore.collection('students').doc(sId).update({
        'enrolledSubject': FieldValue.arrayUnion([subId]),
        'enrolledTeacher': FieldValue.arrayUnion([teacherId]),
      });
      debugPrint(
          'Student $sId enrolled in subject $subId with teacher $teacherId');
    } catch (e) {
      debugPrint('Error enrolling student: $e');
      rethrow;
    }
  }

  /// Get subjects taught by a teacher
  Future<List<Subject>> getSubjectsByTeacherId(String teacherId) async {
    try {
      final docs = await firestore
          .collection('subjects')
          .where('teacherIds', arrayContains: teacherId)
          .get();
      return docs.docs
          .map((doc) => Subject.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching subjects for teacher: $e');
      return [];
    }
  }

  /// CRUD for Teachers

  Future<void> addTeacher(Map<String, dynamic> data, String email, String password) async {
    try {
      // Step 1: Create Firebase Auth account
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Step 2: Save to teachers collection
      final tId = data['tId'] as String;
      await firestore
          .collection('teachers')
          .doc(tId)
          .set(data);

      // Step 3: Save to users collection
      await firestore
          .collection('users')
          .doc(uid)
          .set({
            'tId': tId,
            'role': 'teacher',
            'username': email,
          });

      debugPrint('Teacher $tId added successfully');
    } catch (e) {
      debugPrint('Error adding teacher: $e');
      rethrow;
    }
  }

  Future<void> updateTeacher(String tId, Map<String, dynamic> data) async {
    try {
      await firestore
          .collection('teachers')
          .doc(tId)
          .update(data);
      debugPrint('Teacher $tId updated successfully');
    } catch (e) {
      debugPrint('Error updating teacher: $e');
      rethrow;
    }
  }

  Future<void> deleteTeacher(String tId, String email) async {
    try {
      // Delete from teachers collection
      await firestore
          .collection('teachers')
          .doc(tId)
          .delete();

      // Find and delete from users collection
      final userDocs = await firestore
          .collection('users')
          .where('username', isEqualTo: email)
          .get();

      for (final doc in userDocs.docs) {
        await doc.reference.delete();
      }

      debugPrint('Teacher $tId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting teacher: $e');
      rethrow;
    }
  }

  /// CRUD for Students

  Future<void> addStudent(
      Map<String, dynamic> data, String email, String password) async {
    try {
      // Step 1: Create Firebase Auth account
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Step 2: Save to students collection
      final sId = data['sId'] as String;
      await firestore.collection('students').doc(sId).set(data);

      // Step 3: Save to users collection
      await firestore.collection('users').doc(uid).set({
            'sId': sId,
            'role': 'student',
            'username': email,
          });

      debugPrint('Student $sId added successfully');
    } catch (e) {
      debugPrint('Error adding student: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(String sId, Map<String, dynamic> data) async {
    try {
      await firestore
          .collection('students')
          .doc(sId)
          .update(data);
      debugPrint('Student $sId updated successfully');
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String sId, String email) async {
    try {
      // Delete from students collection
      await firestore
          .collection('students')
          .doc(sId)
          .delete();

      // Find and delete from users collection
      final userDocs = await firestore
          .collection('users')
          .where('username', isEqualTo: email)
          .get();

      for (final doc in userDocs.docs) {
        await doc.reference.delete();
      }

      debugPrint('Student $sId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  /// CRUD for Subjects

  Future<void> addSubject(Map<String, dynamic> data) async {
    try {
      final subId = data['subId'] as String;
      await firestore
          .collection('subjects')
          .doc(subId)
          .set(data);
      debugPrint('Subject $subId added successfully');
    } catch (e) {
      debugPrint('Error adding subject: $e');
      rethrow;
    }
  }

  Future<void> updateSubject(String subId, Map<String, dynamic> data) async {
    try {
      await firestore
          .collection('subjects')
          .doc(subId)
          .update(data);
      debugPrint('Subject $subId updated successfully');
    } catch (e) {
      debugPrint('Error updating subject: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(String subId) async {
    try {
      // Remove subject from all enrolled students
      final students = await firestore
          .collection('students')
          .where('enrolledSubject', arrayContains: subId)
          .get();

      for (final doc in students.docs) {
        await doc.reference.update({
          'enrolledSubject': FieldValue.arrayRemove([subId])
        });
      }

      // Delete the subject
      await firestore
          .collection('subjects')
          .doc(subId)
          .delete();

      debugPrint('Subject $subId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      rethrow;
    }
  }

  /// Results CRUD operations

  /// Get single result for a student and subject
  Future<ResultModel?> getStudentResult(String sId, String subId) async {
    try {
      final doc = await firestore
          .collection('results')
          .doc('${sId}_$subId')
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return ResultModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error getting result: $e');
      return null;
    }
  }

  /// Get ALL results for a student (all subjects)
  Future<List<ResultModel>> getAllResultsForStudent(String sId) async {
    try {
      final query = await firestore
          .collection('results')
          .where('sId', isEqualTo: sId)
          .get();

      return query.docs
          .map((doc) => ResultModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting student results: $e');
      return [];
    }
  }

  /// Get ALL results for a subject (used by teacher)
  Future<List<ResultModel>> getAllResultsForSubject(String subId) async {
    try {
      final query = await firestore
          .collection('results')
          .where('subId', isEqualTo: subId)
          .get();

      return query.docs
          .map((doc) => ResultModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting subject results: $e');
      return [];
    }
  }

  /// Save or update result (admin only)
  Future<void> saveResult(ResultModel result) async {
    try {
      final docId = '${result.sId}_${result.subId}';
      final data = result.toMap();
      debugPrint('GRADE_LOG: Writing to Firestore - docId=$docId, data=$data');
      await firestore
          .collection('results')
          .doc(docId)
          .set(data);
      debugPrint('GRADE_LOG: Firestore write complete for $docId');
    } catch (e) {
      debugPrint('Error saving result: $e');
      rethrow;
    }
  }

  /// Get students enrolled in a specific subject
  /// (used by teacher to see their students)
  Future<List<Student>> getStudentsEnrolledInSubject(String subId) async {
    try {
      final query = await firestore
          .collection('students')
          .where('enrolledSubject', arrayContains: subId)
          .get();

      return query.docs
          .map((doc) => Student.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting enrolled students: $e');
      return [];
    }
  }

  /// Get students enrolled in the given subject specifically under this teacher
  Future<List<Student>> getStudentsForTeacherSubject(
      String teacherId, String subjectId) async {
    try {
      final query = await firestore
          .collection('students')
          .where('enrolledSubject', arrayContains: subjectId)
          .get();

      return query.docs
          .map((doc) => Student.fromFirestore(doc.data()))
          .where((student) {
            for (var idx = 0;
                idx < student.enrolledSubject.length &&
                    idx < student.enrolledTeacher.length;
                idx++) {
              if (student.enrolledSubject[idx] == subjectId &&
                  student.enrolledTeacher[idx] == teacherId) {
                return true;
              }
            }
            return false;
          })
          .toList();
    } catch (e) {
      debugPrint('Error getting students for teacher subject: $e');
      return [];
    }
  }

  /// Get students taught by a specific teacher
  Future<List<Student>> getStudentsByTeacherId(String teacherId) async {
    try {
      final query = await firestore
          .collection('students')
          .where('enrolledTeacher', arrayContains: teacherId)
          .get();

      return query.docs
          .map((doc) => Student.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting students for teacher: $e');
      return [];
    }
  }

  /// Get students taught by a specific teacher across all assigned subjects
  Future<List<Student>> getStudentsForTeacher(String teacherId) async {
    try {
      final subjects = await getAllSubjects();
      final teacherSubjects = subjects
          .where((s) => s.teacherIds.contains(teacherId))
          .toList();

      final results = await Future.wait(
        teacherSubjects.map((subject) => getStudentsForTeacherSubject(teacherId, subject.subId)),
      );

      final studentMap = <String, Student>{};
      for (final result in results) {
        for (final student in result) {
          studentMap[student.sId] = student;
        }
      }

      return studentMap.values.toList();
    } catch (e) {
      debugPrint('Error getting students for teacher: $e');
      return [];
    }
  }

  /// Generate next notification ID - using sequential format
  Future<String> _generateNextNId() async {
    try {
      // Get all notifications to find the highest number
      final query = await firestore
          .collection('notifications')
          .get();

      int maxNumber = 0;
      for (final doc in query.docs) {
        try {
          final nId = doc.data()['nId'] as String?;
          if (nId != null && nId.startsWith('N')) {
            // Extract number from format N001, N002, etc
            final numStr = nId.substring(1);
            if (numStr.isNotEmpty) {
              final num = int.tryParse(numStr);
              if (num != null && num > maxNumber) {
                maxNumber = num;
              }
            }
          }
        } catch (e) {
          debugPrint('[generateNextNId] Error parsing nId: $e');
        }
      }

      maxNumber++;
      final newNId = 'N${maxNumber.toString().padLeft(3, '0')}';
      debugPrint('[generateNextNId] Generated nId: $newNId');
      return newNId;
    } catch (e) {
      debugPrint('[generateNextNId] Error: $e, using timestamp fallback');
      return 'N${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Send notification (admin only)
  Future<void> sendNotification({
    required String title,
    required String message,
    required String category,
    required String targetAudience,
    required String sentBy,
  }) async {
    try {
      final nId = await _generateNextNId();
      debugPrint('[sendNotification] Generated nId: $nId');
      
      final notification = NotificationModel(
        nId: nId,
        category: category,
        message: message,
        sentAt: DateTime.now(),
        sentBy: sentBy,
        targetAudience: targetAudience,
        title: title,
      );

      final data = notification.toMap();
      debugPrint('[sendNotification] Storing notification: $notification with data: $data');

      await firestore
          .collection('notifications')
          .doc(nId)
          .set(data);

      debugPrint('[sendNotification] Notification $nId sent successfully to Firestore');
    } catch (e) {
      debugPrint('[sendNotification] ERROR: $e');
      rethrow;
    }
  }

  /// Get notifications for students (targetAudience: 'all' or 'students')
  Stream<List<NotificationModel>> getStudentNotifications() {
    debugPrint('[getStudentNotifications] Creating stream for student notifications');
    return firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          debugPrint('[getStudentNotifications] Received snapshot with ${snapshot.docs.length} documents');
          
          final allNotifications = <NotificationModel>[];
          final filteredNotifications = <NotificationModel>[];
          
          for (final doc in snapshot.docs) {
            try {
              final notification = NotificationModel.fromFirestore(
                doc.data(),
                documentId: doc.id,
              );
              allNotifications.add(notification);
              
              // Filter for students
              if (notification.targetAudience == 'all' || notification.targetAudience == 'students') {
                filteredNotifications.add(notification);
                debugPrint('[getStudentNotifications] ✓ Included: ${notification.nId} - ${notification.title}');
              } else {
                debugPrint('[getStudentNotifications] ✗ Filtered out: ${notification.nId} - audience: ${notification.targetAudience}');
              }
            } catch (e) {
              debugPrint('[getStudentNotifications] ERROR parsing doc ${doc.id}: $e');
            }
          }
          
          filteredNotifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          debugPrint('[getStudentNotifications] Returning ${filteredNotifications.length} notifications out of ${allNotifications.length} total');
          return filteredNotifications;
        })
        .handleError((error) {
          debugPrint('[getStudentNotifications] Stream error: $error');
          return <NotificationModel>[];
        });
  }

  /// Get notifications for teachers (targetAudience: 'all' or 'teachers')
  Stream<List<NotificationModel>> getTeacherNotifications() {
    debugPrint('[getTeacherNotifications] Creating stream for teacher notifications');
    return firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          debugPrint('[getTeacherNotifications] Received snapshot with ${snapshot.docs.length} documents');
          
          final allNotifications = <NotificationModel>[];
          final filteredNotifications = <NotificationModel>[];
          
          for (final doc in snapshot.docs) {
            try {
              final notification = NotificationModel.fromFirestore(
                doc.data(),
                documentId: doc.id,
              );
              allNotifications.add(notification);
              
              // Filter for teachers
              if (notification.targetAudience == 'all' || notification.targetAudience == 'teachers') {
                filteredNotifications.add(notification);
                debugPrint('[getTeacherNotifications] ✓ Included: ${notification.nId} - ${notification.title}');
              } else {
                debugPrint('[getTeacherNotifications] ✗ Filtered out: ${notification.nId} - audience: ${notification.targetAudience}');
              }
            } catch (e) {
              debugPrint('[getTeacherNotifications] ERROR parsing doc ${doc.id}: $e');
            }
          }
          
          filteredNotifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          debugPrint('[getTeacherNotifications] Returning ${filteredNotifications.length} notifications out of ${allNotifications.length} total');
          return filteredNotifications;
        })
        .handleError((error) {
          debugPrint('[getTeacherNotifications] Stream error: $error');
          return <NotificationModel>[];
        });
  }

  /// Get all notifications (admin only)
  Stream<List<NotificationModel>> getAllNotifications() {
    debugPrint('[getAllNotifications] Creating stream for all notifications');
    return firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          debugPrint('[getAllNotifications] Received snapshot with ${snapshot.docs.length} documents');
          
          final notifications = <NotificationModel>[];
          
          for (final doc in snapshot.docs) {
            try {
              final notification = NotificationModel.fromFirestore(
                doc.data(),
                documentId: doc.id,
              );
              notifications.add(notification);
              debugPrint('[getAllNotifications] ✓ Added: ${notification.nId} - ${notification.title}');
            } catch (e) {
              debugPrint('[getAllNotifications] ERROR parsing doc ${doc.id}: $e');
            }
          }
          
          notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          debugPrint('[getAllNotifications] Returning ${notifications.length} notifications');
          return notifications;
        })
        .handleError((error) {
          debugPrint('[getAllNotifications] Stream error: $error');
          return <NotificationModel>[];
        });
  }

  /// Delete notification by nId
  Future<void> deleteNotification(String nId) async {
    try {
      await firestore.collection('notifications').doc(nId).delete();
      debugPrint('Notification $nId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// ========== TIMETABLE CRUD OPERATIONS ==========

  /// Generate next timetable ID (TT001, TT002...)
  Future<String> _generateNextTTId() async {
    try {
      final query = await firestore
          .collection('timetable')
          .orderBy('ttId', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return 'TT001';
      final lastId = query.docs.first.data()['ttId'] as String? ?? 'TT000';
      final lastNumber = int.tryParse(lastId.substring(2)) ?? 0;
      final nextNumber = lastNumber + 1;
      return 'TT${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('[_generateNextTTId] Error: $e, using timestamp fallback');
      return 'TT${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Add timetable entry (admin only)
  Future<void> addTimetableEntry(TimetableModel entry) async {
    try {
      final ttId = await _generateNextTTId();
      final newEntry = TimetableModel(
        ttId: ttId,
        subId: entry.subId,
        subName: entry.subName,
        tId: entry.tId,
        grade: entry.grade,
        day: entry.day,
        time: entry.time,
      );
      await firestore.collection('timetable').doc(ttId).set(newEntry.toMap());
      debugPrint('[addTimetableEntry] Added $ttId successfully');
    } catch (e) {
      debugPrint('[addTimetableEntry] Error: $e');
      rethrow;
    }
  }

  /// Update timetable entry (admin only)
  Future<void> updateTimetableEntry(TimetableModel entry) async {
    try {
      await firestore
          .collection('timetable')
          .doc(entry.ttId)
          .update(entry.toMap());
      debugPrint('[updateTimetableEntry] Updated ${entry.ttId} successfully');
    } catch (e) {
      debugPrint('[updateTimetableEntry] Error: $e');
      rethrow;
    }
  }

  /// Delete timetable entry (admin only)
  Future<void> deleteTimetableEntry(String ttId) async {
    try {
      await firestore.collection('timetable').doc(ttId).delete();
      debugPrint('[deleteTimetableEntry] Deleted $ttId successfully');
    } catch (e) {
      debugPrint('[deleteTimetableEntry] Error: $e');
      rethrow;
    }
  }

  /// Get ALL timetable entries (admin)
  Stream<List<TimetableModel>> getAllTimetableEntries() {
    debugPrint('[getAllTimetableEntries] Creating stream for all timetable entries');
    return firestore
        .collection('timetable')
        .orderBy('ttId')
        .snapshots()
        .map((snapshot) {
          debugPrint('[getAllTimetableEntries] Received ${snapshot.docs.length} entries');
          return snapshot.docs
              .map((doc) => TimetableModel.fromFirestore(doc.data()))
              .toList();
        })
        .handleError((error) {
          debugPrint('[getAllTimetableEntries] Stream error: $error');
          return <TimetableModel>[];
        });
  }

  /// Get timetable for teacher (by tId)
  Stream<List<TimetableModel>> getTeacherTimetable(String tId) {
    debugPrint('[getTeacherTimetable] Creating stream for teacher: $tId');
    return firestore
        .collection('timetable')
        .where('tId', isEqualTo: tId)
        .snapshots()
        .map((snapshot) {
          debugPrint('[getTeacherTimetable] Received ${snapshot.docs.length} entries for teacher $tId');
          final entries = snapshot.docs
              .map((doc) => TimetableModel.fromFirestore(doc.data()))
              .toList();
          // Sort by day order and time
          entries.sort((a, b) {
            final dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            final dayCompare = dayOrder.indexOf(a.day).compareTo(dayOrder.indexOf(b.day));
            if (dayCompare != 0) return dayCompare;
            return a.time.compareTo(b.time);
          });
          return entries;
        })
        .handleError((error) {
          debugPrint('[getTeacherTimetable] Stream error: $error');
          return <TimetableModel>[];
        });
  }

  /// Get all timetable entries for a teacher (one-time fetch)
  Future<List<TimetableModel>> getTeacherTimetableEntries(String tId) async {
    try {
      final query = await firestore
          .collection('timetable')
          .where('tId', isEqualTo: tId)
          .get();

      final entries = query.docs
          .map((doc) => TimetableModel.fromFirestore(doc.data()))
          .toList();

      entries.sort((a, b) {
        final dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayCompare = dayOrder.indexOf(a.day).compareTo(dayOrder.indexOf(b.day));
        if (dayCompare != 0) return dayCompare;
        return a.time.compareTo(b.time);
      });
      return entries;
    } catch (e) {
      debugPrint('[getTeacherTimetableEntries] Error: $e');
      return [];
    }
  }

  /// Get attendance sessions for a teacher on a specific date
  Future<Map<String, AttendanceModel>> getTeacherAttendanceSessionsForDate(
      String tId, String date) async {
    try {
      final query = await firestore
          .collection('attendance')
          .where('tId', isEqualTo: tId)
          .where('date', isEqualTo: date)
          .get();

      return Map.fromEntries(query.docs.map((doc) {
        final attendance = AttendanceModel.fromFirestore(doc.data());
        return MapEntry(attendance.ttId, attendance);
      }));
    } catch (e) {
      debugPrint('[getTeacherAttendanceSessionsForDate] Error: $e');
      return {};
    }
  }

  /// Get students enrolled in a subject for a specific grade
  Future<List<Student>> getStudentsForClass(String grade, String subId) async {
    try {
      final query = await firestore
          .collection('students')
          .where('grade', isEqualTo: grade)
          .where('enrolledSubject', arrayContains: subId)
          .get();
      return query.docs
          .map((d) => Student.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      debugPrint('[getStudentsForClass] Error: $e');
      return [];
    }
  }

  /// Get existing attendance for a class session on a date
  Future<AttendanceModel?> getExistingAttendance(String ttId, String date) async {
    try {
      final query = await firestore
          .collection('attendance')
          .where('ttId', isEqualTo: ttId)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return AttendanceModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      debugPrint('[getExistingAttendance] Error: $e');
      return null;
    }
  }

  /// Generate next attendance ID
  Future<String> _generateNextAttId() async {
    try {
      final query = await firestore
          .collection('attendance')
          .orderBy('attId', descending: true)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return 'ATT001';
      final last = query.docs.first.data()['attId'] as String? ?? 'ATT000';
      final next = int.tryParse(last.substring(3)) ?? 0;
      return 'ATT${(next + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('[generateNextAttId] Error: $e');
      return 'ATT${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get today's date string in yyyy-MM-dd format
  String getTodayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Create a new attendance document for today's session
  Future<String> createAttendanceSession(TimetableModel timetable) async {
    final attId = await _generateNextAttId();
    final date = getTodayDateString();
    final day = _getDayName(DateTime.now());

    await firestore.collection('attendance').doc(attId).set({
      'attId': attId,
      'subId': timetable.subId,
      'subName': timetable.subName,
      'tId': timetable.tId,
      'grade': timetable.grade,
      'date': date,
      'day': day,
      'time': timetable.time,
      'ttId': timetable.ttId,
      'students': {},
    });

    return attId;
  }

  /// Mark a single student's attendance in an existing attendance document
  Future<void> markStudentAttendance({
    required String attId,
    required String sId,
    required String status,
  }) async {
    try {
      await firestore.collection('attendance').doc(attId).update({
        'students.$sId': status,
      });
    } catch (e) {
      debugPrint('[markStudentAttendance] Error: $e');
      rethrow;
    }
  }

  /// Get attendance percentage for a student per enrolled subject
  Future<Map<String, double>> getStudentAttendancePercentage(
      String sId, List<String> enrolledSubjects) async {
    final percentages = <String, double>{};

    for (final subId in enrolledSubjects) {
      final query = await firestore
          .collection('attendance')
          .where('subId', isEqualTo: subId)
          .get();

      final allDocs = query.docs
          .map((d) => AttendanceModel.fromFirestore(d.data()))
          .toList();

      final relevantDocs = allDocs
          .where((a) => a.students.containsKey(sId))
          .toList();

      if (relevantDocs.isEmpty) {
        percentages[subId] = -1;
        continue;
      }

      final totalClasses = relevantDocs.length;
      final presentCount = relevantDocs
          .where((a) => a.students[sId] == 'present')
          .length;

      percentages[subId] = (presentCount / totalClasses) * 100;
    }

    return percentages;
  }

  /// Get attendance summary for a student in a subject
  Future<AttendanceSummary> getStudentAttendanceSummary(
      String sId, String subId) async {
    final query = await firestore
        .collection('attendance')
        .where('subId', isEqualTo: subId)
        .get();

    final docs = query.docs
        .map((d) => AttendanceModel.fromFirestore(d.data()))
        .where((a) => a.students.containsKey(sId))
        .toList();

    final total = docs.length;
    final present = docs
        .where((a) => a.students[sId] == 'present')
        .length;
    final absent = total - present;
    final pct = total > 0 ? (present / total) * 100.0 : -1.0;

    return AttendanceSummary(
      subId: subId,
      totalClasses: total,
      presentCount: present,
      absentCount: absent,
      percentage: pct,
    );
  }

  /// Get attendance summaries for a student across all enrolled subjects
  Future<Map<String, AttendanceSummary>> getStudentAttendanceSummaries(
      String sId, List<String> enrolledSubjects) async {
    final summaries = <String, AttendanceSummary>{};
    for (final subId in enrolledSubjects) {
      summaries[subId] = await getStudentAttendanceSummary(sId, subId);
    }
    return summaries;
  }

  /// Get all attendance history for a teacher
  Future<List<AttendanceModel>> getTeacherAttendanceHistory(String tId) async {
    try {
      final query = await firestore
          .collection('attendance')
          .where('tId', isEqualTo: tId)
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => AttendanceModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[getTeacherAttendanceHistory] Error: $e');
      return [];
    }
  }

  /// Get timetable for student
  /// Shows entries where grade matches AND subId is in student's enrolledSubjects
  Future<List<TimetableModel>> getStudentTimetable(
      String grade, List<String> enrolledSubjects) async {
    try {
      debugPrint('[getStudentTimetable] Getting timetable for grade: $grade, subjects: $enrolledSubjects');
      final query = await firestore
          .collection('timetable')
          .where('grade', isEqualTo: grade)
          .get();

      final entries = query.docs
          .map((doc) => TimetableModel.fromFirestore(doc.data()))
          .where((entry) => enrolledSubjects.contains(entry.subId))
          .toList();

      // Sort by day order and time
      entries.sort((a, b) {
        final dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayCompare = dayOrder.indexOf(a.day).compareTo(dayOrder.indexOf(b.day));
        if (dayCompare != 0) return dayCompare;
        return a.time.compareTo(b.time);
      });

      debugPrint('[getStudentTimetable] Returning ${entries.length} entries');
      return entries;
    } catch (e) {
      debugPrint('[getStudentTimetable] Error: $e');
      return [];
    }
  }

  /// Get today's timetable for teacher
  /// Returns entries for current day only
  Stream<List<TimetableModel>> getTeacherTodayTimetable(String tId) {
    return getTeacherTimetable(tId).map((entries) {
      final today = _getDayName(DateTime.now());
      return entries.where((e) => e.day == today).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
    });
  }

  /// Get today's timetable for student
  /// Returns entries for current day only, filtered by grade and subjects
  Future<List<TimetableModel>> getStudentTodayTimetable(
      String grade, List<String> enrolledSubjects) async {
    final entries = await getStudentTimetable(grade, enrolledSubjects);
    final today = _getDayName(DateTime.now());
    return entries.where((e) => e.day == today).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// Helper: Get day name from DateTime
  static String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  // ─── ENROLLMENT & PAYMENT SYSTEM ─────────────────────────────────

  /// Generate next enrollment ID
  Future<String> _generateNextEnrId() async {
    try {
      final query = await firestore
          .collection('enrollments')
          .orderBy('enrId', descending: true)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return 'ENR001';
      final last = query.docs.first.data()['enrId'] as String? ?? 'ENR000';
      final next = int.tryParse(last.substring(3)) ?? 0;
      return 'ENR${(next + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('[_generateNextEnrId] Error: $e');
      return 'ENR${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Generate next payment ID
  Future<String> _generateNextPayId() async {
    try {
      final query = await firestore
          .collection('payments')
          .orderBy('payId', descending: true)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return 'PAY001';
      final last = query.docs.first.data()['payId'] as String? ?? 'PAY000';
      final next = int.tryParse(last.substring(3)) ?? 0;
      return 'PAY${(next + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('[_generateNextPayId] Error: $e');
      return 'PAY${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Student requests enrollment
  Future<String> requestEnrollment({
    required String sId,
    required String sName,
    required String subId,
    required String subName,
    required String tId,
    required String amount,
    String paymentType = 'pending',
  }) async {
    try {
      // Check duplicate
      final existing = await firestore
          .collection('enrollments')
          .where('sId', isEqualTo: sId)
          .where('subId', isEqualTo: subId)
          .where('tId', isEqualTo: tId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already requested enrollment for this subject.');
      }

      final enrId = await _generateNextEnrId();
      final payId = await _generateNextPayId();
      final batch = firestore.batch();

      // Enrollment document
      batch.set(
        firestore.collection('enrollments').doc(enrId),
        {
          'enrId': enrId,
          'sId': sId,
          'sName': sName,
          'subId': subId,
          'subName': subName,
          'tId': tId,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        },
      );

      // Payment document
      batch.set(
        firestore.collection('payments').doc(payId),
        {
          'payId': payId,
          'sId': sId,
          'sName': sName,
          'subId': subId,
          'subName': subName,
          'tId': tId,
          'amount': amount,
          'paymentFor': 'enrollment',
          'month': 'enrollment',
          'paymentType': paymentType,
          'status': 'pending',
          'enrId': enrId,
          'requestedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      debugPrint('[requestEnrollment] Enrollment $enrId and Payment $payId created');
      return payId;
    } catch (e) {
      debugPrint('[requestEnrollment] Error: $e');
      rethrow;
    }
  }

  /// Admin marks payment as paid - auto-approves enrollment
  Future<void> markPaymentAsPaid({
    required String payId,
    required String enrId,
    required String sId,
    required String subId,
    required String subName,
    required String adminAId,
  }) async {
    if (payId.trim().isEmpty) {
      throw Exception('Mark payment failed because payId is empty');
    }
    try {
      final batch = firestore.batch();

      batch.update(
        firestore.collection('payments').doc(payId),
        {'status': 'paid', 'paidAt': FieldValue.serverTimestamp()},
      );

      batch.update(
        firestore.collection('enrollments').doc(enrId),
        {'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()},
      );

      batch.update(
        firestore.collection('students').doc(sId),
        {'enrolledSubject': FieldValue.arrayUnion([subId])},
      );

      await batch.commit();
      debugPrint('[markPaymentAsPaid] Payment $payId marked as paid, enrollment approved');

      // Auto notification
      await _sendEnrollmentApprovedNotification(
        sId: sId,
        subName: subName,
        adminAId: adminAId,
      );
    } catch (e) {
      debugPrint('[markPaymentAsPaid] Error: $e');
      rethrow;
    }
  }

  /// Send auto-notification when enrollment is approved
  Future<void> _sendEnrollmentApprovedNotification({
    required String sId,
    required String subName,
    required String adminAId,
  }) async {
    try {
      final nId = await _generateNextNId();
      await firestore.collection('notifications').doc(nId).set({
        'nId': nId,
        'title': 'Enrollment Approved',
        'message': 'Your enrollment for $subName has been approved. Welcome to the class!',
        'category': 'general',
        'targetAudience': 'student',
        'sentBy': adminAId,
        'sentAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[_sendEnrollmentApprovedNotification] Notification sent for student $sId');
    } catch (e) {
      debugPrint('[_sendEnrollmentApprovedNotification] Error: $e');
    }
  }

  /// Admin manually enrolls student - creates all records as approved/paid
  Future<void> manuallyEnrollStudent({
    required String sId,
    required String sName,
    required String subId,
    required String subName,
    required String tId,
    required String amount,
    required String adminAId,
  }) async {
    try {
      final enrId = await _generateNextEnrId();
      final payId = await _generateNextPayId();
      final batch = firestore.batch();

      batch.set(
        firestore.collection('enrollments').doc(enrId),
        {
          'enrId': enrId,
          'sId': sId,
          'sName': sName,
          'subId': subId,
          'subName': subName,
          'tId': tId,
          'status': 'approved',
          'requestedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        firestore.collection('payments').doc(payId),
        {
          'payId': payId,
          'sId': sId,
          'sName': sName,
          'subId': subId,
          'subName': subName,
          'tId': tId,
          'amount': amount,
          'paymentFor': 'enrollment',
          'month': 'enrollment',
          'paymentType': 'physical',
          'status': 'paid',
          'enrId': enrId,
          'requestedAt': FieldValue.serverTimestamp(),
          'paidAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        firestore.collection('students').doc(sId),
        {'enrolledSubject': FieldValue.arrayUnion([subId])},
      );

      await batch.commit();
      debugPrint('[manuallyEnrollStudent] Enrollment $enrId created manually');

      await _sendEnrollmentApprovedNotification(
        sId: sId,
        subName: subName,
        adminAId: adminAId,
      );
    } catch (e) {
      debugPrint('[manuallyEnrollStudent] Error: $e');
      rethrow;
    }
  }

  /// Get all enrollments (admin view)
  Stream<List<dynamic>> getAllEnrollments() {
    return firestore
        .collection('enrollments')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'enrId': data['enrId'] ?? '',
              'sId': data['sId'] ?? '',
              'sName': data['sName'] ?? '',
              'subId': data['subId'] ?? '',
              'subName': data['subName'] ?? '',
              'tId': data['tId'] ?? '',
              'status': data['status'] ?? 'pending',
              'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate(),
              'approvedAt': (data['approvedAt'] as Timestamp?)?.toDate(),
            };
          }).toList();
        });
  }

  /// Get pending enrollments only
  Stream<List<dynamic>> getPendingEnrollments() {
    return firestore
        .collection('enrollments')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'enrId': data['enrId'] ?? '',
              'sId': data['sId'] ?? '',
              'sName': data['sName'] ?? '',
              'subId': data['subId'] ?? '',
              'subName': data['subName'] ?? '',
              'tId': data['tId'] ?? '',
              'status': data['status'] ?? 'pending',
              'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate(),
              'approvedAt': (data['approvedAt'] as Timestamp?)?.toDate(),
            };
          }).toList();
        });
  }

  /// Get student's enrollments
  Stream<List<dynamic>> getStudentEnrollments(String sId) {
    return firestore
        .collection('enrollments')
        .where('sId', isEqualTo: sId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'enrId': data['enrId'] ?? '',
              'sId': data['sId'] ?? '',
              'sName': data['sName'] ?? '',
              'subId': data['subId'] ?? '',
              'subName': data['subName'] ?? '',
              'tId': data['tId'] ?? '',
              'status': data['status'] ?? 'pending',
              'requestedAt': (data['requestedAt'] as Timestamp?)?.toDate(),
              'approvedAt': (data['approvedAt'] as Timestamp?)?.toDate(),
            };
          }).toList();
        });
  }

  /// Get payment by enrollment ID
  Future<PaymentModel?> getPaymentByEnrId(String enrId) async {
    try {
      final query = await firestore
          .collection('payments')
          .where('enrId', isEqualTo: enrId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return PaymentModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      debugPrint('[getPaymentByEnrId] Error: $e');
      return null;
    }
  }

  Future<PaymentModel?> getPaymentByPayId(String payId) async {
    try {
      final doc = await firestore.collection('payments').doc(payId).get();
      if (!doc.exists || doc.data() == null) return null;
      return PaymentModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('[getPaymentByPayId] Error: $e');
      return null;
    }
  }

  /// Auto-generate monthly payments for current month if missing
  Future<void> autoGenerateMonthlyPayments(Student student) async {
    try {
      final now = DateTime.now();
      final currentMonth = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

      for (final subId in student.enrolledSubject) {
        final existing = await firestore
            .collection('payments')
            .where('sId', isEqualTo: student.sId)
            .where('subId', isEqualTo: subId)
            .where('month', isEqualTo: currentMonth)
            .where('paymentFor', isEqualTo: 'monthly')
            .get();

        if (existing.docs.isNotEmpty) continue;

        final subDoc = await firestore.collection('subjects').doc(subId).get();
        if (!subDoc.exists || subDoc.data() == null) continue;
        final subName = subDoc.data()?['subName'] ?? '';

        final enrQuery = await firestore
            .collection('enrollments')
            .where('sId', isEqualTo: student.sId)
            .where('subId', isEqualTo: subId)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();

        if (enrQuery.docs.isEmpty) continue;
        final tId = enrQuery.docs.first.data()['tId'] ?? '';
        if (tId.isEmpty) continue;

        final teacherDoc = await firestore.collection('teachers').doc(tId).get();
        if (!teacherDoc.exists || teacherDoc.data() == null) continue;
        final amount = teacherDoc.data()?['monthlyFee'] ?? 'Rs. 0';

        final payId = await _generateNextPayId();
        await firestore.collection('payments').doc(payId).set({
          'payId': payId,
          'sId': student.sId,
          'sName': student.sName,
          'subId': subId,
          'subName': subName,
          'tId': tId,
          'amount': amount,
          'paymentFor': 'monthly',
          'month': currentMonth,
          'paymentType': 'pending',
          'status': 'pending',
          'enrId': '-',
          'requestedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[autoGenerateMonthlyPayments] Error: $e');
    }
  }

  /// Get student's payment history stream
  Stream<List<PaymentModel>> getStudentPayments(String sId) {
    final trimmedId = sId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('payments')
        .where('sId', isEqualTo: trimmedId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) => PaymentModel.fromFirestore(doc.data()))
              .toList();
          payments.sort((a, b) {
            if (a.requestedAt == null && b.requestedAt == null) return 0;
            if (a.requestedAt == null) return 1;
            if (b.requestedAt == null) return -1;
            return b.requestedAt!.compareTo(a.requestedAt!);
          });
          return payments;
        });
  }

  /// Process online payment and optionally approve enrollment
  Future<void> processOnlinePayment({
    required String payId,
    required String cardLast4,
    required String cardType,
    String? enrId,
    String? sId,
    String? subId,
  }) async {
    if (payId.trim().isEmpty) {
      throw Exception('Invalid payId provided to processOnlinePayment');
    }
    try {
      // Read the payment document to determine context (monthly vs enrollment)
      final paymentDoc = await firestore.collection('payments').doc(payId).get();
      final paymentData = paymentDoc.data() ?? {};
      final paymentFor = (paymentData['paymentFor'] as String?) ?? 'monthly';
      final existingEnrId = (paymentData['enrId'] as String?) ?? (enrId ?? '-');
      final sIdEffective = (paymentData['sId'] as String?) ?? (sId ?? '');
      final subIdEffective = (paymentData['subId'] as String?) ?? (subId ?? '');
      final subName = (paymentData['subName'] as String?) ?? '';
      final tId = (paymentData['tId'] as String?) ?? '';

      final batch = firestore.batch();
      batch.update(
        firestore.collection('payments').doc(payId),
        {
          'status': 'paid',
          'paymentType': 'online',
          'cardLast4': cardLast4,
          'cardType': cardType,
          'paidAt': FieldValue.serverTimestamp(),
        },
      );

      // If this payment is linked to an enrollment request, approve it as before
      if (existingEnrId.isNotEmpty && existingEnrId != '-' ) {
        batch.update(
          firestore.collection('enrollments').doc(existingEnrId),
          {
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          },
        );
        if (sIdEffective.isNotEmpty && subIdEffective.isNotEmpty) {
          batch.update(
            firestore.collection('students').doc(sIdEffective),
            {'enrolledSubject': FieldValue.arrayUnion([subIdEffective])},
          );
        }
      } else {
        // Special case: allow enrolling by paying a monthly fee for a subject
        // If paymentFor is 'monthly' and no enrollment exists, create an approved enrollment
        if (paymentFor == 'monthly' && sIdEffective.isNotEmpty && subIdEffective.isNotEmpty && tId.isNotEmpty) {
          // Check whether student is already enrolled in this subject
          final studentDoc = await firestore.collection('students').doc(sIdEffective).get();
          final studentData = studentDoc.data() ?? {};
          final enrolled = List<String>.from(studentData['enrolledSubject'] ?? []);
          if (!enrolled.contains(subIdEffective)) {
            final newEnrId = await _generateNextEnrId();
            batch.set(
              firestore.collection('enrollments').doc(newEnrId),
              {
                'enrId': newEnrId,
                'sId': sIdEffective,
                'sName': studentData['sName'] ?? '',
                'subId': subIdEffective,
                'subName': subName,
                'tId': tId,
                'status': 'approved',
                'requestedAt': FieldValue.serverTimestamp(),
                'approvedAt': FieldValue.serverTimestamp(),
              },
            );
            // Link payment to new enrollment
            batch.update(
              firestore.collection('payments').doc(payId),
              {'enrId': newEnrId},
            );
            batch.update(
              firestore.collection('students').doc(sIdEffective),
              {'enrolledSubject': FieldValue.arrayUnion([subIdEffective])},
            );
          }
        }
      }

      await batch.commit();

      // Clean up any other pending payments linked to the same enrollment
      // (prevents duplicate pending records when an online payment finishes)
      if (enrId != null && enrId != '-' ) {
        try {
          final otherPending = await firestore
              .collection('payments')
              .where('enrId', isEqualTo: enrId)
              .where('status', isEqualTo: 'pending')
              .get();

          if (otherPending.docs.isNotEmpty) {
            final cleanup = firestore.batch();
            for (final doc in otherPending.docs) {
              if ((doc.data()['payId'] as String?) == payId) continue;
              cleanup.update(doc.reference, {
                'status': 'cancelled',
                'paymentType': 'cancelled',
              });
            }
            await cleanup.commit();
          }
        } catch (e) {
          debugPrint('[processOnlinePayment][cleanup] Error: $e');
        }
      }
    } catch (e) {
      debugPrint('[processOnlinePayment] Error: $e');
      rethrow;
    }
  }

  /// Choose physical payment for a pending payment
  Future<void> choosePhysicalPayment(String payId) async {
    if (payId.trim().isEmpty) {
      throw Exception('Invalid payId provided to choosePhysicalPayment');
    }
    try {
      await firestore.collection('payments').doc(payId).update({
        'paymentType': 'physical',
      });
    } catch (e) {
      debugPrint('[choosePhysicalPayment] Error: $e');
      rethrow;
    }
  }

  /// Admin marks a physical or other pending payment as paid
  Future<void> adminMarkPaymentPaid({
    required String payId,
    required String adminAId,
    String? enrId,
    String? sId,
    String? subId,
    String? subName,
  }) async {
    if (payId.trim().isEmpty) {
      throw Exception('Invalid payId provided to adminMarkPaymentPaid');
    }
    try {
      final batch = firestore.batch();
      batch.update(
        firestore.collection('payments').doc(payId),
        {
          'status': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
        },
      );

      if (enrId != null && enrId != '-' && sId != null && subId != null) {
        batch.update(
          firestore.collection('enrollments').doc(enrId),
          {
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          },
        );
        batch.update(
          firestore.collection('students').doc(sId),
          {'enrolledSubject': FieldValue.arrayUnion([subId])},
        );
      }

      await batch.commit();

      if (enrId != null && enrId != '-' && sId != null && subId != null && subName != null) {
        await _sendEnrollmentApprovedNotification(
          sId: sId,
          subName: subName,
          adminAId: adminAId,
        );
      }
    } catch (e) {
      debugPrint('[adminMarkPaymentPaid] Error: $e');
      rethrow;
    }
  }

  /// Get pending physical payments for admin review
  Stream<List<PaymentModel>> getPendingPhysicalPayments() {
    return firestore
        .collection('payments')
        .where('status', isEqualTo: 'pending')
        .where('paymentType', isEqualTo: 'physical')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc.data()))
            .toList());
  }

  /// Get all payments for admin history
  Stream<List<PaymentModel>> getAllPayments() {
    return firestore
        .collection('payments')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc.data()))
            .toList());
  }
}
