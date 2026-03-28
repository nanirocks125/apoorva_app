class AppUser {
  final String id;
  final String name;
  final String role; // Admin or Staff
  final String status; // Active or Inactive
  final bool firstLoginDone;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.firstLoginDone,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      role: data['role'] ?? 'Staff',
      status: data['status'] ?? 'Active',
      firstLoginDone: data['first_login_done'] ?? false,
    );
  }
}
