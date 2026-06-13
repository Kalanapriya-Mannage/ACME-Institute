class TermResult {
  final String marks;
  final String grade;

  TermResult({required this.marks, required this.grade});

  factory TermResult.fromMap(Map<String, dynamic> data) {
    return TermResult(
      marks: data['marks'] ?? '',
      grade: data['grade'] ?? '',
    );
  }

  // Check if result has been entered
  bool get hasResult => marks.isNotEmpty && grade.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'marks': marks,
        'grade': grade,
      };
}

class ResultModel {
  final String resultId;
  final String sId;
  final String subId;
  final String subName;
  final String? teacherId;
  final String? teacherName;
  final TermResult term1;
  final TermResult term2;
  final TermResult term3;

  ResultModel({
    required this.resultId,
    required this.sId,
    required this.subId,
    required this.subName,
    this.teacherId,
    this.teacherName,
    required this.term1,
    required this.term2,
    required this.term3,
  });

  factory ResultModel.fromFirestore(Map<String, dynamic> data) {
    return ResultModel(
      resultId: data['resultId'] ?? '',
      sId: data['sId'] ?? '',
      subId: data['subId'] ?? '',
      subName: data['subName'] ?? '',
      teacherId: data['teacherId'] as String?,
      teacherName: data['teacherName'] as String?,
      term1: TermResult.fromMap(
          Map<String, dynamic>.from(data['term1'] ?? {})),
      term2: TermResult.fromMap(
          Map<String, dynamic>.from(data['term2'] ?? {})),
      term3: TermResult.fromMap(
          Map<String, dynamic>.from(data['term3'] ?? {})),
    );
  }

  Map<String, dynamic> toMap() => {
        'resultId': resultId,
        'sId': sId,
        'subId': subId,
        'subName': subName,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'term1': term1.toMap(),
        'term2': term2.toMap(),
        'term3': term3.toMap(),
      };
}
