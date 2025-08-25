import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/notification_service.dart';
import 'package:gestion_favor/data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Tout marquer comme lu',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
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
                    'Erreur lors du chargement',
                    style: AppTextStyles.headline3,
                  ),
                  SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: AppDimensions.spaceMedium),
                  Text(
                    'Aucune notification',
                    style: AppTextStyles.headline3.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'Vous serez notifié des nouvelles faveurs\net demandes d\'amitié',
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppDimensions.paddingSmall),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return NotificationCard(
                notification: notifications[index],
                onTap: () => _handleNotificationTap(notifications[index]),
                onDismiss: () => _dismissNotification(notifications[index].id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toutes les notifications ont été marquées comme lues'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Marquer comme lue si non lue
    if (!notification.isRead) {
      await _notificationService.markNotificationAsRead(notification.id);
    }

    // Navigation en fonction du type de notification
    switch (notification.type) {
      case NotificationType.favorRequested:
      case NotificationType.favorAccepted:
      case NotificationType.favorRefused:
      case NotificationType.favorCompleted:
        // Retourner à l'écran principal des faveurs
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      
      case NotificationType.friendRequestReceived:
        // Naviguer vers l'écran des demandes d'amitié
        Navigator.pushNamed(context, '/friend-requests');
        break;
      
      case NotificationType.friendRequestAccepted:
        // Naviguer vers l'écran des amis
        Navigator.pushNamed(context, '/friends');
        break;
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppDimensions.paddingMedium),
        color: AppColors.errorColor,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: EdgeInsets.symmetric(
          vertical: AppDimensions.paddingXSmall,
          horizontal: AppDimensions.paddingSmall,
        ),
        color: notification.isRead ? AppColors.cardColor : AppColors.primaryLightColor.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimensions.paddingSmall),
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                    size: AppDimensions.iconSize,
                  ),
                ),
                SizedBox(width: AppDimensions.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.headline3.copyWith(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.paddingXSmall),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodyText2,
                      ),
                      SizedBox(height: AppDimensions.paddingXSmall),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(notification.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.favorRequested:
        return AppColors.pendingColor;
      case NotificationType.favorAccepted:
        return AppColors.acceptedColor;
      case NotificationType.favorRefused:
        return AppColors.refusedColor;
      case NotificationType.favorCompleted:
        return AppColors.completedColor;
      case NotificationType.friendRequestReceived:
        return AppColors.infoColor;
      case NotificationType.friendRequestAccepted:
        return AppColors.successColor;
      default:
        return AppColors.primaryColor;
    }
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.favorRequested:
        return Icons.help_outline;
      case NotificationType.favorAccepted:
        return Icons.thumb_up;
      case NotificationType.favorRefused:
        return Icons.thumb_down;
      case NotificationType.favorCompleted:
        return Icons.check_circle;
      case NotificationType.friendRequestReceived:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }
}