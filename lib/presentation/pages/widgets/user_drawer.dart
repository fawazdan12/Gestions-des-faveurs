import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/auth_service.dart';
import 'package:gestion_favor/core/services/notification_service.dart';
import 'package:gestion_favor/presentation/pages/friends_management_screen.dart';
import 'package:gestion_favor/presentation/pages/notifications_screen.dart';

class UserDrawer extends StatelessWidget {
  final User? user;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  UserDrawer({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
            ),
            accountName: Text(
              user?.displayName ?? 'Utilisateur',
              style: AppTextStyles.headline3.copyWith(color: Colors.white),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: AppTextStyles.bodyText2.copyWith(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: AppDimensions.iconSizeLarge,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          
          // Navigation items
          _buildNavigationSection(context),
          
          Divider(),
          
          // Analytics section
          _buildAnalyticsSection(context),
          
          Divider(),
          
          // Settings section
          _buildSettingsSection(context),
          
          Spacer(),
          
          Divider(),
          
          // Logout
          _buildLogoutSection(context),
          
          // Version
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.favorite, color: AppColors.primaryColor),
          title: Text('Mes Faveurs'),
          onTap: () => Navigator.pop(context),
        ),
        
        ListTile(
          leading: Icon(Icons.people, color: AppColors.primaryColor),
          title: Text('Mes Amis'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FriendsManagementScreen()),
            );
          },
        ),
        
        // Notifications optimisées avec StreamBuilder
        _buildNotificationTile(context),
      ],
    );
  }

  Widget _buildNotificationTile(BuildContext context) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadNotificationCount(),
      initialData: 0, // Valeur par défaut pour éviter les rebuilds
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return ListTile(
          leading: _buildNotificationIcon(unreadCount),
          title: _buildNotificationTitle(unreadCount),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationIcon(int unreadCount) {
    if (unreadCount == 0) {
      return Icon(Icons.notifications, color: AppColors.primaryColor);
    }
    
    return Stack(
      children: [
        Icon(Icons.notifications, color: AppColors.primaryColor),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.errorColor,
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTitle(int unreadCount) {
    if (unreadCount == 0) {
      return Text('Notifications');
    }
    
    return Row(
      children: [
        Text('Notifications'),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.errorColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$unreadCount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.history, color: AppColors.primaryColor),
          title: Text('Historique'),
          onTap: () => _navigateToHistoire(context),
        ),
        ListTile(
          leading: Icon(Icons.bar_chart, color: AppColors.primaryColor),
          title: Text('Statistiques'),
          onTap: () => _navigateToStatistics(context),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.settings, color: Colors.grey),
          title: Text('Paramètres'),
          onTap: () {
            Navigator.pop(context);
            _showSettingsDialog(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.help, color: Colors.grey),
          title: Text('Aide'),
          onTap: () {
            Navigator.pop(context);
            _showHelpDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout, color: AppColors.errorColor),
      title: Text('Déconnexion'),
      onTap: () {
        Navigator.pop(context);
        _showLogoutDialog(context);
      },
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      child: Text(
        '${AppConstants.appName} v${AppConstants.appVersion}',
        style: AppTextStyles.caption,
        textAlign: TextAlign.center,
      ),
    );
  }

  // Optimisation : Utilisation de async/await proper
  void _navigateToHistoire(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implémenter la navigation vers l'historique
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité à venir')),
    );
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implémenter la navigation vers les statistiques
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité à venir')),
    );
  }

  // Rest of the methods remain the same...
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Utilisation d'une méthode asynchrone optimisée
              await _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Affichage d'un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _authService.signOut();
      
      // Fermer l'indicateur de chargement
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context); // Fermer l'indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paramètres'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsItem(
                context,
                Icons.notifications,
                'Notifications',
                'Gérer les notifications',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsScreen()),
                ),
              ),
              _buildSettingsItem(
                context,
                Icons.cleaning_services,
                'Nettoyer les données',
                'Supprimer les anciennes notifications',
                () => _performCleanup(context),
              ),
              _buildSettingsItem(
                context,
                Icons.dark_mode,
                'Mode sombre',
                'Activer/désactiver le thème sombre',
                () => _showFeatureComingSoon(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _performCleanup(BuildContext context) async {
    try {
      await _notificationService.cleanupOldNotifications();
      _showSuccessMessage(context, 'Nettoyage effectué');
    } catch (e) {
      _showErrorMessage(context, 'Erreur lors du nettoyage');
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  void _showFeatureComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fonctionnalité à venir')),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment utiliser KofFavor',
                style: AppTextStyles.headline3,
              ),
              SizedBox(height: AppDimensions.spaceMedium),
              ..._buildHelpItems(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHelpItems() {
    final helpItems = [
      ('1. Ajouter des amis', 'Utilisez l\'onglet "Ajouter" dans la section Amis pour rechercher et ajouter vos amis par email.'),
      ('2. Demander une faveur', 'Appuyez sur le bouton "+" pour créer une nouvelle demande de faveur à un ami.'),
      ('3. Gérer les faveurs', 'Acceptez, refusez ou marquez comme terminées les faveurs dans les différents onglets.'),
      ('4. Notifications', 'Vous recevez des notifications en temps réel pour toutes les interactions.'),
      ('5. Historique', 'Consultez l\'historique de toutes vos faveurs passées.'),
    ];

    return helpItems.map((item) => _buildHelpItem(item.$1, item.$2)).toList();
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)
          ),
          SizedBox(height: AppDimensions.paddingXSmall),
          Text(description, style: AppTextStyles.bodyText2),
        ],
      ),
    );
  }
}