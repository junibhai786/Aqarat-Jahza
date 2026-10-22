class ApiEndpoints {
  const ApiEndpoints._();

  //static const String baseUrl = 'http://192.168.18.66:3000/api/mobile';
  static const String baseUrl = 'https://aqaratjahza.com/api/mobile';

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Public
  static const String meta = '/meta';
  static const String properties = '/properties';
  static String property(int id) => '/properties/$id';
  static String propertyView(int id) => '/properties/$id/view';

  // Buyer
  static const String favorites = '/favorites';
  static const String bookings = '/bookings';
  static const String leads = '/leads';
  static const String notifications = '/notifications';
  static const String account = '/account';

  // Seller
  static const String dashboard = '/dashboard';
  static const String uploads = '/uploads';
  static String booking(int id) => '/bookings/$id';
  static String lead(int id) => '/leads/$id';
  static String propertyStatus(int id) => '/properties/$id/status';
  static String favorite(int propertyId) => '/favorites/$propertyId';
}
