import 'package:flutter/material.dart';
import 'package:gestion_favor/core/constants/constants.dart';
import 'package:gestion_favor/core/services/firebase_service.dart';
import 'package:gestion_favor/core/services/friendship_service.dart';
import 'package:gestion_favor/data/models/friendship_request.dart';
import 'package:gestion_favor/data/models/user.dart';

class FriendsManagementScreen extends StatefulWidget {
  @override
  _FriendsManagementScreenState createState() => _FriendsManagementScreenState();
}

class _FriendsManagementScreenState extends State<FriendsManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FriendshipService _friendshipService = FriendshipService();
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Mes Amis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Amis', icon: Icon(Icons.people)),
            Tab(text: 'Demandes reçues', icon: Icon(Icons.mail)),
            Tab(text: 'Ajouter', icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildFriendRequestsList(),
          _buildAddFriendTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return FutureBuilder<List<AppUser>>(
      future: _firebaseService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppColors.errorColor),
                SizedBox(height: AppDimensions.spaceMedium),
                Text('Erreur lors du chargement', style: AppTextStyles.headline3),
                Text(snapshot.error.toString(), style: AppTextStyles.bodyText2),
              ],
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: AppDimensions.spaceMedium),
                Text(
                  'Aucun ami pour le moment',
                  style: AppTextStyles.headline3.copyWith(color: Colors.grey),
                ),
                Text(
                  'Ajoutez des amis pour commencer\nà échanger des faveurs',
                  style: AppTextStyles.bodyText2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.all(AppDimensions.paddingSmall),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              return FriendCard(
                friend: friends[index],
                onRemove: () => _showRemoveFriendDialog(friends[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendRequestsList() {
    return StreamBuilder<List<FriendshipRequest>>(
      stream: _friendshipService.getReceivedFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppColors.errorColor),
                SizedBox(height: AppDimensions.spaceMedium),
                Text('Erreur', style: AppTextStyles.headline3),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: AppDimensions.spaceMedium),
                Text(
                  'Aucune demande d\'amitié',
                  style: AppTextStyles.headline3.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _friendshipService.getDetailedReceivedRequests(),
          builder: (context, detailSnapshot) {
            if (detailSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final detailedRequests = detailSnapshot.data ?? [];

            return ListView.builder(
              padding: EdgeInsets.all(AppDimensions.paddingSmall),
              itemCount: detailedRequests.length,
              itemBuilder: (context, index) {
                final data = detailedRequests[index];
                final request = data['request'] as FriendshipRequest;
                final sender = data['sender'] as AppUser;

                return FriendRequestCard(
                  request: request,
                  sender: sender,
                  onAccept: () => _respondToRequest(request.id, true),
                  onDecline: () => _respondToRequest(request.id, false),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAddFriendTab() {
    return AddFriendWidget(
      friendshipService: _friendshipService,
    );
  }

  Future<void> _respondToRequest(String requestId, bool accept) async {
    try {
      await _friendshipService.respondToFriendRequest(requestId, accept);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Demande acceptée!' : 'Demande refusée'),
          backgroundColor: accept ? AppColors.successColor : AppColors.warningColor,
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

  void _showRemoveFriendDialog(AppUser friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer cet ami'),
        content: Text('Êtes-vous sûr de vouloir retirer ${friend.displayName} de votre liste d\'amis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _friendshipService.removeFriend(friend.id);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${friend.displayName} a été retiré de vos amis'),
                    backgroundColor: AppColors.warningColor,
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: Text('Retirer'),
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

class FriendCard extends StatelessWidget {
  final AppUser friend;
  final VoidCallback onRemove;

  const FriendCard({
    Key? key,
    required this.friend,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : 'U',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(friend.displayName, style: AppTextStyles.headline3),
        subtitle: Text(friend.email, style: AppTextStyles.bodyText2),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: AppColors.errorColor),
                  SizedBox(width: 8),
                  Text('Retirer'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              onRemove();
            }
          },
        ),
      ),
    );
  }
}

class FriendRequestCard extends StatelessWidget {
  final FriendshipRequest request;
  final AppUser sender;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const FriendRequestCard({
    Key? key,
    required this.request,
    required this.sender,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    sender.displayName.isNotEmpty ? sender.displayName[0].toUpperCase() : 'U',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: AppDimensions.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sender.displayName, style: AppTextStyles.headline3),
                      Text(sender.email, style: AppTextStyles.bodyText2),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spaceMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDecline,
                  child: Text('Refuser', style: TextStyle(color: AppColors.errorColor)),
                ),
                SizedBox(width: AppDimensions.paddingSmall),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.successColor),
                  child: Text('Accepter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddFriendWidget extends StatefulWidget {
  final FriendshipService friendshipService;

  const AddFriendWidget({
    Key? key,
    required this.friendshipService,
  }) : super(key: key);

  @override
  _AddFriendWidgetState createState() => _AddFriendWidgetState();
}

class _AddFriendWidgetState extends State<AddFriendWidget> {
  final _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher par email',
              hintText: 'Entrez l\'email de votre ami',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _isSearching
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
            onChanged: _onSearchChanged,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: AppDimensions.spaceMedium),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: AppDimensions.spaceMedium),
            Text(
              'Aucun utilisateur trouvé',
              style: AppTextStyles.headline3.copyWith(color: Colors.grey),
            ),
            Text(
              'Vérifiez l\'email saisi',
              style: AppTextStyles.bodyText2,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: AppDimensions.spaceMedium),
            Text(
              'Rechercher des amis',
              style: AppTextStyles.headline3.copyWith(color: Colors.grey),
            ),
            Text(
              'Tapez l\'email d\'un ami\npour l\'ajouter à votre liste',
              style: AppTextStyles.bodyText2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return UserSearchCard(
          user: _searchResults[index],
          friendshipService: widget.friendshipService,
          onStatusChanged: () {
            // Rafraîchir la recherche pour mettre à jour le statut
            _performSearch(_searchController.text);
          },
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Debounce la recherche
    Future.delayed(Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String email) async {
    if (email.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.friendshipService.searchUsersByEmail(email);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class UserSearchCard extends StatefulWidget {
  final AppUser user;
  final FriendshipService friendshipService;
  final VoidCallback onStatusChanged;

  const UserSearchCard({
    Key? key,
    required this.user,
    required this.friendshipService,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  _UserSearchCardState createState() => _UserSearchCardState();
}

class _UserSearchCardState extends State<UserSearchCard> {
  String _friendshipStatus = 'none';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriendshipStatus();
  }

  Future<void> _loadFriendshipStatus() async {
    try {
      final status = await widget.friendshipService.getFriendshipStatus(widget.user.id);
      setState(() {
        _friendshipStatus = status;
      });
    } catch (e) {
      // Erreur silencieuse pour le statut
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            widget.user.displayName.isNotEmpty ? widget.user.displayName[0].toUpperCase() : 'U',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(widget.user.displayName, style: AppTextStyles.headline3),
        subtitle: Text(widget.user.email, style: AppTextStyles.bodyText2),
        trailing: _buildActionButton(),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return Container(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (_friendshipStatus) {
      case 'friends':
        return Icon(Icons.people, color: AppColors.successColor);
      case 'request_sent':
        return Text('Demande envoyée', style: TextStyle(color: AppColors.warningColor));
      case 'request_received':
        return Text('Demande reçue', style: TextStyle(color: AppColors.infoColor));
      case 'none':
      default:
        return ElevatedButton(
          onPressed: _sendFriendRequest,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
          child: Text('Ajouter'),
        );
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.friendshipService.sendFriendRequest(widget.user.id);
      setState(() {
        _friendshipStatus = 'request_sent';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande d\'amitié envoyée à ${widget.user.displayName}'),
          backgroundColor: AppColors.successColor,
        ),
      );

      widget.onStatusChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}