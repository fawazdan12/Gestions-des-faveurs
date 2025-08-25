import 'package:flutter/material.dart';
import 'package:gestion_favor/core/services/firebase_service.dart';
import 'package:gestion_favor/data/models/user.dart';

class RequestFavorScreen extends StatefulWidget {
  @override
  _RequestFavorScreenState createState() => _RequestFavorScreenState();
}

class _RequestFavorScreenState extends State<RequestFavorScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  AppUser? _selectedFriend;
  List<AppUser> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _firebaseService.getFriends();
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des amis: $e')),
      );
    }
  }

  Future<void> _submitFavor() async {
    if (!_formKey.currentState!.validate() || _selectedFriend == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.createFavor(
        title: _titleController.text,
        description: _descriptionController.text,
        targetUid: _selectedFriend!.id,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faveur envoyée avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demander une faveur'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AppUser>(
                value: _selectedFriend,
                decoration: InputDecoration(
                  labelText: 'Choisir un ami',
                  border: OutlineInputBorder(),
                ),
                items: _friends.map((friend) {
                  return DropdownMenuItem(
                    value: friend,
                    child: Text(friend.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedFriend = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un ami';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de la faveur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitFavor,
                child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Envoyer la demande'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}