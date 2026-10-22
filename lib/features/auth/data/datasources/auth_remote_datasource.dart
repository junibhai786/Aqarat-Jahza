import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/network/dio_client.dart';
import 'package:aqarat_app/features/auth/data/models/user_model.dart';
import 'package:aqarat_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);
  final DioClient _client;

  Future<AuthResult> login({required String phone, required String password}) => _authenticate(ApiEndpoints.login, {'phone': phone, 'password': password});
  Future<AuthResult> register({required String fullName, required String phone, required String password, required String role}) => _authenticate(ApiEndpoints.register, {'full_name': fullName, 'phone': phone, 'password': password, 'role': role});

  Future<AuthResult> _authenticate(String path, Map<String, String> data) async {
    final response = await _client.post(path, data: data);
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) throw ApiException(body['error']?.toString() ?? 'Authentication failed.', statusCode: response.statusCode);
    final token = body['access_token']?.toString() ?? '';
    if (token.isEmpty) throw const ApiException('The server did not return an access token.');
    final expiresIn = int.tryParse(body['expires_in']?.toString() ?? '');
    return AuthResult(
      user: UserModel.fromJson((body['user'] as Map).cast<String, dynamic>()),
      accessToken: token,
      expiresAt: expiresIn == null ? null : DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }
}
