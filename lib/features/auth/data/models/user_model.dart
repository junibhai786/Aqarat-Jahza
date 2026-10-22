import 'package:aqarat_app/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.role,
    required super.status,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    fullName: json['full_name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    status: json['status']?.toString() ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'role': role,
    'status': status,
  };
}
