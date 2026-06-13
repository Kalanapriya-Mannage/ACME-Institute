class Student {
  final String sId;
  final String sName;
  final String age;
  final String grade;
  final String school;
  final String guardianName;
  final String guardianContact;
  final String email;
  final String password;
  final List<String> enrolledSubject;
  final List<String> enrolledTeacher;

  Student({
    required this.sId,
    required this.sName,
    required this.age,
    required this.grade,
    required this.school,
    required this.guardianName,
    required this.guardianContact,
    required this.email,
    required this.password,
    required this.enrolledSubject,
    required this.enrolledTeacher,
  });

  factory Student.fromFirestore(Map<String, dynamic> data) {
    return Student(
      sId: data['sId'] ?? '',
      sName: data['sName'] ?? '',
      age: data['age'] ?? '',
      grade: data['grade'] ?? '',
      school: data['school'] ?? '',
      guardianName: data['guardianName'] ?? '',
      guardianContact: data['guardianContact'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      enrolledSubject: List<String>.from(data['enrolledSubject'] ?? []),
      enrolledTeacher: List<String>.from(data['enrolledTeacher'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sId': sId,
      'sName': sName,
      'age': age,
      'grade': grade,
      'school': school,
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'email': email,
      'password': password,
      'enrolledSubject': enrolledSubject,
      'enrolledTeacher': enrolledTeacher,
    };
  }
}
