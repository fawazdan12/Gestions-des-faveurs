
import 'package:flutter/material.dart';

/// ========================================
/// CONSTANTES DE L'APPLICATION KOFFAVOR
/// ========================================

class AppConstants {
  // Empêcher l'instanciation de cette classe
  AppConstants._();

  /// ========================================
  /// INFORMATIONS DE L'APPLICATION
  /// ========================================
  
  static const String appName = 'KofFavor';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Application de gestion des faveurs entre amis';

  /// ========================================
  /// CONSTANTES FIREBASE
  /// ========================================
  
  // Collections Firestore
  static const String usersCollection = 'users';
  static const String favorsCollection = 'favors';
  
  // Champs des documents
  static const String idField = 'id';
  static const String emailField = 'email';
  static const String displayNameField = 'displayName';
  static const String friendsField = 'friends';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  
  // Champs spécifiques aux faveurs
  static const String favorIdField = 'id';
  static const String titleField = 'title';
  static const String descriptionField = 'description';
  static const String requesterUidField = 'requesterUid';
  static const String targetUidField = 'targetUid';
  static const String statusField = 'status';
  static const String acceptedAtField = 'acceptedAt';
  static const String completedAtField = 'completedAt';
}

/// ========================================
/// STATUTS DES FAVEURS
/// ========================================

class FavorStatus {
  FavorStatus._();
  
  // Statuts possibles
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String refused = 'refused';
  static const String completed = 'completed';
  
  // Liste de tous les statuts valides
  static const List<String> allStatuses = [
    pending,
    accepted,
    refused,
    completed,
  ];
  
  // Statuts actifs (qui nécessitent une action)
  static const List<String> activeStatuses = [
    pending,
    accepted,
  ];
  
  // Statuts finaux (terminés)
  static const List<String> finalStatuses = [
    refused,
    completed,
  ];
  
  /// Vérifier si un statut est valide
  static bool isValid(String status) {
    return allStatuses.contains(status);
  }
  
  /// Vérifier si un statut est actif
  static bool isActive(String status) {
    return activeStatuses.contains(status);
  }
  
  /// Vérifier si un statut est final
  static bool isFinal(String status) {
    return finalStatuses.contains(status);
  }
  
  /// Obtenir le libellé d'affichage d'un statut
  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'En attente';
      case accepted:
        return 'Acceptée';
      case refused:
        return 'Refusée';
      case completed:
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }
  
  /// Obtenir la couleur associée à un statut
  static Color getStatusColor(String status) {
    switch (status) {
      case pending:
        return AppColors.pendingColor;
      case accepted:
        return AppColors.acceptedColor;
      case refused:
        return AppColors.refusedColor;
      case completed:
        return AppColors.completedColor;
      default:
        return AppColors.unknownColor;
    }
  }
  
  /// Obtenir l'icône associée à un statut
  static IconData getStatusIcon(String status) {
    switch (status) {
      case pending:
        return Icons.schedule;
      case accepted:
        return Icons.thumb_up;
      case refused:
        return Icons.thumb_down;
      case completed:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

/// ========================================
/// COULEURS DE L'APPLICATION
/// ========================================

class AppColors {
  AppColors._();
  
  // Couleurs principales
  static const Color primaryColor = Color(0xFF2196F3); // Bleu
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFFBBDEFB);
  
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal
  static const Color secondaryDarkColor = Color(0xFF018786);
  
  // Couleurs des statuts
  static const Color pendingColor = Color(0xFFFF9800); // Orange
  static const Color acceptedColor = Color(0xFF4CAF50); // Vert
  static const Color refusedColor = Color(0xFFF44336); // Rouge
  static const Color completedColor = Color(0xFF9C27B0); // Violet
  static const Color unknownColor = Color(0xFF9E9E9E); // Gris
  
  // Couleurs de l'interface
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFBDBDBD);
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
}

/// ========================================
/// STYLES DE TEXTE
/// ========================================

class AppTextStyles {
  AppTextStyles._();
  
  // Titres
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryColor,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryColor,
  );
  
  // Corps de texte
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimaryColor,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondaryColor,
  );
  
  // Texte de caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondaryColor,
  );
  
  // Styles spéciaux
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    color: AppColors.errorColor,
  );
}

