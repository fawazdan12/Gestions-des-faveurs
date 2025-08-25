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
          
          // Section principale - Navigation
          ListTile(
            leading: Icon(Icons.favorite, color: AppColors.primaryColor),
            title: Text('Mes Faveurs'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers l'écran principal des faveurs
            },
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
          
          // Notifications avec badge
          StreamBuilder<int>(
            stream: _notificationService.getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return ListTile(
                leading: Stack(
                  children: [
                    Icon(Icons.notifications, color: AppColors.primaryColor),
                    if (unreadCount > 0)
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
                ),
                title: Row(
                  children: [
                    Text('Notifications'),
                    if (unreadCount > 0) ...[
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
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsScreen()),
                  );
                },
              );
            },
          ),
          
          Divider(),
          
          // Section analytique
          ListTile(
            leading: Icon(Icons.history, color: AppColors.primaryColor),
            title: Text('Historique'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers l'historique complet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          ListTile(
            leading: Icon(Icons.bar_chart, color: AppColors.primaryColor),
            title: Text('Statistiques'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers les statistiques détaillées
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          
          Divider(),
          
          // Section paramètres
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
          
          Spacer(),
          
          Divider(),
          
          // Déconnexion
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.errorColor),
            title: Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
          
          // Version de l'app
          Padding(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

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
              await _authService.signOut();
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paramètres'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              subtitle: Text('Gérer les notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cleaning_services),
              title: Text('Nettoyer les données'),
              subtitle: Text('Supprimer les anciennes notifications'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _notificationService.cleanupOldNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nettoyage effectué'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors du nettoyage'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Mode sombre'),
              subtitle: Text('Activer/désactiver le thème sombre'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter le changement de thème
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
          ],
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
              _buildHelpItem(
                '1. Ajouter des amis',
                'Utilisez l\'onglet "Ajouter" dans la section Amis pour rechercher et ajouter vos amis par email.',
              ),
              _buildHelpItem(
                '2. Demander une faveur',
                'Appuyez sur le bouton "+" pour créer une nouvelle demande de faveur à un ami.',
              ),
              _buildHelpItem(
                '3. Gérer les faveurs',
                'Acceptez, refusez ou marquez comme terminées les faveurs dans les différents onglets.',
              ),
              _buildHelpItem(
                '4. Notifications',
                'Vous recevez des notifications en temps réel pour toutes les interactions avec vos faveurs et demandes d\'amitié.',
              ),
              _buildHelpItem(
                '5. Historique',
                'Consultez l\'historique de toutes vos faveurs passées dans la section dédiée.',
              ),
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

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: AppDimensions.paddingXSmall),
          Text(description, style: AppTextStyles.bodyText2),
        ],
      ),
    );
  }
}