class User {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
  });
  final int? id;
  final String fullName;
  final String phone;
  final String role;
  final String status;
}
