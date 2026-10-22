sealed class PropertyEvent { const PropertyEvent(); }
class PropertiesRequested extends PropertyEvent { const PropertiesRequested({this.filters}); final Map<String, dynamic>? filters; }
class NextPropertiesRequested extends PropertyEvent { const NextPropertiesRequested(); }
class PropertyDetailsRequested extends PropertyEvent { const PropertyDetailsRequested(this.id); final int id; }
