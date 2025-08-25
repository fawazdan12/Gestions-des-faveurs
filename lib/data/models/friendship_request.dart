import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipRequestStatus { pending, accepted, declined }

class FriendshipRequest {
  final String id;
  final String senderUid;
  final String receiverUid;
  final FriendshipRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendshipRequest({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendshipRequest.fromMap(Map<String, dynamic> map) {
    return FriendshipRequest(
      id: map['id'] ?? '',
      senderUid: map['senderUid'] ?? '',
      receiverUid: map['receiverUid'] ?? '',
      status: _statusFromString(map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null 
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  static FriendshipRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FriendshipRequestStatus.pending;
      case 'accepted':
        return FriendshipRequestStatus.accepted;
      case 'declined':
        return FriendshipRequestStatus.declined;
      default:
        return FriendshipRequestStatus.pending;
    }
  }
}