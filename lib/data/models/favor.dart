import 'package:cloud_firestore/cloud_firestore.dart';

enum FavorStatus { pending, accepted, refused, completed }

class Favor {
  final String id;
  final String title;
  final String description;
  final String requesterUid;
  final String targetUid;
  final FavorStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  Favor({
    required this.id,
    required this.title,
    required this.description,
    required this.requesterUid,
    required this.targetUid,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory Favor.fromMap(Map<String, dynamic> map) {
    return Favor(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requesterUid: map['requesterUid'] ?? '',
      targetUid: map['targetUid'] ?? '',
      status: _statusFromString(map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null 
          ? (map['acceptedAt'] as Timestamp).toDate() 
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requesterUid': requesterUid,
      'targetUid': targetUid,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  static FavorStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FavorStatus.pending;
      case 'accepted':
        return FavorStatus.accepted;
      case 'refused':
        return FavorStatus.refused;
      case 'completed':
        return FavorStatus.completed;
      default:
        return FavorStatus.pending;
    }
  }
}