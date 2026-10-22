import 'package:aqarat_app/features/properties/domain/entities/property.dart';
enum PropertyStatus { initial, loading, success, failure }
class PropertyState {
  const PropertyState({this.status = PropertyStatus.initial, this.properties = const [], this.regions = const [], this.filters = const {}, this.page = 1, this.hasMore = false, this.error, this.selectedProperty, this.isDetailLoading = false, this.detailError});
  final PropertyStatus status; final List<Property> properties; final List<String> regions; final Map<String, dynamic> filters; final int page; final bool hasMore; final String? error; final Property? selectedProperty; final bool isDetailLoading; final String? detailError;
  PropertyState copyWith({PropertyStatus? status, List<Property>? properties, List<String>? regions, Map<String, dynamic>? filters, int? page, bool? hasMore, String? error, Property? selectedProperty, bool? isDetailLoading, String? detailError}) => PropertyState(status: status ?? this.status, properties: properties ?? this.properties, regions: regions ?? this.regions, filters: filters ?? this.filters, page: page ?? this.page, hasMore: hasMore ?? this.hasMore, error: error, selectedProperty: selectedProperty ?? this.selectedProperty, isDetailLoading: isDetailLoading ?? this.isDetailLoading, detailError: detailError);
}
