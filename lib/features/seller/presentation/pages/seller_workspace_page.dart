import 'dart:io';

import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/features/seller/domain/repositories/seller_repository.dart';
import 'package:aqarat_app/features/properties/data/models/property_model.dart';
import 'package:aqarat_app/features/properties/presentation/pages/property_details_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellerWorkspacePage extends StatefulWidget {
  const SellerWorkspacePage({
    super.key,
    required this.repository,
    required this.name,
  });
  final SellerRepository repository;
  final String name;
  @override
  State<SellerWorkspacePage> createState() => _SellerWorkspacePageState();
}

class _SellerWorkspacePageState extends State<SellerWorkspacePage> {
  late Future<Map<String, dynamic>> _dashboard;
  late Future<List<Map<String, dynamic>>> _listings;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dashboard = widget.repository.dashboard();
    _listings = widget.repository.listings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newListing,
      icon: const Icon(Icons.add),
      label: const Text('Add a property'),
    ),
    body: RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your property workspace',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage listings, viewings and buyer requests.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, dynamic>>(
            future: _dashboard,
            builder: (_, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                );
              if (snapshot.hasError)
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString()),
                );
              final data = snapshot.data ?? const <String, dynamic>{};
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.42,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _stat(
                    Icons.apartment_outlined,
                    'Properties',
                    _count(data, [
                      'properties',
                      'listings',
                      'total_properties',
                    ]),
                  ),
                  _stat(
                    Icons.pending_actions_outlined,
                    'In review',
                    _listingStatusCount(data, 'pending'),
                  ),
                  _stat(
                    Icons.calendar_month_outlined,
                    'Viewings',
                    _count(data, ['bookings', 'viewings', 'total_bookings']),
                  ),
                  _stat(
                    Icons.chat_bubble_outline,
                    'Requests',
                    _count(data, ['leads', 'total_leads']),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _listings,
            builder: (_, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              final items = snapshot.data ?? const <Map<String, dynamic>>[];
              if (items.isEmpty) return _empty();
              return _latestListings(items);
              /* Previous simple listing layout.
              return Column(
                children: items
                    .take(3)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.home_work_outlined),
                          ),
                          title: Text(
                            item['title']?.toString() ?? 'Untitled property',
                          ),
                          subtitle: Text(
                            '${item['region'] ?? ''} · ${item['listing_status'] ?? 'draft'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openListings,
                        ),
                      ),
                    )
                    .toList(),
              ); */
            },
          ),
        ],
      ),
    ),
  );
  int _count(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) return value.length;
      final count = int.tryParse(value?.toString() ?? '');
      if (count != null) return count;
    }
    return 0;
  }
  int _listingStatusCount(Map<String, dynamic> data, String status) {
    final properties = data['properties'];
    if (properties is List) {
      return properties.whereType<Map>().where((property) => property['listing_status']?.toString() == status).length;
    }
    return _count(data, [status, '${status}_properties']);
  }

  Widget _stat(IconData icon, String label, int count) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E9E5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF007A61)),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
  Widget _empty() => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E9E5)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.home_work_outlined,
          size: 42,
          color: Color(0xFF85A193),
        ),
        const SizedBox(height: 10),
        const Text(
          'No properties yet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: _newListing,
          child: const Text('Add your first property'),
        ),
      ],
    ),
  );
  Widget _latestListings(List<Map<String, dynamic>> items) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Latest listings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 3), const Text('Track listing status and details in one place.', style: TextStyle(fontSize: 12, color: Colors.black54))])), TextButton.icon(onPressed: _openListings, iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('View all'))]),
      const SizedBox(height: 12),
      ...items.take(3).map(_latestListing),
    ]),
  );
  Widget _latestListing(Map<String, dynamic> item) {
    final raw = item['images'];
    final image = raw is List && raw.isNotEmpty ? raw.first.toString() : null;
    final status = item['listing_status']?.toString() ?? 'draft';
    final color = status == 'pending' ? const Color(0xFFB0801E) : status == 'approved' ? const Color(0xFF007A61) : const Color(0xFF687A70);
    return InkWell(onTap: () => _openSellerPropertyDetails(context, item), borderRadius: BorderRadius.circular(12), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(vertical: 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEAF0EC)))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: 62, height: 62, child: image == null ? const ColoredBox(color: Color(0xFFE8F5F0), child: Icon(Icons.home_work_outlined)) : Image.network(_imageUrl(image), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE8F5F0), child: Icon(Icons.home_work_outlined))))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['title']?.toString() ?? 'Untitled property', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${item['region'] ?? ''} · ${item['area'] ?? '-'} m²', style: const TextStyle(fontSize: 11, color: Colors.black54)), const SizedBox(height: 8), Text('${item['price'] ?? '-'} EGP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(6)), child: Text(status == 'pending' ? 'Under review' : status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))), const SizedBox(height: 12), Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF007A61)), const SizedBox(width: 3), Text('${item['views'] ?? 0}', style: const TextStyle(fontSize: 11)), const SizedBox(width: 8), const Icon(Icons.favorite_border, size: 15, color: Color(0xFFB35E5E)), const SizedBox(width: 3), Text('${item['favorite_count'] ?? 0}', style: const TextStyle(fontSize: 11))])]),
    ])));
  }
  Future<void> _newListing() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SellerListingFormPage(repository: widget.repository),
      ),
    );
    if (saved == true && mounted) setState(_load);
  }

  Future<void> _openListings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SellerListingsPage(repository: widget.repository),
      ),
    );
    if (mounted) setState(_load);
  }
}

