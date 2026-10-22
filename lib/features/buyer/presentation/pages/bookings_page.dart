import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:flutter/material.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key, required this.repository});
  final BuyerRepository repository;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late Future<List<Map<String, dynamic>>> _bookings;
  String _statusFilter = 'all';

  @override
  void initState() { super.initState(); _bookings = widget.repository.bookings(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.tr('viewings')),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.search, size: 18), label: Text(context.tr('discoverProperties'))),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _bookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final bookings = snapshot.data ?? const <Map<String, dynamic>>[];
            final filtered = _statusFilter == 'all' ? bookings : bookings.where((booking) => booking['status']?.toString() == _statusFilter).toList();
            if (bookings.isEmpty) return Center(child: Text(context.tr('noViewings')));
            return RefreshIndicator(
              onRefresh: () async => setState(() => _bookings = widget.repository.bookings()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(context.tr('yourPersonalSpace'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(context.tr('viewings'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(context.tr('allDetailsOnePlace'), style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(context.tr('appointmentsAndRequests'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        DropdownButton<String>(value: _statusFilter, underline: const SizedBox(), items: [DropdownMenuItem(value: 'all', child: Text(context.tr('allStatuses'))), ...bookings.map((booking) => booking['status']?.toString()).whereType<String>().where((status) => status.isNotEmpty).toSet().map((status) => DropdownMenuItem(value: status, child: Text(status)))], onChanged: (value) => setState(() => _statusFilter = value ?? 'all')),
                      ]),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(context.tr('noViewings')))) else ...filtered.map((booking) => _card(context, booking)),
                    ]),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _card(BuildContext context, Map<String, dynamic> booking) {
    final property = booking['property'];
    final propertyMap = property is Map ? property : const <String, dynamic>{};
    final title = propertyMap['title']?.toString() ?? booking['property_title']?.toString() ?? context.tr('propertyDetails');
    final requestedFor = booking['requested_for']?.toString() ?? '-';
    final status = booking['status']?.toString() ?? '-';
    final id = int.tryParse(booking['id']?.toString() ?? '');
    final message = booking['message']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE1E9E4))),
      child: Row(children: [
        Container(margin: const EdgeInsetsDirectional.only(end: 12), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFE8F5F0), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF007A61))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(requestedFor, style: const TextStyle(fontSize: 12, color: Colors.black54)), if (message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)))])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Chip(label: Text(status)), if (id != null && status != 'cancelled' && status != 'completed') TextButton(onPressed: () => _cancel(id), child: Text(context.tr('cancel')))],),
      ]),
    );
  }

  Future<void> _cancel(int bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('cancelViewing')),
        content: Text(context.tr('cancelViewingQuestion')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('cancelViewing'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.cancelBooking(bookingId);
      if (!mounted) return;
      setState(() => _bookings = widget.repository.bookings());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('viewingCancelled'))));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
