import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/data/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de l'utilisateur connecté
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => currentUser != null;

  /// Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Mettre à jour les informations utilisateur dans Firestore
      await _updateUserInFirestore(result.user!);
      
      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Inscription avec email et mot de passe
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le nom d'affichage
      await result.user!.updateDisplayName(displayName);

      // Créer le profil utilisateur dans Firestore
      await _createUserProfile(result.user!, displayName);

      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Créer le profil utilisateur dans Firestore
  Future<void> _createUserProfile(User user, String displayName) async {
    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      friends: [], // Liste vide au début
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(appUser.toMap());
  }

  /// Mettre à jour les informations utilisateur dans Firestore
  Future<void> _updateUserInFirestore(User user) async {
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // Si le profil n'existe pas, le créer
      await _createUserProfile(user, user.displayName ?? 'Utilisateur');
    } else {
      // Mettre à jour la dernière connexion
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'lastLogin': Timestamp.now(),
        AppConstants.emailField: user.email,
        AppConstants.displayNameField: user.displayName,
      });
    }
  }

  /// Gérer les exceptions d'authentification
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cette adresse email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cette adresse email est déjà utilisée.';
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'invalid-email':
          return 'Adresse email invalide.';
        case 'user-disabled':
          return 'Ce compte utilisateur a été désactivé.';
        case 'too-many-requests':
          return 'Trop de tentatives. Veuillez réessayer plus tard.';
        default:
          return 'Erreur d\'authentification: ${e.message}';
      }
    }
    return 'Une erreur inattendue s\'est produite.';
  }

  /// Réinitialiser le mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Obtenir les informations complètes de l'utilisateur
  Future<AppUser?> getCurrentUserProfile() async {
    if (!isLoggedIn) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }
}