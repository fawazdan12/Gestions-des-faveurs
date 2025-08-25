class AppUser {
  final String id;
  final String email;
  final String displayName;
  final List<String> friends;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.friends,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      friends: List<String>.from(map['friends'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'friends': friends,
    };
  }
}