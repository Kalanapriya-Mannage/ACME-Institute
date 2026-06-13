import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationModel {
  final String nId;
  final String category;
  final String message;
  final DateTime sentAt;
  final String sentBy;
  final String targetAudience;
  final String title;

  NotificationModel({
    required this.nId,
    required this.category,
    required this.message,
    required this.sentAt,
    required this.sentBy,
    required this.targetAudience,
    required this.title,
  });

  factory NotificationModel.fromFirestore(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    debugPrint('[NotificationModel] Parsing data: $data');
    try {
      // Safely extract each field from multiple possible key variants.
      final nId = _parseString(
        data['nId'] ?? data['n_Id'] ?? data['id'] ?? documentId,
        documentId ?? 'unknown',
      );
      final category = _parseString(
        data['category'] ?? data['Category'],
        'General',
      );
      final message = _parseString(data['message'], '');
      final sentBy = _parseString(
        data['sentBy'] ?? data['sentby'] ?? data['sent_by'] ?? data['sender'],
        'system',
      );
      final targetAudience = _parseString(
        data['targetAudience'] ?? data['target_audience'] ?? data['target'] ?? 'all',
        'all',
      ).toLowerCase();
      final title = _parseString(data['title'] ?? data['subject'], 'Notification');

      DateTime sentAt;
      final sentAtRaw = data['sentAt'] ?? data['sent_at'];

      if (sentAtRaw is Timestamp) {
        sentAt = sentAtRaw.toDate();
      } else if (sentAtRaw is DateTime) {
        sentAt = sentAtRaw;
      } else if (sentAtRaw is int) {
        sentAt = DateTime.fromMillisecondsSinceEpoch(sentAtRaw);
      } else if (sentAtRaw is String) {
        sentAt = DateTime.tryParse(sentAtRaw) ?? DateTime.now();
      } else if (sentAtRaw == null) {
        debugPrint('[NotificationModel] Warning: sentAt is null, using current time');
        sentAt = DateTime.now();
      } else {
        debugPrint('[NotificationModel] Warning: sentAt is ${sentAtRaw.runtimeType}, using current time');
        sentAt = DateTime.now();
      }

      return NotificationModel(
        nId: nId,
        category: category,
        message: message,
        sentAt: sentAt,
        sentBy: sentBy,
        targetAudience: targetAudience,
        title: title,
      );
    } catch (e) {
      debugPrint('[NotificationModel] ERROR parsing notification: $e, data: $data');
      return NotificationModel(
        nId: documentId ?? 'unknown',
        category: 'General',
        message: 'Error loading notification',
        sentAt: DateTime.now(),
        sentBy: 'system',
        targetAudience: 'all',
        title: 'Error',
      );
    }
  }

  static String _parseString(dynamic value, String fallback) {
    if (value == null) {
      return fallback;
    }
    if (value is String) {
      return value.trim().isEmpty ? fallback : value.trim();
    }
    return value.toString().trim().isEmpty ? fallback : value.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'nId': nId,
      'category': category,
      'message': message,
      'sentAt': sentAt,
      'sentBy': sentBy,
      'targetAudience': targetAudience,
      'title': title,
    };
  }

  @override
  String toString() => 'Notification(nId: $nId, title: $title, audience: $targetAudience)';
}
