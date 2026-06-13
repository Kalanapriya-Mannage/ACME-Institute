class Teacher {
  final String tId;
  final String name;
  final String subject;
  final List<String> grades;
  final String experience;
  final String qualification;
  final String whatsapp;
  final String monthlyFee;
  final String email;
  final String password;

  Teacher({
    required this.tId,
    required this.name,
    required this.subject,
    required this.grades,
    required this.experience,
    required this.qualification,
    required this.whatsapp,
    required this.monthlyFee,
    required this.email,
    required this.password,
  });

  String get subjectDetails {
    if (subject.isEmpty && grades.isEmpty) return '';
    if (grades.isEmpty) return subject;
    final gradeDisplay = gradesDisplay;
    return '$subject ($gradeDisplay)';
  }

  String get gradesDisplay =>
      grades.isNotEmpty ? 'Grade ${grades.first} - ${grades.last}' : '';

  String get qualifications => qualification;

  String get contactInfo => whatsapp.isEmpty ? '' : 'WhatsApp - $whatsapp';

  String get id => tId;

  factory Teacher.fromFirestore(Map<String, dynamic> data) {
    return Teacher(
      tId: data['tId'] ?? '',
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      grades: List<String>.from(data['grades'] ?? []),
      experience: data['experience'] ?? '',
      qualification: data['qualification'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      monthlyFee: data['monthlyFee'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tId': tId,
      'name': name,
      'subject': subject,
      'grades': grades,
      'experience': experience,
      'qualification': qualification,
      'whatsapp': whatsapp,
      'monthlyFee': monthlyFee,
      'email': email,
      'password': password,
    };
  }
}
