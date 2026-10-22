import 'dart:io';
import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class SellerRemoteDataSource {
  const SellerRemoteDataSource(this._client);
  final DioClient _client;
  Map<String, dynamic> _map(dynamic data, [String key = 'data']) { final b = (data as Map).cast<String, dynamic>(); if (b['success'] != true) throw ApiException(b['error']?.toString() ?? 'Request failed.'); return ((b[key] ?? b['data'] ?? b) as Map).cast<String, dynamic>(); }
  List<Map<String, dynamic>> _list(dynamic data, String key) { final b = (data as Map).cast<String, dynamic>(); if (b['success'] != true) throw ApiException(b['error']?.toString() ?? 'Request failed.'); final items = b[key] ?? b['data'] ?? <dynamic>[]; return (items as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(); }
  Future<Map<String, dynamic>> dashboard() async => _map((await _client.get(ApiEndpoints.dashboard)).data);
  Future<List<Map<String, dynamic>>> listings() async => _list((await _client.get(ApiEndpoints.properties)).data, 'properties');
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> d) async => _map((await _client.post(ApiEndpoints.properties, data: d)).data, 'property');
  Future<Map<String, dynamic>> updateListing(int id, Map<String, dynamic> d) async => _map((await _client.patch(ApiEndpoints.property(id), data: d)).data, 'property');
  Future<void> deleteListing(int id) async => _client.delete(ApiEndpoints.property(id));
  Future<Map<String, dynamic>> setListingStatus(int id, String s) async => _map((await _client.patch(ApiEndpoints.propertyStatus(id), data: {'listing_status': s})).data, 'property');
  Future<List<Map<String, dynamic>>> bookings() async => _list((await _client.get(ApiEndpoints.bookings)).data, 'bookings');
  Future<Map<String, dynamic>> updateBooking(int id, String s) async => _map((await _client.patch(ApiEndpoints.booking(id), data: {'status': s})).data, 'booking');
  Future<List<Map<String, dynamic>>> leads() async => _list((await _client.get(ApiEndpoints.leads)).data, 'leads');
  Future<Map<String, dynamic>> updateLead(int id, String s) async => _map((await _client.patch(ApiEndpoints.lead(id), data: {'status': s})).data, 'lead');
  Future<List<String>> uploadImages(List<File> files) async { if (files.isEmpty || files.length > 8) throw const ApiException('Upload between 1 and 8 images.'); final form = FormData(); for (final file in files) { form.files.add(MapEntry('images', await MultipartFile.fromFile(file.path))); } final body = ((await _client.post(ApiEndpoints.uploads, data: form)).data as Map).cast<String, dynamic>(); if (body['success'] != true) throw ApiException(body['error']?.toString() ?? 'Upload failed.'); return (body['images'] as List? ?? []).map((e) => e.toString()).toList(); }
  Future<Map<String, dynamic>> account() async => _map((await _client.get(ApiEndpoints.account)).data, 'user');
  Future<Map<String, dynamic>> updateAccount(Map<String, dynamic> d) async => _map((await _client.patch(ApiEndpoints.account, data: d)).data, 'user');
  Future<List<Map<String, dynamic>>> notifications() async => _list((await _client.get(ApiEndpoints.notifications)).data, 'notifications');
  Future<void> markNotificationsRead() async => _client.patch(ApiEndpoints.notifications);
}
