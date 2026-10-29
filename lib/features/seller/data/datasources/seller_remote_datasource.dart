import 'dart:io';

import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class SellerRemoteDataSource {
  const SellerRemoteDataSource(this._client);

  final DioClient _client;

  Map<String, dynamic> _body(dynamic data) {
    if (data is! Map) throw const ApiException('Invalid response from the server.');
    final body = data.cast<String, dynamic>();
    if (body['success'] == false) {
      throw ApiException(body['error']?.toString() ?? body['message']?.toString() ?? 'Request failed.');
    }
    return body;
  }

  Map<String, dynamic> _map(dynamic data, [String key = 'data']) {
    final body = _body(data);
    final nested = body['data'];
    final value = body[key] ?? body['dashboard'] ?? body['result'] ?? (nested is Map ? nested[key] ?? nested['dashboard'] : null) ?? nested ?? body;
    if (value is! Map) throw const ApiException('Invalid response from the server.');
    return value.cast<String, dynamic>();
  }

  List<Map<String, dynamic>> _list(dynamic data, String key) {
    final body = _body(data);
    final nested = body['data'];
    final items = body[key] ??
        (nested is Map ? nested[key] ?? nested['items'] ?? nested['results'] : nested) ??
        body['items'] ??
        body['results'] ??
        const <dynamic>[];
    if (items is! List) throw const ApiException('Invalid list response from the server.');
    return items.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
  }

  Future<void> _success(Future<Response<dynamic>> response) async {
    _body((await response).data);
  }

  Future<Map<String, dynamic>> dashboard() async => _map((await _client.get(ApiEndpoints.dashboard)).data);
  // The mobile backend's public `/properties` route currently returns approved
  // listings from every seller. The dashboard response is seller-scoped and
  // includes the authenticated seller's owned properties, so use it here.
  Future<List<Map<String, dynamic>>> listings() async =>
      _list((await _client.get(ApiEndpoints.dashboard)).data, 'properties');
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async => _map((await _client.post(ApiEndpoints.properties, data: data)).data, 'property');
  Future<Map<String, dynamic>> updateListing(int id, Map<String, dynamic> data) async => _map((await _client.patch(ApiEndpoints.property(id), data: data)).data, 'property');
  Future<void> deleteListing(int id) => _success(_client.delete(ApiEndpoints.property(id)));
  Future<Map<String, dynamic>> setListingStatus(int id, String status) async => _map((await _client.patch(ApiEndpoints.propertyStatus(id), data: {'listing_status': status})).data, 'property');
  Future<List<Map<String, dynamic>>> bookings() async => _list((await _client.get(ApiEndpoints.bookings)).data, 'bookings');
  Future<Map<String, dynamic>> updateBooking(int id, String status) async => _map((await _client.patch(ApiEndpoints.booking(id), data: {'status': status})).data, 'booking');
  Future<List<Map<String, dynamic>>> leads() async => _list((await _client.get(ApiEndpoints.leads)).data, 'leads');
  Future<Map<String, dynamic>> updateLead(int id, String status) async => _map((await _client.patch(ApiEndpoints.lead(id), data: {'status': status})).data, 'lead');

  Future<List<String>> uploadImages(List<File> files) async {
    if (files.isEmpty || files.length > 8) throw const ApiException('Upload between 1 and 8 images.');
    final form = FormData();
    for (final file in files) {
      form.files.add(MapEntry('images', await MultipartFile.fromFile(file.path)));
    }
    final body = _body((await _client.post(ApiEndpoints.uploads, data: form)).data);
    final nested = body['data'];
    final images = body['images'] ?? (nested is Map ? nested['images'] : null) ?? const <dynamic>[];
    if (images is! List) throw const ApiException('Invalid upload response from the server.');
    return images.map((image) => image.toString()).toList();
  }

  Future<Map<String, dynamic>> account() async => _map((await _client.get(ApiEndpoints.account)).data, 'user');
  Future<Map<String, dynamic>> updateAccount(Map<String, dynamic> data) async => _map((await _client.patch(ApiEndpoints.account, data: data)).data, 'user');
  Future<List<Map<String, dynamic>>> notifications() async => _list((await _client.get(ApiEndpoints.notifications)).data, 'notifications');
  Future<void> markNotificationsRead() => _success(_client.patch(ApiEndpoints.notifications));
}
