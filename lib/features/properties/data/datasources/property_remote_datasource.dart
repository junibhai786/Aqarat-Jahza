import 'package:aqarat_app/core/constants/api_endpoints.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/network/dio_client.dart';
import 'package:aqarat_app/features/properties/data/models/property_model.dart';

class PropertyRemoteDataSource {
  const PropertyRemoteDataSource(this._client); final DioClient _client;
  Future<Map<String, dynamic>> getMeta() async { final response = await _client.get(ApiEndpoints.meta); return (response.data as Map).cast<String, dynamic>(); }
  Future<PropertyPage> getProperties({Map<String, dynamic>? filters, int page = 1}) async {
    final response = await _client.get(ApiEndpoints.properties, queryParameters: {...?filters, 'page': page});
    final body = (response.data as Map).cast<String, dynamic>();
    if (body['success'] != true) throw ApiException(body['error']?.toString() ?? 'Could not load properties.');
    final rawItems = body['properties'] ?? body['data'] ?? body['items'] ?? const [];
    final properties = (rawItems as List).whereType<Map>().map((item) => PropertyModel.fromJson(item.cast<String, dynamic>())).toList();
    final pagination = body['pagination'] is Map ? (body['pagination'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final currentPage = int.tryParse((pagination['current_page'] ?? pagination['page'] ?? page).toString()) ?? page;
    final lastPage = int.tryParse((pagination['last_page'] ?? pagination['total_pages'] ?? currentPage).toString()) ?? currentPage;
    return PropertyPage(properties: properties, currentPage: currentPage, hasMore: currentPage < lastPage);
  }
  Future<PropertyModel> getProperty(int id) async { final response = await _client.get(ApiEndpoints.property(id)); final body = (response.data as Map).cast<String, dynamic>(); final data = body['property'] ?? body['data']; return PropertyModel.fromJson((data as Map).cast<String, dynamic>()); }
  Future<void> recordView(int id) async => _client.post(ApiEndpoints.propertyView(id));
}
class PropertyPage { const PropertyPage({required this.properties, required this.currentPage, required this.hasMore}); final List<PropertyModel> properties; final int currentPage; final bool hasMore; }
