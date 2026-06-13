class TimetableModel {
  final String ttId;
  final String subId;
  final String subName;
  final String tId;
  final String grade;
  final String day;
  final String time;

  TimetableModel({
    required this.ttId,
    required this.subId,
    required this.subName,
    required this.tId,
    required this.grade,
    required this.day,
    required this.time,
  });

  factory TimetableModel.fromFirestore(Map<String, dynamic> data) {
    return TimetableModel(
      ttId: data['ttId'] ?? '',
      subId: data['subId'] ?? '',
      subName: data['subName'] ?? '',
      tId: data['tId'] ?? '',
      grade: data['grade'] ?? '',
      day: data['day'] ?? '',
      time: data['time'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'ttId': ttId,
        'subId': subId,
        'subName': subName,
        'tId': tId,
        'grade': grade,
        'day': day,
        'time': time,
      };

  @override
  String toString() =>
      'Timetable(ttId: $ttId, subject: $subName, grade: $grade, day: $day, time: $time)';
}
