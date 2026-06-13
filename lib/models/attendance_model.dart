class AttendanceModel {
  final String attId;
  final String subId;
  final String subName;
  final String tId;
  final String grade;
  final String date;
  final String day;
  final String time;
  final String ttId;
  final Map<String, String> students;

  AttendanceModel({
    required this.attId,
    required this.subId,
    required this.subName,
    required this.tId,
    required this.grade,
    required this.date,
    required this.day,
    required this.time,
    required this.ttId,
    required this.students,
  });

  factory AttendanceModel.fromFirestore(Map<String, dynamic> data) {
    final rawStudents = data['students'];
    Map<String, String> studentsMap = {};
    if (rawStudents is Map) {
      studentsMap = Map<String, String>.from(
        rawStudents.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }

    return AttendanceModel(
      attId: data['attId'] ?? '',
      subId: data['subId'] ?? '',
      subName: data['subName'] ?? '',
      tId: data['tId'] ?? '',
      grade: data['grade'] ?? '',
      date: data['date'] ?? '',
      day: data['day'] ?? '',
      time: data['time'] ?? '',
      ttId: data['ttId'] ?? '',
      students: studentsMap,
    );
  }

  Map<String, dynamic> toMap() => {
        'attId': attId,
        'subId': subId,
        'subName': subName,
        'tId': tId,
        'grade': grade,
        'date': date,
        'day': day,
        'time': time,
        'ttId': ttId,
        'students': students,
      };
}

class AttendanceSummary {
  final String subId;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final double percentage;

  AttendanceSummary({
    required this.subId,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.percentage,
  });
}
