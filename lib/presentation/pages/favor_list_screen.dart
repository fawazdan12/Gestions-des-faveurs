import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/auth_service.dart';
import 'package:gestion_favor/core/services/firebase_service.dart';
import 'package:gestion_favor/data/models/favor.dart' hide FavorStatus;
import 'package:gestion_favor/presentation/pages/widgets/favor_card.dart';
import 'package:gestion_favor/presentation/pages/widgets/user_drawer.dart';
import 'request_favor_screen.dart';

class FavorListScreen extends StatefulWidget {
  @override
  _FavorListScreenState createState() => _FavorListScreenState();
}

class _FavorListScreenState extends State<FavorListScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  String _currentFilter = FavorStatus.pending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _authService.currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Mes Faveurs'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0: _currentFilter = FavorStatus.pending; break;
                case 1: _currentFilter = FavorStatus.accepted; break;
                case 2: _currentFilter = FavorStatus.completed; break;
                case 3: _currentFilter = FavorStatus.refused; break;
              }
            });
          },
          tabs: [
            Tab(text: 'En attente', icon: Icon(Icons.schedule)),
            Tab(text: 'Acceptées', icon: Icon(Icons.thumb_up)),
            Tab(text: 'Terminées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Refusées', icon: Icon(Icons.thumb_down)),
          ],
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
      ),
      drawer: UserDrawer(user: currentUser),
      body: Column(
        children: [
          // Statistiques rapides
          _buildStatsCard(),
          
          // Liste des faveurs
          Expanded(child: _buildFavorsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestFavorScreen()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Nouvelle faveur'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(AppDimensions.paddingMedium),
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, int>>(
        future: _firebaseService.getFavorStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'En attente',
                stats[FavorStatus.pending] ?? 0,
                AppColors.pendingColor,
                Icons.schedule,
              ),
              _buildStatItem(
                'Acceptées',
                stats[FavorStatus.accepted] ?? 0,
                AppColors.acceptedColor,
                Icons.thumb_up,
              ),
              _buildStatItem(
                'Terminées',
                stats[FavorStatus.completed] ?? 0,
                AppColors.completedColor,
                Icons.check_circle,
              ),
              _buildStatItem(
                'Refusées',
                stats[FavorStatus.refused] ?? 0,
                AppColors.refusedColor,
                Icons.thumb_down,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Icon(icon, color: color, size: AppDimensions.iconSize),
        ),
        SizedBox(height: AppDimensions.paddingXSmall),
        Text(
          count.toString(),
          style: AppTextStyles.headline3.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFavorsList() {
    return StreamBuilder<List<Favor>>(
      stream: _firebaseService.getFavorsByStatus(_currentFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppDimensions.spaceMedium),
                Text(AppStrings.loading, style: AppTextStyles.bodyText2),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  SizedBox(height: AppDimensions.spaceMedium),
                  Text(
                    'Une erreur est survenue',
                    style: AppTextStyles.headline3,
                  ),
                  SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.spaceLarge),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Force refresh
                    },
                    child: Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final favors = snapshot.data ?? [];

        if (favors.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyStateIcon(_currentFilter),
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: AppDimensions.spaceMedium),
                  Text(
                    _getEmptyStateMessage(_currentFilter),
                    style: AppTextStyles.headline3.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    _getEmptyStateSubMessage(_currentFilter),
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Force refresh
          },
          child: ListView.builder(
            padding: EdgeInsets.all(AppDimensions.paddingSmall),
            itemCount: favors.length,
            itemBuilder: (context, index) {
              return FavorCard(
                favor: favors[index],
                onAccept: () => _handleFavorAction(
                  () => _firebaseService.acceptFavor(favors[index].id),
                  AppStrings.favorAccepted,
                ),
                onRefuse: () => _handleFavorAction(
                  () => _firebaseService.refuseFavor(favors[index].id),
                  AppStrings.favorRefused,
                ),
                onComplete: () => _handleFavorAction(
                  () => _firebaseService.completeFavor(favors[index].id),
                  AppStrings.favorCompleted,
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getEmptyStateIcon(String status) {
    switch (status) {
      case FavorStatus.pending: return Icons.schedule;
      case FavorStatus.accepted: return Icons.thumb_up;
      case FavorStatus.completed: return Icons.check_circle;
      case FavorStatus.refused: return Icons.thumb_down;
      default: return Icons.favorite_border;
    }
  }

  String _getEmptyStateMessage(String status) {
    switch (status) {
      case FavorStatus.pending: return 'Aucune faveur en attente';
      case FavorStatus.accepted: return 'Aucune faveur acceptée';
      case FavorStatus.completed: return 'Aucune faveur terminée';
      case FavorStatus.refused: return 'Aucune faveur refusée';
      default: return AppStrings.noFavors;
    }
  }

  String _getEmptyStateSubMessage(String status) {
    switch (status) {
      case FavorStatus.pending: 
        return 'Vos amis peuvent vous demander des faveurs.\nElles apparaîtront ici.';
      case FavorStatus.accepted: 
        return 'Les faveurs que vous acceptez\napparaîtront dans cette section.';
      case FavorStatus.completed: 
        return 'Bravo ! Vous n\'avez terminé aucune faveur\npour le moment.';
      case FavorStatus.refused: 
        return 'Les faveurs que vous refusez\napparaîtront ici.';
      default: 
        return 'Commencez par demander une faveur à un ami !';
    }
  }

  Future<void> _handleFavorAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
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
              // La navigation sera gérée automatiquement par AuthWrapper
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
