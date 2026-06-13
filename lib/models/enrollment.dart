import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String enrId;
  final String sId;
  final String sName;
  final String subId;
  final String subName;
  final String tId;
  final String status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;

  EnrollmentModel({
    required this.enrId,
    required this.sId,
    required this.sName,
    required this.subId,
    required this.subName,
    required this.tId,
    required this.status,
    this.requestedAt,
    this.approvedAt,
  });

  factory EnrollmentModel.fromFirestore(Map<String, dynamic> data) {
    return EnrollmentModel(
      enrId: data['enrId'] ?? '',
      sId: data['sId'] ?? '',
      sName: data['sName'] ?? '',
      subId: data['subId'] ?? '',
      subName: data['subName'] ?? '',
      tId: data['tId'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'enrId': enrId,
    'sId': sId,
    'sName': sName,
    'subId': subId,
    'subName': subName,
    'tId': tId,
    'status': status,
    'requestedAt': FieldValue.serverTimestamp(),
  };
}
