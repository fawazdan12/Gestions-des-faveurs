import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_favor/core/constants/constants.dart' hide FavorStatus;
import 'package:gestion_favor/data/models/favor.dart';
import 'package:gestion_favor/data/models/user.dart';
import 'package:gestion_favor/core/services/notification_service.dart';
import 'auth_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  /// Vérifier si l'utilisateur est connecté, sinon lever une exception
  void _requireAuth() {
    if (!_authService.isLoggedIn) {
      throw Exception(AppStrings.userNotConnected);
    }
  }

  /// Obtenir l'UID de l'utilisateur connecté
  String get _currentUserUid {
    _requireAuth();
    return _authService.currentUser!.uid;
  }

  /// Convertir enum FavorStatus en String pour Firestore
  String _statusToString(FavorStatus status) {
    return status.toString().split('.').last;
  }

  /// Convertir String en enum FavorStatus
  FavorStatus _statusFromString(String status) {
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

  /// Vérifier si un statut string est valide
  bool _isValidStatus(String status) {
    return ['pending', 'accepted', 'refused', 'completed'].contains(status);
  }

  /// Stream des faveurs pour l'utilisateur connecté
  Stream<List<Favor>> getFavorsForUser() {
    if (!_authService.isLoggedIn) {
      return Stream.error(Exception(AppStrings.userNotConnected));
    }
    
    return _firestore
        .collection(AppConstants.favorsCollection)
        .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
        .orderBy(AppConstants.createdAtField, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Favor.fromMap(doc.data()))
            .toList());
  }

  /// Stream des faveurs par statut
  Stream<List<Favor>> getFavorsByStatus(String status) {
    if (!_authService.isLoggedIn) {
      return Stream.error(Exception(AppStrings.userNotConnected));
    }

    if (!_isValidStatus(status)) {
      return Stream.error(Exception(AppStrings.invalidStatus));
    }
    
    return _firestore
        .collection(AppConstants.favorsCollection)
        .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
        .where(AppConstants.statusField, isEqualTo: status)
        .orderBy(AppConstants.createdAtField, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Favor.fromMap(doc.data()))
            .toList());
  }

  /// Créer une nouvelle faveur avec notification
  Future<void> createFavor({
    required String title,
    required String description,
    required String targetUid,
  }) async {
    _requireAuth();

    // Validations
    final titleError = AppValidation.validateTitle(title);
    if (titleError != null) throw Exception(titleError);

    final descError = AppValidation.validateDescription(description);
    if (descError != null) throw Exception(descError);

    if (!AppValidation.isValidUid(targetUid)) {
      throw Exception(AppStrings.invalidTarget);
    }

    if (targetUid == _currentUserUid) {
      throw Exception(AppStrings.cannotRequestSelf);
    }

    // Vérifier que l'utilisateur cible existe
    final targetUser = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUid)
        .get();
    
    if (!targetUser.exists) {
      throw Exception('L\'utilisateur destinataire n\'existe pas');
    }

    final favorId = _firestore.collection(AppConstants.favorsCollection).doc().id;
    
    final favor = Favor(
      id: favorId,
      title: title.trim(),
      description: description.trim(),
      requesterUid: _currentUserUid,
      targetUid: targetUid,
      status: FavorStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .set(favor.toMap());

    // Envoyer une notification au destinataire
    await _notificationService.sendFavorRequestNotification(
      recipientUid: targetUid,
      senderUid: _currentUserUid,
      favorId: favorId,
      favorTitle: title,
    );
  }

  /// Accepter une faveur avec notification
  Future<void> acceptFavor(String favorId) async {
    _requireAuth();
    
    // Récupérer les détails de la faveur pour la notification
    final favorDoc = await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .get();
    
    if (favorDoc.exists) {
      final favorData = favorDoc.data()!;
      final favor = Favor.fromMap(favorData);
      
      await _updateFavorStatus(favorId, FavorStatus.accepted, {
        AppConstants.acceptedAtField: Timestamp.now(),
      });

      // Envoyer une notification au demandeur
      await _notificationService.sendFavorAcceptedNotification(
        recipientUid: favor.requesterUid,
        senderUid: _currentUserUid,
        favorId: favorId,
        favorTitle: favor.title,
      );
    }
  }

  /// Refuser une faveur avec notification
  Future<void> refuseFavor(String favorId) async {
    _requireAuth();
    
    // Récupérer les détails de la faveur pour la notification
    final favorDoc = await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .get();
    
    if (favorDoc.exists) {
      final favorData = favorDoc.data()!;
      final favor = Favor.fromMap(favorData);
      
      await _updateFavorStatus(favorId, FavorStatus.refused);

      // Envoyer une notification au demandeur
      await _notificationService.sendFavorRefusedNotification(
        recipientUid: favor.requesterUid,
        senderUid: _currentUserUid,
        favorId: favorId,
        favorTitle: favor.title,
      );
    }
  }

  /// Marquer une faveur comme terminée avec notification
  Future<void> completeFavor(String favorId) async {
    _requireAuth();
    
    // Récupérer les détails de la faveur pour la notification
    final favorDoc = await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .get();
    
    if (favorDoc.exists) {
      final favorData = favorDoc.data()!;
      final favor = Favor.fromMap(favorData);
      
      await _updateFavorStatus(favorId, FavorStatus.completed, {
        AppConstants.completedAtField: Timestamp.now(),
      });

      // Envoyer une notification au demandeur
      await _notificationService.sendFavorCompletedNotification(
        recipientUid: favor.requesterUid,
        senderUid: _currentUserUid,
        favorId: favorId,
        favorTitle: favor.title,
      );
    }
  }

  /// Mettre à jour le statut d'une faveur
  Future<void> _updateFavorStatus(
    String favorId, 
    FavorStatus newStatus,
    [Map<String, dynamic>? additionalFields]
  ) async {
    // Vérifier que la faveur existe et appartient à l'utilisateur
    final favorDoc = await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .get();

    if (!favorDoc.exists) {
      throw Exception('Cette faveur n\'existe pas');
    }

    final favorData = favorDoc.data()!;
    if (favorData[AppConstants.targetUidField] != _currentUserUid) {
      throw Exception('Vous n\'êtes pas autorisé à modifier cette faveur');
    }

    final updateData = <String, dynamic>{
      AppConstants.statusField: _statusToString(newStatus),
      AppConstants.updatedAtField: Timestamp.now(),
    };

    if (additionalFields != null) {
      updateData.addAll(additionalFields);
    }

    await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .update(updateData);
  }

  /// Obtenir la liste des amis réels (avec relation mutuelle)
  Future<List<AppUser>> getFriends() async {
    _requireAuth();
    
    // Récupérer l'utilisateur actuel pour obtenir sa liste d'amis
    final currentUserDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_currentUserUid)
        .get();
    
    if (!currentUserDoc.exists) {
      return [];
    }
    
    final currentUser = AppUser.fromMap(currentUserDoc.data()!);
    final friendIds = currentUser.friends;
    
    if (friendIds.isEmpty) {
      return [];
    }
    
    // Récupérer les détails des amis par batch
    List<AppUser> friends = [];
    
    // Firestore limite à 10 éléments pour whereIn, donc on traite par batch
    for (int i = 0; i < friendIds.length; i += 10) {
      final batch = friendIds.skip(i).take(10).toList();
      
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('id', whereIn: batch)
          .get();
      
      friends.addAll(
        snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList()
      );
    }
    
    return friends;
  }

  /// Obtenir les statistiques des faveurs
  Future<Map<String, int>> getFavorStats() async {
    _requireAuth();

    final results = await Future.wait([
      _firestore
          .collection(AppConstants.favorsCollection)
          .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
          .where(AppConstants.statusField, isEqualTo: _statusToString(FavorStatus.pending))
          .get(),
      _firestore
          .collection(AppConstants.favorsCollection)
          .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
          .where(AppConstants.statusField, isEqualTo: _statusToString(FavorStatus.accepted))
          .get(),
      _firestore
          .collection(AppConstants.favorsCollection)
          .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
          .where(AppConstants.statusField, isEqualTo: _statusToString(FavorStatus.completed))
          .get(),
      _firestore
          .collection(AppConstants.favorsCollection)
          .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
          .where(AppConstants.statusField, isEqualTo: _statusToString(FavorStatus.refused))
          .get(),
    ]);

    return {
      _statusToString(FavorStatus.pending): results[0].size,
      _statusToString(FavorStatus.accepted): results[1].size,
      _statusToString(FavorStatus.completed): results[2].size,
      _statusToString(FavorStatus.refused): results[3].size,
    };
  }
}