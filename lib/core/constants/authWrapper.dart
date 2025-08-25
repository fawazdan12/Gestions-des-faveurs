

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/main.dart';
import 'package:gestion_favor/presentation/pages/auth/login_screen.dart';
import 'package:gestion_favor/presentation/pages/favor_list_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En cours de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        // Erreur de connexion
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }
        
        // Utilisateur connecté -> Écran principal
        if (snapshot.hasData && snapshot.data != null) {
          return FavorListScreen();
        }
        
        // Utilisateur non connecté -> Écran de connexion
        return LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 80,
              color: AppColors.primaryColor,
            ),
            SizedBox(height: AppDimensions.spaceLarge),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            SizedBox(height: AppDimensions.spaceMedium),
            Text(
              AppStrings.loading,
              style: AppTextStyles.bodyText2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.errorColor,
              ),
              SizedBox(height: AppDimensions.spaceLarge),
              Text(
                'Erreur de connexion',
                style: AppTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spaceMedium),
              Text(
                error,
                style: AppTextStyles.bodyText2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spaceLarge),
              ElevatedButton(
                onPressed: () {
                  // Relancer l'application
                  main();
                },
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}