import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/auth_service.dart';
import 'package:gestion_favor/data/models/notification_model.dart';
import 'package:gestion_favor/data/models/user.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  static const String _notificationsCollection = 'notifications';

  /// Vérifier si l'utilisateur est connecté
  void _requireAuth() {
    if (!_authService.isLoggedIn) {
      throw Exception('Utilisateur non connecté');
    }
  }

  /// Obtenir l'UID de l'utilisateur connecté
  String get _currentUserUid {
    _requireAuth();
    return _authService.currentUser!.uid;
  }

  /// Créer une notification générique
  Future<void> _createNotification({
    required String recipientUid,
    required String senderUid,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notificationId = _firestore.collection(_notificationsCollection).doc().id;
    
    final notification = NotificationModel(
      id: notificationId,
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: type,
      title: title,
      body: body,
      data: data ?? {},
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_notificationsCollection)
        .doc(notificationId)
        .set(notification.toMap());
  }

  /// Obtenir le nom d'affichage d'un utilisateur
  Future<String> _getUserDisplayName(String uid) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        final user = AppUser.fromMap(userDoc.data()!);
        return user.displayName;
      }
      return 'Utilisateur inconnu';
    } catch (e) {
      return 'Utilisateur inconnu';
    }
  }

  /// Notification pour une nouvelle demande de faveur
  Future<void> sendFavorRequestNotification({
    required String recipientUid,
    required String senderUid,
    required String favorId,
    required String favorTitle,
  }) async {
    final senderName = await _getUserDisplayName(senderUid);

    await _createNotification(
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: NotificationType.favorRequested,
      title: 'Nouvelle demande de faveur',
      body: '$senderName vous demande : "$favorTitle"',
      data: {
        'favorId': favorId,
        'favorTitle': favorTitle,
      },
    );
  }

  /// Notification pour une faveur acceptée
  Future<void> sendFavorAcceptedNotification({
    required String recipientUid,
    required String senderUid,
    required String favorId,
    required String favorTitle,
  }) async {
    final senderName = await _getUserDisplayName(senderUid);

    await _createNotification(
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: NotificationType.favorAccepted,
      title: 'Faveur acceptée',
      body: '$senderName a accepté votre demande : "$favorTitle"',
      data: {
        'favorId': favorId,
        'favorTitle': favorTitle,
      },
    );
  }

  /// Notification pour une faveur refusée
  Future<void> sendFavorRefusedNotification({
    required String recipientUid,
    required String senderUid,
    required String favorId,
    required String favorTitle,
  }) async {
    final senderName = await _getUserDisplayName(senderUid);

    await _createNotification(
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: NotificationType.favorRefused,
      title: 'Faveur refusée',
      body: '$senderName a refusé votre demande : "$favorTitle"',
      data: {
        'favorId': favorId,
        'favorTitle': favorTitle,
      },
    );
  }

  /// Notification pour une faveur terminée
  Future<void> sendFavorCompletedNotification({
    required String recipientUid,
    required String senderUid,
    required String favorId,
    required String favorTitle,
  }) async {
    final senderName = await _getUserDisplayName(senderUid);

    await _createNotification(
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: NotificationType.favorCompleted,
      title: 'Faveur terminée',
      body: '$senderName a terminé la faveur : "$favorTitle"',
      data: {
        'favorId': favorId,
        'favorTitle': favorTitle,
      },
    );
  }

  /// Notification pour une nouvelle demande d'amitié
  Future<void> sendFriendRequestNotification({
    required String receiverUid,
    required String senderUid,
    required String requestId,
  }) async {
    final senderName = await _getUserDisplayName(senderUid);

    await _createNotification(
      recipientUid: receiverUid,
      senderUid: senderUid,
      type: NotificationType.friendRequestReceived,
      title: 'Nouvelle demande d\'amitié',
      body: '$senderName souhaite devenir votre ami',
      data: {
        'requestId': requestId,
      },
    );
  }

  /// Notification pour une demande d'amitié acceptée
  Future<void> sendFriendRequestAcceptedNotification({
    required String recipientUid,
    required String senderUid,
  }) async {
    final senderName = await _getUserDisplayName(senderUid);

    await _createNotification(
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: NotificationType.friendRequestAccepted,
      title: 'Demande d\'amitié acceptée',
      body: '$senderName a accepté votre demande d\'amitié',
      data: {},
    );
  }

  /// Stream des notifications pour l'utilisateur connecté
  Stream<List<NotificationModel>> getUserNotifications() {
    _requireAuth();
    
    return _firestore
        .collection(_notificationsCollection)
        .where('recipientUid', isEqualTo: _currentUserUid)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limiter à 50 notifications récentes
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection(_notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead() async {
    _requireAuth();

    final batch = _firestore.batch();
    final unreadNotifications = await _firestore
        .collection(_notificationsCollection)
        .where('recipientUid', isEqualTo: _currentUserUid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Obtenir le nombre de notifications non lues
  Stream<int> getUnreadNotificationCount() {
    _requireAuth();
    
    return _firestore
        .collection(_notificationsCollection)
        .where('recipientUid', isEqualTo: _currentUserUid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection(_notificationsCollection)
        .doc(notificationId)
        .delete();
  }

  /// Supprimer les anciennes notifications (plus de 30 jours)
  Future<void> cleanupOldNotifications() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: 30));
    
    final oldNotifications = await _firestore
        .collection(_notificationsCollection)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();
    for (var doc in oldNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}