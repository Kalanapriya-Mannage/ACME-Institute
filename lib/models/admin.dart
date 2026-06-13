class Admin {
  final String aId;
  final String aName;
  final String aEmail;
  final String password;

  Admin({
    required this.aId,
    required this.aName,
    required this.aEmail,
    required this.password,
  });

  factory Admin.fromFirestore(Map<String, dynamic> data) {
    return Admin(
      aId: data['aId'] ?? '',
      aName: data['aName'] ?? '',
      aEmail: data['aEmail'] ?? '',
      password: data['password'] ?? '',
    );
  }
}
