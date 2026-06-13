class Subject {
  final String subId;
  final String subName;
  final List<String> grades;
  final List<String> teacherIds;

  Subject({
    required this.subId,
    required this.subName,
    required this.grades,
    required this.teacherIds,
  });

  String get gradesDisplay =>
      grades.isNotEmpty ? 'Grade ${grades.first} - ${grades.last}' : '';

  factory Subject.fromFirestore(Map<String, dynamic> data) {
    return Subject(
      subId: data['subId'] ?? '',
      subName: data['subName'] ?? '',
      grades: List<String>.from(data['grades'] ?? []),
      teacherIds: List<String>.from(data['teacherIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subId': subId,
      'subName': subName,
      'grades': grades,
      'teacherIds': teacherIds,
    };
  }
}
