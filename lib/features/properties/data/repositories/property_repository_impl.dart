import 'package:aqarat_app/features/properties/data/datasources/property_remote_datasource.dart';
import 'package:aqarat_app/features/properties/domain/entities/property.dart';
import 'package:aqarat_app/features/properties/domain/repositories/property_repository.dart';
class PropertyRepositoryImpl implements PropertyRepository { const PropertyRepositoryImpl(this._remote); final PropertyRemoteDataSource _remote;
  @override Future<List<String>> regions() async { final meta = await _remote.getMeta(); return (meta['regions'] as List? ?? []).map((item) => item.toString()).toList(); }
  @override Future<PropertyResult> search({Map<String, dynamic>? filters, int page = 1}) async { final result = await _remote.getProperties(filters: filters, page: page); return PropertyResult(properties: result.properties, page: result.currentPage, hasMore: result.hasMore); }
  @override Future<Property> details(int id) => _remote.getProperty(id);
  @override Future<void> recordView(int id) => _remote.recordView(id);
}
