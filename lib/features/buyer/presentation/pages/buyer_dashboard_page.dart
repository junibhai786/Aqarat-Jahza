import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/favorites_page.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/bookings_page.dart';
import 'package:flutter/material.dart';

class BuyerDashboardPage extends StatefulWidget {
  const BuyerDashboardPage({super.key, required this.repository, required this.name});

  final BuyerRepository repository;
  final String name;

  @override
  State<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends State<BuyerDashboardPage> {
  late Future<_BuyerCounts> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _load();
  }

  Future<_BuyerCounts> _load() async {
    final data = await Future.wait([
      widget.repository.favorites(),
      widget.repository.bookings(),
      widget.repository.leads(),
      widget.repository.notifications(),
    ]);
    return _BuyerCounts(
      favorites: data[0].length,
      savedProperties: data[0],
      bookings: data[1].length,
      leads: data[2].length,
      notifications: data[3].length,
      upcoming: data[1],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('dashboard'))),
        body: FutureBuilder<_BuyerCounts>(
          future: _counts,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            final counts = snapshot.data ?? const _BuyerCounts();
            return RefreshIndicator(
              onRefresh: () async => setState(() => _counts = _load()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(context.tr('yourPersonalSpace'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('Hello ${widget.name}, ${context.tr('haveNiceDay')}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(context.tr('dashboardSubtitle'), style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _stat(Icons.favorite_border, context.tr('favourites'), counts.favorites, const Color(0xFF007A61)),
                      _stat(Icons.calendar_month_outlined, context.tr('viewingRequests'), counts.bookings, const Color(0xFFB0801E)),
                      _stat(Icons.chat_bubble_outline, context.tr('requests'), counts.leads, const Color(0xFF657DB5)),
                      _stat(Icons.notifications_none, context.tr('unreadNotifications'), counts.notifications, const Color(0xFF16816A)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _upcoming(counts.upcoming),
                  const SizedBox(height: 16),
                  _favouritesCard(counts.savedProperties),
                ],
              ),
            );
          },
        ),
      );

  Widget _stat(IconData icon, String label, int value, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(alignment: AlignmentDirectional.centerEnd, child: Icon(icon, color: color)),
          const Spacer(),
          Text('$value', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      );

  Widget _upcoming(List<Map<String, dynamic>> bookings) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _card(),
        child: Column(children: [
          Row(children: [Expanded(child: Text(context.tr('upcomingViewings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))), TextButton.icon(onPressed: _openBookings, icon: const Icon(Icons.arrow_forward, size: 17), label: Text(context.tr('viewings')))]),
          Text(context.tr('followAppointments'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 18),
          if (bookings.isEmpty) ...[
            const Icon(Icons.calendar_month_outlined, size: 42, color: Color(0xFF91AE9D)),
            const SizedBox(height: 12),
            Text(context.tr('firstViewing'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(context.tr('viewingEmpty'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: Text(context.tr('browseProperties'))),
          ] else ...[
            ...bookings.take(2).map((booking) {
              final property = booking['property'];
              final title = property is Map ? property['title']?.toString() : booking['property_title']?.toString();
              final status = booking['status']?.toString() ?? '-';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5F0), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF007A61))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title ?? context.tr('propertyDetails'), style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(booking['requested_for']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: Colors.black54))])),
                  Chip(label: Text(status)),
                ]),
              );
            }),
          ],
        ]),
      );

  Widget _favouritesCard(List<Map<String, dynamic>> favorites) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _card(),
        child: Column(children: [
          Row(children: [Expanded(child: Text(context.tr('savedProperties'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))), TextButton(onPressed: _openFavorites, child: Text(context.tr('viewFavourites')))]),
          if (favorites.isEmpty) ...[
            const Icon(Icons.favorite_border, size: 38, color: Color(0xFF91AE9D)),
            const SizedBox(height: 8),
            Text(context.tr('keepChoices'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ] else ...[
            const SizedBox(height: 8),
            ...favorites.take(2).map(_savedProperty),
          ],
        ]),
      );

  Widget _savedProperty(Map<String, dynamic> favorite) {
    final property = favorite['property'];
    final item = property is Map ? property : favorite;
    final title = item['title']?.toString() ?? context.tr('propertyDetails');
    final region = item['region']?.toString() ?? '';
    final price = item['price']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Color(0xFFE8F5F0), child: Icon(Icons.home_work_outlined, color: Color(0xFF007A61))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)), if (region.isNotEmpty) Text(region, style: const TextStyle(fontSize: 12, color: Colors.black54))])),
        if (price.isNotEmpty) Text('$price EGP', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FavoritesPage(repository: widget.repository)));
    if (mounted) setState(() => _counts = _load());
  }

  Future<void> _openBookings() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BookingsPage(repository: widget.repository)));
    if (mounted) setState(() => _counts = _load());
  }

  BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4)));
}

class _BuyerCounts {
  const _BuyerCounts({this.favorites = 0, this.bookings = 0, this.leads = 0, this.notifications = 0, this.upcoming = const <Map<String, dynamic>>[], this.savedProperties = const <Map<String, dynamic>>[]});

  final int favorites;
  final int bookings;
  final int leads;
  final int notifications;
  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> savedProperties;
}
