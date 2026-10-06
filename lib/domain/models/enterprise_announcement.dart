import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Priority level of an enterprise broadcast announcement.
enum AnnouncementPriority {
  normal,
  high,
  urgent,
}

/// Domain model representing a company-wide or department-targeted broadcast announcement.
class EnterpriseAnnouncement {
  final String id;
  final String enterpriseId;
  final String title;
  final String message;
  final AnnouncementPriority priority;
  final List<String> targetRoles; // Empty means all roles
  final String authorName;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final List<String> readByUids;

  const EnterpriseAnnouncement({
    required this.id,
    required this.enterpriseId,
    required this.title,
    required this.message,
    this.priority = AnnouncementPriority.normal,
    this.targetRoles = const [],
    required this.authorName,
    required this.publishedAt,
    this.expiresAt,
    this.readByUids = const [],
  });

  Color get priorityColor {
    switch (priority) {
      case AnnouncementPriority.normal:
        return const Color(0xFF3B82F6); // Blue
      case AnnouncementPriority.high:
        return const Color(0xFFF59E0B); // Amber
      case AnnouncementPriority.urgent:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get priorityIcon {
    switch (priority) {
      case AnnouncementPriority.normal:
        return Icons.campaign_rounded;
      case AnnouncementPriority.high:
        return Icons.priority_high_rounded;
      case AnnouncementPriority.urgent:
        return Icons.emergency_rounded;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'enterpriseId': enterpriseId,
      'title': title,
      'message': message,
      'priority': priority.name,
      'targetRoles': targetRoles,
      'authorName': authorName,
      'publishedAt': Timestamp.fromDate(publishedAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'readByUids': readByUids,
    };
  }

  factory EnterpriseAnnouncement.fromJson(Map<String, dynamic> json, {String docId = ''}) {
    AnnouncementPriority parsePriority(String? p) {
      return AnnouncementPriority.values.firstWhere(
        (e) => e.name == p,
        orElse: () => AnnouncementPriority.normal,
      );
    }

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return EnterpriseAnnouncement(
      id: docId.isNotEmpty ? docId : (json['id'] as String? ?? ''),
      enterpriseId: json['enterpriseId'] as String? ?? '',
      title: json['title'] as String? ?? 'Announcement',
      message: json['message'] as String? ?? '',
      priority: parsePriority(json['priority'] as String?),
      targetRoles: (json['targetRoles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      authorName: json['authorName'] as String? ?? 'Management',
      publishedAt: parseDate(json['publishedAt']),
      expiresAt: json['expiresAt'] != null ? parseDate(json['expiresAt']) : null,
      readByUids: (json['readByUids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  factory EnterpriseAnnouncement.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return EnterpriseAnnouncement.fromJson(data, docId: doc.id);
  }
}
