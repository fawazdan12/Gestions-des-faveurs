import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  favorRequested,
  favorAccepted,
  favorRefused,
  favorCompleted,
  friendRequestReceived,
  friendRequestAccepted
}

class NotificationModel {
  final String id;
  final String recipientUid;
  final String senderUid;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientUid,
    required this.senderUid,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      recipientUid: map['recipientUid'] ?? '',
      senderUid: map['senderUid'] ?? '',
      type: _typeFromString(map['type']),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientUid': recipientUid,
      'senderUid': senderUid,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'favorRequested':
        return NotificationType.favorRequested;
      case 'favorAccepted':
        return NotificationType.favorAccepted;
      case 'favorRefused':
        return NotificationType.favorRefused;
      case 'favorCompleted':
        return NotificationType.favorCompleted;
      case 'friendRequestReceived':
        return NotificationType.friendRequestReceived;
      case 'friendRequestAccepted':
        return NotificationType.friendRequestAccepted;
      default:
        return NotificationType.favorRequested;
    }
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}