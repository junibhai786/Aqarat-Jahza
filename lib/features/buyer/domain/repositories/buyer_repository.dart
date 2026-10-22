abstract class BuyerRepository {
  Future<List<Map<String, dynamic>>> favorites();
  Future<Map<String, dynamic>> toggleFavorite(int propertyId);
  Future<List<Map<String, dynamic>>> bookings();
  Future<Map<String, dynamic>> createBooking({required int propertyId, required DateTime requestedFor, String? message});
  Future<Map<String, dynamic>> cancelBooking(int bookingId);
  Future<List<Map<String, dynamic>>> leads();
  Future<Map<String, dynamic>> createLead({required String purpose, required String region, required num budget, required int rooms, required String details, int? propertyId});
  Future<List<Map<String, dynamic>>> notifications();
  Future<void> markNotificationsRead();
  Future<Map<String, dynamic>> account();
  Future<Map<String, dynamic>> updateAccount({required String fullName, String? currentPassword, String? newPassword});
  Future<void> deleteAccount({required String currentPassword});
}
