import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_favor/core/constants/constants.dart' hide FavorStatus;
import 'package:gestion_favor/data/models/favor.dart';
import 'package:gestion_favor/data/models/user.dart';
import 'auth_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

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

  /// Créer une nouvelle faveur
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
      status: FavorStatus.pending, // ✅ Utilisation de l'enum
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.favorsCollection)
        .doc(favorId)
        .set(favor.toMap()); // toMap() gère la conversion enum -> string
  }

  /// Accepter une faveur
  Future<void> acceptFavor(String favorId) async {
    _requireAuth();
    await _updateFavorStatus(favorId, FavorStatus.accepted, {
      AppConstants.acceptedAtField: Timestamp.now(),
    });
  }

  /// Refuser une faveur
  Future<void> refuseFavor(String favorId) async {
    _requireAuth();
    await _updateFavorStatus(favorId, FavorStatus.refused);
  }

  /// Marquer une faveur comme terminée
  Future<void> completeFavor(String favorId) async {
    _requireAuth();
    await _updateFavorStatus(favorId, FavorStatus.completed, {
      AppConstants.completedAtField: Timestamp.now(),
    });
  }

  /// Mettre à jour le statut d'une faveur
  Future<void> _updateFavorStatus(
    String favorId, 
    FavorStatus newStatus, // ✅ Paramètre en enum
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
      AppConstants.statusField: _statusToString(newStatus), // ✅ Conversion enum -> string
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

  /// Obtenir la liste des amis
  Future<List<AppUser>> getFriends() async {
    _requireAuth();
    
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .limit(AppConfig.maxFriendsToShow)
        .get();
    
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data()))
        .where((user) => user.id != _currentUserUid)
        .toList();
  }

  /// Obtenir les statistiques des faveurs
  Future<Map<String, int>> getFavorStats() async {
    _requireAuth();

    final results = await Future.wait([
      _firestore
          .collection(AppConstants.favorsCollection)
          .where(AppConstants.targetUidField, isEqualTo: _currentUserUid)
          .where(AppConstants.statusField, isEqualTo: _statusToString(FavorStatus.pending)) // ✅ Conversion
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