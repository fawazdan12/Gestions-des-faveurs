
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/auth_service.dart';



class UserDrawer extends StatelessWidget {
  final User? user;
  final AuthService _authService = AuthService();

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
          
          ListTile(
            leading: Icon(Icons.favorite, color: AppColors.primaryColor),
            title: Text('Mes Faveurs'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          
          ListTile(
            leading: Icon(Icons.people, color: AppColors.primaryColor),
            title: Text('Mes Amis'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers la page des amis
            },
          ),
          
          ListTile(
            leading: Icon(Icons.history, color: AppColors.primaryColor),
            title: Text('Historique'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers l'historique
            },
          ),
          
          ListTile(
            leading: Icon(Icons.bar_chart, color: AppColors.primaryColor),
            title: Text('Statistiques'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers les statistiques
            },
          ),
          
          Divider(),
          
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey),
            title: Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers les paramètres
            },
          ),
          
          ListTile(
            leading: Icon(Icons.help, color: Colors.grey),
            title: Text('Aide'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Naviguer vers l'aide
            },
          ),
          
          Spacer(),
          
          Divider(),
          
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.errorColor),
            title: Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
          
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
}