import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/admin/admin_enrollments.dart';
import '../../features/admin/admin_notifications.dart';
import '../../features/admin/admin_payment.dart';
import '../../features/admin/admin_profile.dart';
import '../../features/admin/admin_student_detail.dart';
import '../../features/admin/admin_students.dart';
import '../../features/admin/admin_subjects.dart';
import '../../features/admin/admin_teachers.dart';
import '../../features/admin/admin_timetable.dart';
import '../../features/admin/admin_settings.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/student/enrollment/payment_screen.dart';
import '../../features/student/enrollment/teacher_profile_enroll.dart';
import '../../features/student/enrollment/teachers_for_subject.dart';
import '../../features/student/student_attendance.dart';
import '../../features/student/student_dashboard.dart';
import '../../features/student/student_notifications.dart';
import '../../features/student/student_payment.dart';
import '../../features/student/student_profile.dart';
import '../../features/student/student_results.dart';
import '../../features/student/student_subjects.dart';
import '../../features/student/student_teachers.dart';
import '../../features/student/student_timetable.dart';
import '../../features/teacher/grade_class_view.dart';
import '../../features/teacher/teacher_dashboard.dart';
import '../../features/teacher/teacher_notifications.dart';
import '../../features/teacher/teacher_profile.dart';
import '../../features/teacher/teacher_students.dart';
import '../../features/teacher/teacher_student_detail.dart';
import '../../features/teacher/teacher_attendance.dart';
import '../../features/teacher/teacher_timetable.dart';

class AppRouter {
  static const roleSelection = '/';
  static const login = '/login';

  static String dashboardFor(String role) => role == 'student'
      ? '/student/dashboard'
      : role == 'teacher'
          ? '/teacher/dashboard'
          : '/admin/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case '/login':
        return MaterialPageRoute(
          builder: (_) => LoginScreen(role: settings.arguments as String? ?? 'student'),
          settings: settings,
        );
      case '/student/dashboard':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentDashboard()),
          settings: settings,
        );
      case '/student/profile':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentProfile()),
          settings: settings,
        );
      case '/student/subjects':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentSubjects()),
          settings: settings,
        );
      case '/student/subjects/teachers':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const TeachersForSubject()),
          settings: settings,
        );
      case '/student/teacher/profile':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const TeacherProfileEnroll()),
          settings: settings,
        );
      case '/student/enroll/payment':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const EnrollmentPayment()),
          settings: settings,
        );
      case '/student/teachers':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentTeachers()),
          settings: settings,
        );
      case '/student/timetable':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentTimetable()),
          settings: settings,
        );
      case '/student/attendance':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentAttendance()),
          settings: settings,
        );
      case '/student/results':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentResults()),
          settings: settings,
        );
      case '/student/payment':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentPayment()),
          settings: settings,
        );
      case '/student/notifications':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'student', const StudentNotifications()),
          settings: settings,
        );
      case '/teacher/dashboard':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherDashboard()),
          settings: settings,
        );
      case '/teacher/profile':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherProfile()),
          settings: settings,
        );
      case '/teacher/timetable':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherTimetable()),
          settings: settings,
        );
      case '/teacher/attendance':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherAttendance()),
          settings: settings,
        );
      case '/teacher/notifications':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherNotifications()),
          settings: settings,
        );
      case '/teacher/students':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherStudents()),
          settings: settings,
        );
      case '/teacher/student/detail':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const TeacherStudentDetail()),
          settings: settings,
        );
      case '/teacher/grade':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'teacher', const GradeClassView()),
          settings: settings,
        );
      case '/admin/dashboard':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminDashboard()),
          settings: settings,
        );
      case '/admin/profile':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminProfile()),
          settings: settings,
        );
      case '/admin/students':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminStudents()),
          settings: settings,
        );
      case '/admin/student/detail':
        return MaterialPageRoute(
          builder: (context) {
            final studentId = settings.arguments as String?;
            return _guardedPage(
              context,
              'admin',
              AdminStudentDetail(studentId: studentId ?? ''),
            );
          },
          settings: settings,
        );
      case '/admin/teachers':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminTeachers()),
          settings: settings,
        );
      case '/admin/teacher/profile':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const TeacherProfile()),
          settings: settings,
        );
      case '/admin/subjects':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminSubjects()),
          settings: settings,
        );
      case '/admin/notifications':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminNotifications()),
          settings: settings,
        );
      case '/admin/payments':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminPayment()),
          settings: settings,
        );
      case '/admin/enrollments':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminEnrollments()),
          settings: settings,
        );
      case '/admin/timetable':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminTimetable()),
          settings: settings,
        );
      case '/admin/settings':
        return MaterialPageRoute(
          builder: (context) => _guardedPage(context, 'admin', const AdminSettings()),
          settings: settings,
        );
      default:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
    }
  }

  static Widget _guardedPage(BuildContext context, String requiredRole, Widget screen) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || auth.userRole != requiredRole) {
      return const RoleSelectionScreen();
    }
    return screen;
  }
}
