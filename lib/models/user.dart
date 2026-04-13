class User {
  final int id;
  final String username;
  final String email;

  User({required this.id, required this.username, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['user_id'],
        username: json['username'],
        email: json['email'] ?? '',
      );
}