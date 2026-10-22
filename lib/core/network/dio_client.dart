import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  DioClient(this._preferences)
      : dio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _preferences.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log('RESPONSE ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}\n${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          _log('ERROR ${error.response?.statusCode ?? 'NETWORK'} ${error.requestOptions.method} ${error.requestOptions.uri}\n${error.response?.data ?? error.message}');
          handler.next(error);
        },
      ),
    );
  }

  final SharedPreferences _preferences;
  final Dio dio;

  Future<Response<dynamic>> post(String path, {Object? data}) => _request(() => dio.post(path, data: data));
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) => _request(() => dio.get(path, queryParameters: queryParameters));
  Future<Response<dynamic>> patch(String path, {Object? data}) => _request(() => dio.patch(path, data: data));
  Future<Response<dynamic>> delete(String path, {Object? data}) => _request(() => dio.delete(path, data: data));

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() action) async {
    try { return await action(); } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw ApiException(message ?? 'Unable to reach the server. Please try again.', statusCode: error.response?.statusCode);
    }
  }

  void _logRequest(RequestOptions options) {
    final headers = Map<String, dynamic>.from(options.headers);
    if (headers['Authorization'] != null) headers['Authorization'] = 'Bearer ***';
    _log('REQUEST ${options.method} ${options.uri}\nHeaders: $headers\nBody: ${_safeData(options.data)}');
  }

  Object? _safeData(Object? data) {
    if (data is! Map) return data;
    final safeData = Map<Object?, Object?>.from(data);
    if (safeData.containsKey('password')) safeData['password'] = '***';
    if (safeData.containsKey('current_password')) safeData['current_password'] = '***';
    if (safeData.containsKey('new_password')) safeData['new_password'] = '***';
    return safeData;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[Aqarat API] $message');
  }
}
