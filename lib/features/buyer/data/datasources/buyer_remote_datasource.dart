import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/network/dio_client.dart';

class BuyerRemoteDataSource {
  const BuyerRemoteDataSource(this._client);
  final DioClient _client;

  List<Map<String, dynamic>> _list(dynamic data, String key) {
    final body = (data as Map).cast<String, dynamic>();
    if (body['success'] != true) {
      throw ApiException(body['error']?.toString() ?? 'Request failed.');
    }
    final items = body[key] ?? body['data'] ?? <dynamic>[];
    return (items as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Map<String, dynamic> _map(dynamic data, [String key = 'data']) {
    final body = (data as Map).cast<String, dynamic>();
    if (body['success'] != true) {
      throw ApiException(body['error']?.toString() ?? 'Request failed.');
    }
    final value = body[key] ?? body['data'] ?? body;
    return (value as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> favorites() async =>
      _list((await _client.get(ApiEndpoints.favorites)).data, 'favorites');
  Future<Map<String, dynamic>> toggleFavorite(int id) async =>
      _map((await _client.post(ApiEndpoints.favorites, data: {'property_id': id})).data);
  Future<List<Map<String, dynamic>>> bookings() async =>
      _list((await _client.get(ApiEndpoints.bookings)).data, 'bookings');
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async =>
      _map((await _client.post(ApiEndpoints.bookings, data: data)).data, 'booking');
  Future<Map<String, dynamic>> cancelBooking(int id) async =>
      _map((await _client.patch(ApiEndpoints.booking(id), data: {'status': 'cancelled'})).data, 'booking');
  Future<List<Map<String, dynamic>>> leads() async =>
      _list((await _client.get(ApiEndpoints.leads)).data, 'leads');
  Future<Map<String, dynamic>> createLead(Map<String, dynamic> data) async =>
      _map((await _client.post(ApiEndpoints.leads, data: data)).data, 'lead');
  Future<List<Map<String, dynamic>>> notifications() async =>
      _list((await _client.get(ApiEndpoints.notifications)).data, 'notifications');
  Future<void> markNotificationsRead() async => _client.patch(ApiEndpoints.notifications);
  Future<Map<String, dynamic>> account() async =>
      _map((await _client.get(ApiEndpoints.account)).data, 'user');
  Future<Map<String, dynamic>> updateAccount(Map<String, dynamic> data) async =>
      _map((await _client.patch(ApiEndpoints.account, data: data)).data, 'user');

  Future<void> deleteAccount(String currentPassword) async {
    final response = await _client.delete(
      ApiEndpoints.account,
      data: {'current_password': currentPassword},
    );
    final body = (response.data as Map).cast<String, dynamic>();
    if (body['success'] != true) {
      throw ApiException(body['error']?.toString() ?? 'Could not delete account.');
    }
  }
}
