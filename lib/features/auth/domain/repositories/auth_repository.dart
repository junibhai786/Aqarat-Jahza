import 'package:aqarat_app/features/auth/domain/entities/user.dart';

class AuthResult {
  const AuthResult({required this.user, required this.accessToken, this.expiresAt});
  final User user;
  final String accessToken;
  final DateTime? expiresAt;
}

abstract class AuthRepository {
  Future<AuthResult> login({required String phone, required String password});
  Future<AuthResult> register({required String fullName, required String phone, required String password, required String role});
  Future<void> logout();
  Future<User?> getSavedUser();
}