class SellerListingsPage extends StatefulWidget {
  const SellerListingsPage({super.key, required this.repository});
  final SellerRepository repository;
  @override
  State<SellerListingsPage> createState() => _SellerListingsPageState();
}

class _SellerListingsPageState extends State<SellerListingsPage> {
  late Future<List<Map<String, dynamic>>> _items;
  String _query = '', _status = 'all';
  @override
  void initState() {
    super.initState();
    _items = widget.repository.listings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Properties')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: const Text('Add a property'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        final items = snapshot.data ?? const <Map<String, dynamic>>[];
        final filtered = items.where((item) {
          final text =
              '${item['title'] ?? ''} ${item['region'] ?? ''} ${item['id'] ?? ''}'
                  .toLowerCase();
          return text.contains(_query.toLowerCase()) &&
              (_status == 'all' ||
                  item['listing_status']?.toString() == _status);
        }).toList();
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() { _items = widget.repository.listings(); }),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Manage your business',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Properties',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'All the details you need, in one place.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E9E4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Manage listings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${items.length}',
                            style: const TextStyle(
                              color: Color(0xFF007A61),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (_, constraints) => constraints.maxWidth < 480
                          ? Column(
                              children: [
                                _search(),
                                const SizedBox(height: 10),
                                _statusFilter(items),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _search()),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 180,
                                  child: _statusFilter(items),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            items.isEmpty
                                ? 'No properties yet.'
                                : 'No matching properties.',
                          ),
                        ),
                      )
                    else
                      ...filtered.map(_propertyCard),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _search() => TextField(
    onChanged: (value) => setState(() => _query = value),
    decoration: const InputDecoration(
      prefixIcon: Icon(Icons.search),
      hintText: 'Search by title, area or listing number',
      border: OutlineInputBorder(),
    ),
  );
  Widget _statusFilter(List<Map<String, dynamic>> items) {
    final statuses = items
        .map((item) => item['listing_status']?.toString())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final selected = _status == 'all' || statuses.contains(_status)
        ? _status
        : 'all';
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All statuses')),
        ...statuses.map(
          (value) =>
              DropdownMenuItem(value: value, child: Text(_statusLabel(value))),
        ),
      ],
      onChanged: (value) => setState(() => _status = value ?? 'all'),
    );
  }

  Widget _propertyCard(Map<String, dynamic> item) {
    final raw = item['images'];
    final image = raw is List && raw.isNotEmpty ? raw.first.toString() : null;
    final status = item['listing_status']?.toString() ?? 'draft';
    return InkWell(
      onTap: () => _openSellerPropertyDetails(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E9E4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: image == null
                      ? const ColoredBox(
                          color: Color(0xFFE8F5F0),
                          child: Icon(Icons.apartment_outlined),
                        )
                      : Image.network(
                          _listingImageUrl(image),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFE8F5F0),
                            child: Icon(Icons.apartment_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? 'Untitled property',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '#${item['id'] ?? '-'} · ${item['region'] ?? ''} · ${item['area'] ?? '-'} m²',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item['price'] ?? '-'} EGP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A61),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _action(action, item),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'sold', child: Text('Mark as sold')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip(status),
              const Spacer(),
              const Icon(
                Icons.visibility_outlined,
                size: 17,
                color: Color(0xFF007A61),
              ),
              const SizedBox(width: 4),
              Text(
                '${item['views'] ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.favorite_border,
                size: 17,
                color: Color(0xFFB35E5E),
              ),
              const SizedBox(width: 4),
              Text(
                '${item['favorite_count'] ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              IconButton(
                onPressed: () => _edit(item),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'approved'
        ? const Color(0xFF007A61)
        : status == 'pending'
        ? const Color(0xFFB0801E)
        : status == 'sold'
        ? Colors.blueGrey
        : const Color(0xFF687A70);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'pending' => 'Under review',
    'approved' => 'Approved',
    'draft' => 'Draft',
    'sold' => 'Sold',
    _ => status,
  };
  String _listingImageUrl(String path) =>
      path.startsWith('http') ? path : 'http://192.168.18.66:3000$path';
  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SellerListingFormPage(repository: widget.repository),
      ),
    );
    if (saved == true && mounted)
      setState(() { _items = widget.repository.listings(); });
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            SellerListingFormPage(repository: widget.repository, listing: item),
      ),
    );
    if (saved == true && mounted)
      setState(() { _items = widget.repository.listings(); });
  }

  Future<void> _action(String action, Map<String, dynamic> item) async {
    if (action == 'edit') return _edit(item);
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    try {
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Delete property?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await widget.repository.deleteListing(id);
      } else {
        await widget.repository.setListingStatus(id, action);
      }
      if (mounted) setState(() { _items = widget.repository.listings(); });
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class SellerListingFormPage extends StatefulWidget {
  const SellerListingFormPage({
    super.key,
    required this.repository,
    this.listing,
  });
  final SellerRepository repository;
  final Map<String, dynamic>? listing;
  @override
  State<SellerListingFormPage> createState() => _SellerListingFormPageState();
}

class _SellerListingFormPageState extends State<SellerListingFormPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _region = TextEditingController(),
      _address = TextEditingController(),
      _price = TextEditingController(),
      _area = TextEditingController(),
      _rooms = TextEditingController(),
      _baths = TextEditingController(),
      _floor = TextEditingController(),
      _description = TextEditingController(),
      _whatsapp = TextEditingController(),
      _office = TextEditingController();
  String _type = 'sale',
      _kind = 'apartment',
      _priceUnit = 'total',
      _finishValue = 'Luxury finish';
  bool _confirmed = false, _saving = false;
  final List<File> _newImages = [];
  List<String> _images = [];
  bool get _editing => widget.listing != null;
  @override
  void initState() {
    super.initState();
    _rooms.text = '3';
    _baths.text = '1';
    final d = widget.listing;
    if (d != null) {
      _title.text = _value(d, 'title');
      _region.text = _value(d, 'region');
      _address.text = _value(d, 'address');
      _price.text = _value(d, 'price');
      _area.text = _value(d, 'area');
      _rooms.text = _value(d, 'rooms');
      _baths.text = _value(d, 'baths');
      _floor.text = _value(d, 'floor_name');
      _finishValue = _value(d, 'finish_type', 'Luxury finish');
      _description.text = _value(d, 'description');
      _whatsapp.text = _value(d, 'whatsapp');
      _office.text = _value(d, 'office_name');
      _type = _value(d, 'property_type', 'sale');
      _kind = _value(d, 'property_kind', 'apartment');
      _priceUnit = _value(d, 'price_unit', 'total');
      final raw = d['images'];
      _images = raw is List ? raw.map((e) => e.toString()).toList() : [];
    }
    _loadSellerContact();
  }

  String _value(
    Map<String, dynamic> values,
    String key, [
    String fallback = '',
  ]) => values[key]?.toString().isNotEmpty == true
      ? values[key].toString()
      : fallback;
  Future<void> _loadSellerContact() async {
    try {
      final account = await widget.repository.account();
      if (!mounted) return;
      final phone = account['whatsapp']?.toString().trim().isNotEmpty == true
          ? account['whatsapp'].toString()
          : account['phone']?.toString() ?? '';
      final name = account['office_name']?.toString().trim().isNotEmpty == true
          ? account['office_name'].toString()
          : account['full_name']?.toString() ?? '';
      if (_whatsapp.text.trim().isEmpty) _whatsapp.text = phone;
      if (_office.text.trim().isEmpty) _office.text = name;
      setState(() {});
    } on ApiException {
      // The form remains usable if profile data cannot be loaded.
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _region,
      _address,
      _price,
      _area,
      _rooms,
      _baths,
      _floor,
      _description,
      _whatsapp,
      _office,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Edit property' : 'Add a property')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          const Text(
            'Your property workspace',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF007A61),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _editing ? 'Update your property' : 'Add a new property',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 22),
          _section(
            1,
            'The basics',
            'Details that help buyers find your property.',
            _responsive([
              _field(
                _title,
                'Listing title',
                hint: 'Example: 150 m² luxury-finished apartment in Faisal',
              ),
              _select('Listing purpose', _type, const {
                'sale': 'For sale',
                'rent': 'For rent',
                'admin': 'Administrative',
              }, (value) => _type = value),
              _field(_region, 'Area', hint: 'Choose an area'),
              _select('Unit type', _kind, const {
                'apartment': 'Apartment',
                'villa': 'Villa',
                'office': 'Office',
                'commercial': 'Commercial',
                'land': 'Land',
                'admin': 'Administrative',
              }, (value) => _kind = value),
              _field(
                _address,
                'Detailed address',
                hint: 'Street and nearest landmark',
              ),
            ], columns: 2),
          ),
          _section(
            2,
            'Specifications and price',
            'Every detail helps the buyer make a decision.',
            _responsive([
              _field(_price, 'Price (EGP)', number: true),
              _select('Pricing method', _priceUnit, const {
                'total': 'Total price',
                'monthly': 'Monthly price',
              }, (value) => _priceUnit = value),
              _field(_area, 'Area (m²)', number: true),
              _field(_rooms, 'Number of bedrooms', number: true),
              _field(_baths, 'Bathrooms', number: true),
              _field(_floor, 'Floor', hint: 'Example: third floor'),
              _select('Finishing level', _finishValue, const {
                'Luxury finish': 'Luxury finish',
                'Finished': 'Finished',
                'Semi finished': 'Semi finished',
                'Unfinished': 'Unfinished',
              }, (value) => _finishValue = value),
            ], columns: 2),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _field(
              _description,
              'Property description',
              hint:
                  'Describe the property, facilities, and features. At least 20 characters.',
              lines: 5,
            ),
          ),
          _section(
            3,
            'Photos that tell the story',
            'From 1 to 8 photos. JPG, PNG, or WebP, up to 5 MB per photo.',
            _photoArea(),
          ),
          _section(
            4,
            'Direct contact',
            'Advertiser information shown to interested buyers.',
            _responsive([
              _field(_whatsapp, 'WhatsApp number', number: true),
              _field(_office, 'Office / advertiser name'),
            ], columns: 2),
          ),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I confirm the information is accurate and I have the right to advertise this property.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (_, constraints) => constraints.maxWidth < 500
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _action(
                        'Submit listing for review',
                        () => _save('pending'),
                        filled: true,
                      ),
                      const SizedBox(height: 10),
                      _action('Save as draft', () => _save('draft')),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _action(
                          'Submit listing for review',
                          () => _save('pending'),
                          filled: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _action('Save as draft', () => _save('draft')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
  Widget _section(int step, String title, String subtitle, Widget child) =>
      Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE1E9E4))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFFFFBF2),
                  foregroundColor: const Color(0xFFB0801E),
                  child: Text(
                    step.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      );
  Widget _responsive(List<Widget> children, {required int columns}) =>
      LayoutBuilder(
        builder: (_, constraints) {
          final wide = constraints.maxWidth >= 620;
          if (!wide)
            return Column(
              children: children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: child,
                    ),
                  )
                  .toList(),
            );
          final rows = <Widget>[];
          for (var i = 0; i < children.length; i += columns) {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[i]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: i + 1 < children.length
                          ? children[i + 1]
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(children: rows);
        },
      );
  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool number = false,
    int lines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return '$label is required';
          if (controller == _description && text.length < 20)
            return 'Description must be at least 20 characters';
          return null;
        },
      ),
    ],
  );
  Widget _select(
    String label,
    String current,
    Map<String, String> choices,
    ValueChanged<String> changed,
  ) {
    final options = Map<String, String>.from(choices);
    options.putIfAbsent(current, () => current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: current,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => changed(value));
          },
        ),
      ],
    );
  }

  Widget _photoArea() => Column(
    children: [
      if (_images.isEmpty && _newImages.isEmpty)
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            height: 145,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FCF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFAFD5C1),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  size: 34,
                  color: Color(0xFF007A61),
                ),
                SizedBox(height: 8),
                Text(
                  'Click to choose property photos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A61),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Clear, genuine photos help your listing reach buyers.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      if (_images.isNotEmpty || _newImages.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._images.asMap().entries.map(
              (entry) => _imageTile(
                url: entry.value,
                remove: () => setState(() => _images.removeAt(entry.key)),
              ),
            ),
            ..._newImages.asMap().entries.map(
              (entry) => _imageTile(
                file: entry.value,
                remove: () => setState(() => _newImages.removeAt(entry.key)),
              ),
            ),
            if (_images.length + _newImages.length < 8)
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photos'),
              ),
          ],
        ),
      if (_images.isNotEmpty || _newImages.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${_images.length + _newImages.length}/8 photos selected',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
    ],
  );
  Widget _imageTile({String? url, File? file, required VoidCallback remove}) =>
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 94,
              height: 94,
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : Image.network(
                      _imageUrl(url!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE8F5F0)),
                    ),
            ),
          ),
          PositionedDirectional(
            top: 3,
            end: 3,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: remove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
  Widget _action(String label, VoidCallback onPressed, {bool filled = false}) =>
      SizedBox(
        height: 52,
        child: filled
            ? FilledButton.icon(
                onPressed: _saving ? null : onPressed,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(label),
              )
            : OutlinedButton(
                onPressed: _saving ? null : onPressed,
                child: Text(label),
              ),
      );
  Future<void> _pickImages() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheet, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheet, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final remaining = 8 - _images.length - _newImages.length;
    final selected = source == 'camera'
        ? [
            if (await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 88,
                )
                case final image?)
              image,
          ]
        : await picker.pickMultiImage(imageQuality: 88);
    final accepted = <File>[];
    for (final image in selected.take(remaining)) {
      final file = File(image.path);
      final extension = image.path.split('.').last.toLowerCase();
      if (const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension) &&
          await file.length() <= 5 * 1024 * 1024)
        accepted.add(file);
    }
    if (!mounted) return;
    if (accepted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose JPEG, PNG, or WebP photos up to 5 MB.'),
        ),
      );
      return;
    }
    setState(() => _newImages.addAll(accepted));
  }

  Future<void> _save(String status) async {
    if (!_form.currentState!.validate()) return;
    if (_images.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one property photo.')),
      );
      return;
    }
    if (status == 'pending' && !_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm that the property information is accurate.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_newImages.isNotEmpty)
        _images.addAll(await widget.repository.uploadImages(_newImages));
      final data = {
        'title': _title.text.trim(),
        'property_type': _type,
        'property_kind': _kind,
        'listing_status': status,
        'region': _region.text.trim(),
        'address': _address.text.trim(),
        'price': num.tryParse(_price.text.replaceAll(',', '')) ?? 0,
        'price_unit': _priceUnit,
        'area': num.tryParse(_area.text) ?? 0,
        'rooms': int.tryParse(_rooms.text) ?? 0,
        'baths': int.tryParse(_baths.text) ?? 0,
        'floor_name': _floor.text.trim(),
        'finish_type': _finishValue,
        'description': _description.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'office_name': _office.text.trim(),
        'images': _images,
      };
      if (_editing) {
        final id = int.tryParse(widget.listing?['id']?.toString() ?? '');
        if (id == null)
          throw const ApiException(
            'This property cannot be updated because its ID is missing.',
          );
        await widget.repository.updateListing(id, data);
      } else {
        await widget.repository.createListing(data);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<void> _openSellerPropertyDetails(BuildContext context, Map<String, dynamic> item) async {
  final property = PropertyModel.fromJson(item);
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PropertyDetailsPage(propertyId: property.id, preview: property)));
}

String _imageUrl(String path) =>
    path.startsWith('http') ? path : 'http://192.168.18.66:3000$path';
