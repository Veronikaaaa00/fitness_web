import 'role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final Role role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      fullName: '${json['name'] ?? json['fullName'] ?? ''}',
      role: Role.fromApi('${json['role'] ?? 'member'}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': fullName,
        'role': role.apiValue,
      };
}
