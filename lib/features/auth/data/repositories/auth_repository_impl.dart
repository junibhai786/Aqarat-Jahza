import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/network/dio_client.dart';
import 'package:aqarat_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aqarat_app/features/auth/data/models/user_model.dart';
import 'package:aqarat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._preferences, this._client);
  final AuthRemoteDataSource _remote;
  final SharedPreferences _preferences;
  final DioClient _client;
  @override
  Future<AuthResult> login({required String phone, required String password}) async {
    final result = await _remote.login(phone: phone, password: password);
    return _save(result);
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
  }) async {
    final result = await _remote.register(
      fullName: fullName,
      phone: phone,
      password: password,
      role: role,
    );
    return _save(result);
  }
  Future<AuthResult> _save(AuthResult result) async {
    await _preferences.setString('access_token', result.accessToken);
    await _preferences.setString('user_name', result.user.fullName);
    await _preferences.setString('user_role', result.user.role);
    if (result.expiresAt != null) {
      await _preferences.setInt('token_expires_at', result.expiresAt!.millisecondsSinceEpoch);
    }
    final user = result.user;
    await _preferences.setString('current_user', jsonEncode(UserModel(id: user.id, fullName: user.fullName, phone: user.phone, role: user.role, status: user.status).toJson()));
    return result;
  }

  @override
  Future<UserModel?> getSavedUser() async {
    final token = _preferences.getString('access_token');
    final userJson = _preferences.getString('current_user');
    if (token == null || token.isEmpty || userJson == null) return null;
    final expiresAt = _preferences.getInt('token_expires_at');
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      await _preferences.clear();
      return null;
    }
    try {
      return UserModel.fromJson((jsonDecode(userJson) as Map).cast<String, dynamic>());
    } on FormatException {
      await _preferences.clear();
      return null;
    }
  }
  @override
  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } finally {
      await _preferences.clear();
    }
  }
}
