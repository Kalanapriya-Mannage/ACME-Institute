import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class ChatbotService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> processMessage({
    required String message,
    required Student student,
  }) async {
    final lower = message.toLowerCase().trim();

    if (_matchesGreeting(lower)) {
      return _greetingResponse(student);
    }
    if (_matchesHelp(lower)) {
      return _helpResponse();
    }
    if (_matchesTimetable(lower)) {
      return await _timetableResponse(student);
    }
    if (_matchesAttendance(lower)) {
      return await _attendanceResponse(student);
    }
    if (_matchesResults(lower)) {
      return await _resultsResponse(student);
    }
    if (_matchesPayments(lower)) {
      return await _paymentsResponse(student);
    }
    if (_matchesTeachers(lower)) {
      return await _teachersResponse(student);
    }
    if (_matchesSubjects(lower)) {
      return await _subjectsResponse(student);
    }
    if (_matchesEnrollment(lower)) {
      return await _enrollmentResponse(student);
    }
    if (_matchesProfile(lower)) {
      return _profileResponse(student);
    }

    return _defaultResponse();
  }

  bool _containsAny(String msg, List<String> keywords) {
    return keywords.any((keyword) => msg.contains(keyword));
  }

  bool _matchesGreeting(String msg) {
    return _containsAny(msg, [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      'howdy',
    ]);
  }

  bool _matchesHelp(String msg) {
    return _containsAny(msg, [
      'help',
      'what can you do',
      'options',
      'menu',
      'commands',
    ]);
  }

  bool _matchesTimetable(String msg) {
    return _containsAny(msg, [
      'timetable',
      'schedule',
      'class',
      'when',
      'time',
      'day',
      'my classes',
      'next class',
    ]);
  }

  bool _matchesAttendance(String msg) {
    return _containsAny(msg, [
      'attendance',
      'present',
      'absent',
      'percentage',
      'attend',
      'my attendance',
      'attended',
    ]);
  }

  bool _matchesResults(String msg) {
    return _containsAny(msg, [
      'result',
      'marks',
      'grade',
      'exam',
      'test',
      'score',
      'term',
      'my results',
      'how did i do',
      'performance',
    ]);
  }

  bool _matchesPayments(String msg) {
    return _containsAny(msg, [
      'payment',
      'fee',
      'pay',
      'paid',
      'pending',
      'due',
      'amount',
      'monthly fee',
      'how much',
      'invoice',
    ]);
  }

  bool _matchesTeachers(String msg) {
    return _containsAny(msg, [
      'teacher',
      'sir',
      'madam',
      'miss',
      'contact',
      'whatsapp',
      'who teaches',
      'my teacher',
      'instructor',
    ]);
  }

  bool _matchesSubjects(String msg) {
    return _containsAny(msg, [
      'subject',
      'enrolled',
      'studying',
      'my subjects',
      'what subjects',
      'which subjects',
    ]);
  }

  bool _matchesEnrollment(String msg) {
    return _containsAny(msg, [
      'enrollment',
      'enroll',
      'approved',
      'pending approval',
      'my enrollment',
      'registration',
    ]);
  }

  bool _matchesProfile(String msg) {
    return _containsAny(msg, [
      'profile',
      'my details',
      'my info',
      'about me',
      'my profile',
      'who am i',
      'name',
      'school',
      'grade',
    ]);
  }

  String _greetingResponse(Student student) {
    final firstName = student.sName.split(' ').first;
    return 'Hello again $firstName! 👋\n\n'
        'How can I help you today?\n\n'
        'You can ask me about:\n'
        '📅 Timetable\n'
        '📊 Attendance\n'
        '📝 Results\n'
        '💳 Payments\n'
        '👨‍🏫 Teachers\n'
        '📚 Subjects';
  }

  String _helpResponse() {
    return '🤖 I\'m ACME Assistant! Here is what I can help you with:\n\n'
        '📅 Timetable — "show my timetable"\n'
        '📊 Attendance — "my attendance"\n'
        '📝 Results — "my results"\n'
        '💳 Payments — "my payments"\n'
        '👨‍🏫 Teachers — "my teachers"\n'
        '📚 Subjects — "my subjects"\n'
        '📋 Enrollment — "my enrollment"\n'
        '👤 Profile — "my profile"\n\n'
        'Just type your question naturally!';
  }

  Future<String> _timetableResponse(Student student) async {
    try {
      if (student.enrolledSubject.isEmpty) {
        return '📅 You are not enrolled in any subjects yet.\n\n'
            'Please enroll in a subject first to see your timetable.';
      }

      final List<String> lines = [];
      for (final subId in student.enrolledSubject) {
        final query = await _db
            .collection('timetable')
            .where('grade', isEqualTo: student.grade)
            .where('subId', isEqualTo: subId)
            .get();

        for (final doc in query.docs) {
          final data = doc.data();
          final subName = data['subName'] ?? data['subId'] ?? subId;
          final day = data['day'] ?? 'Unknown day';
          final time = data['time'] ?? 'Unknown time';
          lines.add('• $subName — $day at $time');
        }
      }

      if (lines.isEmpty) {
        return '📅 No classes have been scheduled yet.\n\n'
            'Please check back later or contact admin.';
      }

      return '📅 Here is your class schedule:\n\n'
          '${lines.join('\n')}\n\n'
          'Make sure you attend all your classes! 📚';
    } catch (e) {
      return '⚠️ Could not load timetable.\nPlease try again.';
    }
  }

  Future<String> _attendanceResponse(Student student) async {
    try {
      if (student.enrolledSubject.isEmpty) {
        return '📊 You are not enrolled in any subjects yet.';
      }

      final List<String> lines = [];
      bool hasWarning = false;

      for (final subId in student.enrolledSubject) {
        final query = await _db
            .collection('attendance')
            .where('subId', isEqualTo: subId)
            .where('grade', isEqualTo: student.grade)
            .get();

        if (query.docs.isEmpty) {
          lines.add('• $subId: No classes held yet');
          continue;
        }

        final attendanceDocs = query.docs
            .map((e) => e.data())
            .where((data) {
              final students = data['students'] as Map<String, dynamic>?;
              return students != null && students.containsKey(student.sId);
            })
            .toList();

        if (attendanceDocs.isEmpty) {
          lines.add('• $subId: No attendance records yet');
          continue;
        }

        final total = attendanceDocs.length;
        final present = attendanceDocs
            .where((data) =>
                (data['students'] as Map<String, dynamic>)[student.sId] ==
                'present')
            .length;
        final pct = total > 0 ? (present / total) * 100 : 0.0;
        final percentage = pct.toStringAsFixed(0);
        final icon = pct >= 75 ? '✅' : '⚠️';

        if (pct < 75) {
          hasWarning = true;
        }

        lines.add('• $subId: $percentage% ($present/$total classes) $icon');
      }

      final buffer = StringBuffer();
      buffer.writeln('📊 Your attendance summary:\n');
      buffer.writeln(lines.join('\n'));
      if (hasWarning) {
        buffer.writeln('\n⚠️ One or more subjects are below 75%.\nTry to attend more classes!');
      }

      return buffer.toString();
    } catch (e) {
      return '⚠️ Could not load attendance.\nPlease try again.';
    }
  }

  Future<String> _resultsResponse(Student student) async {
    try {
      if (student.enrolledSubject.isEmpty) {
        return '📝 You are not enrolled in any subjects yet.';
      }

      final List<String> lines = [];
      for (final subId in student.enrolledSubject) {
        final doc = await _db.collection('results').doc('${student.sId}_$subId').get();
        if (!doc.exists || doc.data() == null) {
          lines.add('• $subId: No results yet');
          continue;
        }

        final data = doc.data()!;
        final subName = data['subName'] ?? subId;
        final term1 = Map<String, dynamic>.from(data['term1'] ?? {});
        final term2 = Map<String, dynamic>.from(data['term2'] ?? {});
        final term3 = Map<String, dynamic>.from(data['term3'] ?? {});

        final t1Marks = (term1['marks']?.toString().isNotEmpty ?? false)
            ? term1['marks'].toString()
            : '-';
        final t1Grade = (term1['grade']?.toString().isNotEmpty ?? false)
            ? term1['grade'].toString()
            : '-';
        final t2Marks = (term2['marks']?.toString().isNotEmpty ?? false)
            ? term2['marks'].toString()
            : '-';
        final t2Grade = (term2['grade']?.toString().isNotEmpty ?? false)
            ? term2['grade'].toString()
            : '-';
        final t3Marks = (term3['marks']?.toString().isNotEmpty ?? false)
            ? term3['marks'].toString()
            : '-';
        final t3Grade = (term3['grade']?.toString().isNotEmpty ?? false)
            ? term3['grade'].toString()
            : '-';

        lines.add('$subName:\n'
            '  1st Term: $t1Marks ($t1Grade)\n'
            '  2nd Term: $t2Marks ($t2Grade)\n'
            '  3rd Term: $t3Marks ($t3Grade)');
      }

      return '📝 Your exam results:\n\n${lines.join('\n\n')}\n\nKeep up the great work! 🌟';
    } catch (e) {
      return '⚠️ Could not load results.\nPlease try again.';
    }
  }

  Future<String> _paymentsResponse(Student student) async {
    try {
      final query = await _db
          .collection('payments')
          .where('sId', isEqualTo: student.sId)
          .get();

      final payments = query.docs.map((doc) => doc.data()).toList();
      if (payments.isEmpty) {
        return '💳 You have no payment records yet.';
      }

      final pending = payments.where((payment) {
        final status = payment['status']?.toString().toLowerCase() ?? '';
        return status != 'paid';
      }).toList();
      final paid = payments.where((payment) {
        final status = payment['status']?.toString().toLowerCase() ?? '';
        return status == 'paid';
      }).toList();

      final buffer = StringBuffer();
      buffer.writeln('💳 Your payment status:\n');

      if (pending.isNotEmpty) {
        buffer.writeln('Pending payments:');
        for (final payment in pending) {
          final subName = payment['subName'] ?? payment['subId'] ?? 'Subject';
          final month = payment['month'] ?? 'Unknown month';
          final amount = payment['amount'] ?? 'Rs. 0';
          buffer.writeln('• $subName — $month — $amount');
        }
        buffer.writeln();
      }

      if (paid.isNotEmpty) {
        buffer.writeln('✅ Recent paid:');
        for (final payment in paid.take(3)) {
          final subName = payment['subName'] ?? payment['subId'] ?? 'Subject';
          final month = payment['month'] ?? 'Unknown month';
          final amount = payment['amount'] ?? 'Rs. 0';
          buffer.writeln('• $subName — $month — $amount');
        }
        buffer.writeln();
      }

      if (pending.isNotEmpty) {
        buffer.writeln('Please visit the institute or use the payment section to pay. 💰');
      }

      return buffer.toString().trim();
    } catch (e) {
      return '⚠️ Could not load payments.\nPlease try again.';
    }
  }

  Future<String> _teachersResponse(Student student) async {
    try {
      if (student.enrolledSubject.isEmpty) {
        return '👨‍🏫 You are not enrolled in any subjects yet.';
      }

      final List<String> lines = [];
      for (final subId in student.enrolledSubject) {
        final enrollmentQuery = await _db
            .collection('enrollments')
            .where('sId', isEqualTo: student.sId)
            .where('subId', isEqualTo: subId)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();

        if (enrollmentQuery.docs.isEmpty) continue;
        final tId = enrollmentQuery.docs.first.data()['tId'] ?? '';
        if (tId.isEmpty) continue;

        final teacherDoc = await _db.collection('teachers').doc(tId).get();
        if (!teacherDoc.exists || teacherDoc.data() == null) continue;

        final data = teacherDoc.data()!;
        final subject = data['subject'] ?? 'Subject';
        final name = data['name'] ?? 'Teacher';
        final whatsapp = data['whatsapp'] ?? 'Not available';
        final monthlyFee = data['monthlyFee'] ?? 'Rs. 0';
        final experience = data['experience'] ?? 'N/A';

        lines.add('$subject:\n'
            '  $name\n'
            '  📱 WhatsApp: $whatsapp\n'
            '  💰 Monthly Fee: $monthlyFee\n'
            '  ⭐ Experience: $experience');
      }

      if (lines.isEmpty) {
        return '👨‍🏫 No approved teacher assignments found yet.';
      }

      return '👨‍🏫 Your teachers:\n\n${lines.join('\n\n')}';
    } catch (e) {
      return '⚠️ Could not load teacher information.\nPlease try again.';
    }
  }

  Future<String> _subjectsResponse(Student student) async {
    try {
      if (student.enrolledSubject.isEmpty) {
        return '📚 You are not enrolled in any subjects yet.\n\n'
            'Browse subjects and enroll today!';
      }

      final List<String> lines = [];
      for (final subId in student.enrolledSubject) {
        final doc = await _db.collection('subjects').doc(subId).get();
        if (!doc.exists || doc.data() == null) continue;
        final data = doc.data()!;
        final subName = data['subName'] ?? subId;
        lines.add('• $subName (Grade ${student.grade})');
      }

      if (lines.isEmpty) {
        return '📚 Your enrolled subjects could not be loaded.';
      }

      return '📚 Your enrolled subjects:\n\n${lines.join('\n')}\n\n'
          'You are doing great by learning multiple subjects! 🎓';
    } catch (e) {
      return '⚠️ Could not load subjects.\nPlease try again.';
    }
  }

  Future<String> _enrollmentResponse(Student student) async {
    try {
      final query = await _db
          .collection('enrollments')
          .where('sId', isEqualTo: student.sId)
          .get();

      if (query.docs.isEmpty) {
        return '📋 You have no enrollment requests yet.\n\n'
            'Browse subjects to enroll!';
      }

      final List<String> lines = [];
      for (final doc in query.docs) {
        final data = doc.data();
        final subName = data['subName'] ?? 'Subject';
        final status = data['status'] == 'approved' ? '✅ Approved' : '⏳ Pending Approval';
        lines.add('• $subName — $status');
      }

      return '📋 Your enrollment status:\n\n${lines.join('\n')}\n\n'
          'Pending enrollments will be approved after payment.';
    } catch (e) {
      return '⚠️ Could not load enrollment status.\nPlease try again.';
    }
  }

  String _profileResponse(Student student) {
    return '👤 Your profile:\n\n'
        'Name:    ${student.sName}\n'
        'Grade:   ${student.grade}\n'
        'Age:     ${student.age} years old\n'
        'School:  ${student.school}';
  }

  String _defaultResponse() {
    return '🤔 I\'m not sure I understood that.\n\n'
        'Here is what I can help with:\n'
        '📅 Timetable • 📊 Attendance\n'
        '📝 Results • 💳 Payments\n'
        '👨‍🏫 Teachers • 📚 Subjects\n\n'
        'Try asking: "show my timetable" or "what are my results?"';
  }
}
