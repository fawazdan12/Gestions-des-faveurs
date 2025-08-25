import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/auth_service.dart';
import 'package:gestion_favor/core/services/notification_service.dart';
import 'package:gestion_favor/data/models/friendship_request.dart';
import 'package:gestion_favor/data/models/user.dart';

class FriendshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  static const String _friendshipRequestsCollection = 'friendship_requests';

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

  /// Envoyer une demande d'amitié
  Future<void> sendFriendRequest(String receiverUid) async {
    _requireAuth();

    if (receiverUid == _currentUserUid) {
      throw Exception('Impossible de s\'envoyer une demande d\'amitié à soi-même');
    }

    // Vérifier si une demande n'existe pas déjà
    final existingRequest = await _firestore
        .collection(_friendshipRequestsCollection)
        .where('senderUid', isEqualTo: _currentUserUid)
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Une demande d\'amitié est déjà en cours');
    }

    // Vérifier si les utilisateurs sont déjà amis
    final currentUserDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_currentUserUid)
        .get();

    if (currentUserDoc.exists) {
      final userData = currentUserDoc.data()!;
      final friends = List<String>.from(userData['friends'] ?? []);
      if (friends.contains(receiverUid)) {
        throw Exception('Vous êtes déjà amis');
      }
    }

    // Créer la demande d'amitié
    final requestId = _firestore.collection(_friendshipRequestsCollection).doc().id;
    final request = FriendshipRequest(
      id: requestId,
      senderUid: _currentUserUid,
      receiverUid: receiverUid,
      status: FriendshipRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_friendshipRequestsCollection)
        .doc(requestId)
        .set(request.toMap());

    // Envoyer une notification
    await _notificationService.sendFriendRequestNotification(
      receiverUid: receiverUid,
      senderUid: _currentUserUid,
      requestId: requestId,
    );
  }

  /// Répondre à une demande d'amitié
  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    _requireAuth();

    final requestDoc = await _firestore
        .collection(_friendshipRequestsCollection)
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('Demande d\'amitié introuvable');
    }

    final request = FriendshipRequest.fromMap(requestDoc.data()!);

    if (request.receiverUid != _currentUserUid) {
      throw Exception('Non autorisé à répondre à cette demande');
    }

    if (request.status != FriendshipRequestStatus.pending) {
      throw Exception('Cette demande a déjà reçu une réponse');
    }

    // Mettre à jour le statut de la demande
    await _firestore
        .collection(_friendshipRequestsCollection)
        .doc(requestId)
        .update({
      'status': accept ? 'accepted' : 'declined',
      'respondedAt': Timestamp.now(),
    });

    if (accept) {
      // Ajouter mutuellement aux listes d'amis
      await _addMutualFriends(request.senderUid, request.receiverUid);

      // Envoyer une notification d'acceptation
      await _notificationService.sendFriendRequestAcceptedNotification(
        recipientUid: request.senderUid,
        senderUid: _currentUserUid,
      );
    }
  }

  /// Ajouter mutuellement les utilisateurs à leurs listes d'amis
  Future<void> _addMutualFriends(String uid1, String uid2) async {
    final batch = _firestore.batch();

    // Ajouter uid2 à la liste d'amis de uid1
    final user1Ref = _firestore.collection(AppConstants.usersCollection).doc(uid1);
    batch.update(user1Ref, {
      'friends': FieldValue.arrayUnion([uid2])
    });

    // Ajouter uid1 à la liste d'amis de uid2
    final user2Ref = _firestore.collection(AppConstants.usersCollection).doc(uid2);
    batch.update(user2Ref, {
      'friends': FieldValue.arrayUnion([uid1])
    });

    await batch.commit();
  }

  /// Retirer un ami
  Future<void> removeFriend(String friendUid) async {
    _requireAuth();

    final batch = _firestore.batch();

    // Retirer friendUid de la liste d'amis de l'utilisateur actuel
    final currentUserRef = _firestore.collection(AppConstants.usersCollection).doc(_currentUserUid);
    batch.update(currentUserRef, {
      'friends': FieldValue.arrayRemove([friendUid])
    });

    // Retirer l'utilisateur actuel de la liste d'amis de friendUid
    final friendRef = _firestore.collection(AppConstants.usersCollection).doc(friendUid);
    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([_currentUserUid])
    });

    await batch.commit();
  }

  /// Stream des demandes d'amitié reçues
  Stream<List<FriendshipRequest>> getReceivedFriendRequests() {
    _requireAuth();
    
    return _firestore
        .collection(_friendshipRequestsCollection)
        .where('receiverUid', isEqualTo: _currentUserUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendshipRequest.fromMap(doc.data()))
            .toList());
  }

  /// Stream des demandes d'amitié envoyées
  Stream<List<FriendshipRequest>> getSentFriendRequests() {
    _requireAuth();
    
    return _firestore
        .collection(_friendshipRequestsCollection)
        .where('senderUid', isEqualTo: _currentUserUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendshipRequest.fromMap(doc.data()))
            .toList());
  }

  /// Rechercher des utilisateurs par email
  Future<List<AppUser>> searchUsersByEmail(String email) async {
    _requireAuth();

    if (email.trim().isEmpty) {
      return [];
    }

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isGreaterThanOrEqualTo: email.toLowerCase())
        .where('email', isLessThanOrEqualTo: email.toLowerCase() + '\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data()))
        .where((user) => user.id != _currentUserUid)
        .toList();
  }

  /// Obtenir les détails des demandes avec les informations utilisateur
  Future<List<Map<String, dynamic>>> getDetailedReceivedRequests() async {
    _requireAuth();

    final requestsSnapshot = await _firestore
        .collection(_friendshipRequestsCollection)
        .where('receiverUid', isEqualTo: _currentUserUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    List<Map<String, dynamic>> detailedRequests = [];

    for (var doc in requestsSnapshot.docs) {
      final request = FriendshipRequest.fromMap(doc.data());
      
      // Récupérer les informations de l'expéditeur
      final senderDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(request.senderUid)
          .get();

      if (senderDoc.exists) {
        final sender = AppUser.fromMap(senderDoc.data()!);
        detailedRequests.add({
          'request': request,
          'sender': sender,
        });
      }
    }

    return detailedRequests;
  }

  /// Vérifier le statut d'amitié entre deux utilisateurs
  Future<String> getFriendshipStatus(String otherUid) async {
    _requireAuth();

    // Vérifier si déjà amis
    final currentUserDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_currentUserUid)
        .get();

    if (currentUserDoc.exists) {
      final userData = currentUserDoc.data()!;
      final friends = List<String>.from(userData['friends'] ?? []);
      if (friends.contains(otherUid)) {
        return 'friends';
      }
    }

    // Vérifier s'il y a une demande en cours
    final sentRequestSnapshot = await _firestore
        .collection(_friendshipRequestsCollection)
        .where('senderUid', isEqualTo: _currentUserUid)
        .where('receiverUid', isEqualTo: otherUid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (sentRequestSnapshot.docs.isNotEmpty) {
      return 'request_sent';
    }

    final receivedRequestSnapshot = await _firestore
        .collection(_friendshipRequestsCollection)
        .where('senderUid', isEqualTo: otherUid)
        .where('receiverUid', isEqualTo: _currentUserUid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (receivedRequestSnapshot.docs.isNotEmpty) {
      return 'request_received';
    }

    return 'none';
  }
}