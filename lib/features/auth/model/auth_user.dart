/// The signed-in DummyJSON user (from `POST /auth/login` or `GET /auth/me`).
class AuthUser {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String image;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.image,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as num).toInt(),
    username: (json['username'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    firstName: (json['firstName'] ?? '').toString(),
    lastName: (json['lastName'] ?? '').toString(),
    image: (json['image'] ?? '').toString(),
  );
}
