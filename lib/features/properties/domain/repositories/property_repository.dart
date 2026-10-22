import 'package:aqarat_app/features/properties/domain/entities/property.dart';
abstract class PropertyRepository { Future<List<String>> regions(); Future<PropertyResult> search({Map<String, dynamic>? filters, int page}); Future<Property> details(int id); Future<void> recordView(int id); }
class PropertyResult { const PropertyResult({required this.properties, required this.page, required this.hasMore}); final List<Property> properties; final int page; final bool hasMore; }
