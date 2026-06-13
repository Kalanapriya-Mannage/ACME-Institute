import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String payId;
  final String sId;
  final String sName;
  final String subId;
  final String subName;
  final String tId;
  final String amount;
  final String paymentFor;
  final String month;
  final String paymentType;
  final String status;
  final String enrId;
  final DateTime? requestedAt;
  final DateTime? paidAt;
  final String? cardLast4;
  final String? cardType;

  PaymentModel({
    required this.payId,
    required this.sId,
    required this.sName,
    required this.subId,
    required this.subName,
    required this.tId,
    required this.amount,
    required this.paymentFor,
    required this.month,
    required this.paymentType,
    required this.status,
    required this.enrId,
    this.requestedAt,
    this.paidAt,
    this.cardLast4,
    this.cardType,
  });

  factory PaymentModel.fromFirestore(Map<String, dynamic> data) {
    return PaymentModel(
      payId: data['payId'] ?? '',
      sId: data['sId'] ?? '',
      sName: data['sName'] ?? '',
      subId: data['subId'] ?? '',
      subName: data['subName'] ?? '',
      tId: data['tId'] ?? '',
      amount: data['amount'] ?? '',
      paymentFor: data['paymentFor'] ?? 'monthly',
      month: data['month'] ?? '',
      paymentType: data['paymentType'] ?? 'pending',
      status: data['status'] ?? 'pending',
      enrId: data['enrId'] ?? '-',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      cardLast4: data['cardLast4'] as String?,
      cardType: data['cardType'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'payId': payId,
    'sId': sId,
    'sName': sName,
    'subId': subId,
    'subName': subName,
    'tId': tId,
    'amount': amount,
    'paymentFor': paymentFor,
    'month': month,
    'paymentType': paymentType,
    'status': status,
    'enrId': enrId,
    'requestedAt': FieldValue.serverTimestamp(),
  };

  PaymentModel copyWith({
    String? payId,
    String? sId,
    String? sName,
    String? subId,
    String? subName,
    String? tId,
    String? amount,
    String? paymentFor,
    String? month,
    String? paymentType,
    String? status,
    String? enrId,
    DateTime? requestedAt,
    DateTime? paidAt,
    String? cardLast4,
    String? cardType,
  }) {
    return PaymentModel(
      payId: payId ?? this.payId,
      sId: sId ?? this.sId,
      sName: sName ?? this.sName,
      subId: subId ?? this.subId,
      subName: subName ?? this.subName,
      tId: tId ?? this.tId,
      amount: amount ?? this.amount,
      paymentFor: paymentFor ?? this.paymentFor,
      month: month ?? this.month,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      enrId: enrId ?? this.enrId,
      requestedAt: requestedAt ?? this.requestedAt,
      paidAt: paidAt ?? this.paidAt,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardType: cardType ?? this.cardType,
    );
  }
}