/// ========================================
/// DIMENSIONS ET ESPACEMENTS
/// ========================================

class AppDimensions {
  AppDimensions._();
  
  // Marges et paddings
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Rayons des bordures
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  
  // Tailles des éléments
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeLarge = 32.0;
  
  // Espacements
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  
  // Tailles des cartes
  static const double cardElevation = 2.0;
  static const double cardMinHeight = 100.0;
}

/// ========================================
/// MESSAGES ET TEXTES
/// ========================================

class AppStrings {
  AppStrings._();
  
  // Messages généraux
  static const String loading = 'Chargement...';
  static const String error = 'Une erreur est survenue';
  static const String noData = 'Aucune donnée disponible';
  static const String retry = 'Réessayer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';
  
  // Messages spécifiques aux faveurs
  static const String noFavors = 'Aucune faveur pour le moment';
  static const String favorCreated = 'Faveur envoyée avec succès!';
  static const String favorAccepted = 'Faveur acceptée!';
  static const String favorRefused = 'Faveur refusée!';
  static const String favorCompleted = 'Faveur terminée!';
  
  // Erreurs
  static const String userNotConnected = 'Utilisateur non connecté';
  static const String invalidTarget = 'Destinataire invalide';
  static const String cannotRequestSelf = 'Impossible de se demander une faveur à soi-même';
  static const String invalidStatus = 'Statut invalide';
  
  // Labels des formulaires
  static const String titleLabel = 'Titre de la faveur';
  static const String titleHint = 'Entrez le titre de la faveur';
  static const String descriptionLabel = 'Description';
  static const String descriptionHint = 'Décrivez la faveur en détail';
  static const String friendLabel = 'Choisir un ami';
  static const String friendHint = 'Sélectionnez un ami';
  
  // Messages de validation
  static const String titleRequired = 'Veuillez entrer un titre';
  static const String descriptionRequired = 'Veuillez entrer une description';
  static const String friendRequired = 'Veuillez sélectionner un ami';
  
  // Actions
  static const String accept = 'Accepter';
  static const String refuse = 'Refuser';
  static const String complete = 'Terminer';
  static const String requestFavor = 'Demander une faveur';
  static const String sendRequest = 'Envoyer la demande';
}

/// ========================================
/// RÈGLES DE VALIDATION
/// ========================================

class AppValidation {
  AppValidation._();
  
  // Longueurs
  static const int minTitleLength = 3;
  static const int maxTitleLength = 100;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 500;
  static const int uidLength = 28;
  
  // Expressions régulières
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp uidRegex = RegExp(r'^[a-zA-Z0-9]+$');
  
  /// Valider un email
  static bool isValidEmail(String email) {
    return emailRegex.hasMatch(email);
  }
  
  /// Valider un UID Firebase
  static bool isValidUid(String uid) {
    return uid.length == uidLength && uidRegex.hasMatch(uid);
  }
  
  /// Valider un titre de faveur
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return AppStrings.titleRequired;
    }
    if (title.trim().length < minTitleLength) {
      return 'Le titre doit contenir au moins $minTitleLength caractères';
    }
    if (title.trim().length > maxTitleLength) {
      return 'Le titre ne peut pas dépasser $maxTitleLength caractères';
    }
    return null;
  }
  
  /// Valider une description de faveur
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return AppStrings.descriptionRequired;
    }
    if (description.trim().length < minDescriptionLength) {
      return 'La description doit contenir au moins $minDescriptionLength caractères';
    }
    if (description.trim().length > maxDescriptionLength) {
      return 'La description ne peut pas dépasser $maxDescriptionLength caractères';
    }
    return null;
  }
}

/// ========================================
/// CONFIGURATION
/// ========================================

class AppConfig {
  AppConfig._();
  
  // Limites
  static const int maxFavorsPerPage = 20;
  static const int maxFriendsToShow = 100;
  static const int cacheExpiration = 300; // 5 minutes en secondes
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Environnement
  static const bool isDebugMode = true; // Mettre à false en production
  static const String apiVersion = 'v1';
}