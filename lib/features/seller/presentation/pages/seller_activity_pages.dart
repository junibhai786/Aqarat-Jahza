import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/features/seller/domain/repositories/seller_repository.dart';
import 'package:flutter/material.dart';

class SellerBookingsPage extends StatefulWidget {
  const SellerBookingsPage({super.key, required this.repository});
  final SellerRepository repository;
  @override
  State<SellerBookingsPage> createState() => _SellerBookingsPageState();
}

class _SellerBookingsPageState extends State<SellerBookingsPage> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _items = widget.repository.bookings();
  }

  @override
  Widget build(BuildContext context) => _ActivityScaffold(
    title: 'Viewing requests',
    future: _items,
    refresh: () async => setState(() { _items = widget.repository.bookings(); }),
    empty: 'No viewing requests.',
    item: (item) {
      final id = int.tryParse(item['id']?.toString() ?? '');
      final p = item['property'];
      final property = p is Map ? p : const <String, dynamic>{};
      final status = item['status']?.toString() ?? 'pending';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      property['title']?.toString() ??
                          item['property_title']?.toString() ??
                          'Property',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(label: Text(status)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Requested for: ${item['requested_for'] ?? '-'}'),
              if ((item['message']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(item['message'].toString()),
                ),
              if (id != null && !['cancelled', 'completed'].contains(status))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (status == 'pending')
                        OutlinedButton(
                          onPressed: () => _update(id, 'confirmed'),
                          child: const Text('Confirm'),
                        ),
                      OutlinedButton(
                        onPressed: () => _update(id, 'cancelled'),
                        child: const Text('Cancel'),
                      ),
                      if (status == 'confirmed')
                        FilledButton(
                          onPressed: () => _update(id, 'completed'),
                          child: const Text('Complete'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
  Future<void> _update(int id, String status) async {
    try {
      await widget.repository.updateBooking(id, status);
      if (mounted) setState(() { _items = widget.repository.bookings(); });
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class SellerLeadsPage extends StatefulWidget {
  const SellerLeadsPage({super.key, required this.repository});
  final SellerRepository repository;
  @override
  State<SellerLeadsPage> createState() => _SellerLeadsPageState();
}

class _SellerLeadsPageState extends State<SellerLeadsPage> {
  late Future<List<Map<String, dynamic>>> _items;
  String _filter = 'all';
  @override
  void initState() {
    super.initState();
    _items = widget.repository.leads();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Property requests')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        final items = snapshot.data ?? const <Map<String, dynamic>>[];
        final filtered = _filter == 'all'
            ? items
            : items
                  .where((item) => item['status']?.toString() == _filter)
                  .toList();
        final statuses = items
            .map((item) => item['status']?.toString())
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() { _items = widget.repository.leads(); }),
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
                'Property requests',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'All the details you need, in one place.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Client requests',
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
                              const SizedBox(height: 4),
                              const Text(
                                'Review client requests and track contact status.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 125,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value:
                                _filter == 'all' || statuses.contains(_filter)
                                ? _filter
                                : 'all',
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              ...statuses.map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    _label(status),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _filter = value ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(26),
                        child: Center(child: Text('No client requests found.')),
                      )
                    else
                      ...filtered.map(_requestCard),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _requestCard(Map<String, dynamic> item) {
    final id = int.tryParse(item['id']?.toString() ?? '');
    final status = item['status']?.toString() ?? 'new';
    final person = item['buyer'] is Map
        ? (item['buyer'] as Map).cast<String, dynamic>()
        : item;
    final name =
        person['full_name']?.toString() ??
        item['name']?.toString() ??
        'Customer request';
    final phone =
        person['phone']?.toString() ?? item['phone']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E9E4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _status(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: Color(0xFF687A70),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${item['region'] ?? '-'} · ${item['purpose'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${item['budget'] ?? '-'}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'EGP budget',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 7),
          Text(
            '${item['rooms'] ?? '-'} Bedrooms',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if ((item['details']?.toString() ?? '').isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              item['details'].toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (phone.isNotEmpty) ...[
            const Divider(height: 28),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 17,
                  color: Color(0xFF007A61),
                ),
                const SizedBox(width: 7),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Color(0xFF007A61),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (id != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'new')
                  OutlinedButton(
                    onPressed: () => _update(id, 'contacted'),
                    child: const Text('Contacted'),
                  ),
                if (status == 'closed')
                  OutlinedButton(
                    onPressed: () => _update(id, 'new'),
                    child: const Text('Reopen request'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _update(id, 'closed'),
                    child: const Text('Close request'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _status(String value) {
    final color = value == 'new'
        ? const Color(0xFFB0801E)
        : value == 'contacted'
        ? const Color(0xFF007A61)
        : const Color(0xFF687A70);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _label(value),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _label(String value) => switch (value) {
    'new' => 'New',
    'contacted' => 'Contacted',
    'qualified' => 'Qualified',
    'closed' => 'Closed',
    _ => value,
  };
  Future<void> _update(int id, String status) async {
    try {
      await widget.repository.updateLead(id, status);
      if (mounted) setState(() { _items = widget.repository.leads(); });
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class SellerNotificationsPage extends StatefulWidget {
  const SellerNotificationsPage({super.key, required this.repository});
  final SellerRepository repository;
  @override
  State<SellerNotificationsPage> createState() =>
      _SellerNotificationsPageState();
}

class _SellerNotificationsPageState extends State<SellerNotificationsPage> {
  late Future<List<Map<String, dynamic>>> _items;
  @override
  void initState() {
    super.initState();
    _items = widget.repository.notifications();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [TextButton(onPressed: _readAll, child: const Text('Read all'))],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text(s.error.toString()));
        final items = s.data ?? const [];
        if (items.isEmpty)
          return const Center(child: Text('No notifications.'));
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() { _items = widget.repository.notifications(); }),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return Card(
                color: item['read_at'] == null && item['is_read'] != true
                    ? const Color(0xFFF1FAF6)
                    : null,
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(item['title']?.toString() ?? 'Notification'),
                  subtitle: Text(
                    item['body']?.toString() ??
                        item['message']?.toString() ??
                        '',
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
  Future<void> _readAll() async {
    try {
      await widget.repository.markNotificationsRead();
      if (mounted) setState(() { _items = widget.repository.notifications(); });
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class SellerAccountPage extends StatefulWidget {
  const SellerAccountPage({super.key, required this.repository});
  final SellerRepository repository;
  @override
  State<SellerAccountPage> createState() => _SellerAccountPageState();
}

class _SellerAccountPageState extends State<SellerAccountPage> {
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _office = TextEditingController(),
      _currentPassword = TextEditingController(),
      _newPassword = TextEditingController(),
      _confirmPassword = TextEditingController();
  Map<String, dynamic> _profile = const {};
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _office,
      _currentPassword,
      _newPassword,
      _confirmPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.account();
      if (!mounted) return;
      _profile = data;
      _name.text = data['full_name']?.toString() ?? '';
      _phone.text = data['phone']?.toString() ?? '';
      _office.text = data['office_name']?.toString() ?? '';
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account settings')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summary(),
              const SizedBox(height: 16),
              _section('Personal information', 'Your public seller details.', [
                _field(_name, 'Full name'),
                _field(_phone, 'Phone number', readOnly: true),
                _field(_office, 'Office / advertiser name'),
              ]),
              const SizedBox(height: 16),
              _section(
                'Account security',
                'Leave these fields empty if you do not want to change your password.',
                [
                  _field(_currentPassword, 'Current password', obscure: true),
                  _field(_newPassword, 'New password', obscure: true),
                  _field(
                    _confirmPassword,
                    'Confirm new password',
                    obscure: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
  );
  Widget _summary() {
    final name = _profile['full_name']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFE8F2EB),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007A61),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _profile['role']?.toString() ?? 'seller',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(Icons.circle, color: Colors.green, size: 10),
            label: Text(_profile['status']?.toString() ?? 'active'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String subtitle, List<Widget> fields) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E9E4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ...fields,
          ],
        ),
      );
  Widget _field(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    bool obscure = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  Future<void> _save() async {
    if (_newPassword.text.isNotEmpty &&
        _newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'full_name': _name.text.trim(),
        'office_name': _office.text.trim(),
      };
      if (_newPassword.text.isNotEmpty) {
        data['current_password'] = _currentPassword.text;
        data['new_password'] = _newPassword.text;
      }
      final updated = await widget.repository.updateAccount(data);
      if (!mounted) return;
      setState(() => _profile = updated);
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ActivityScaffold extends StatelessWidget {
  const _ActivityScaffold({
    required this.title,
    required this.future,
    required this.refresh,
    required this.empty,
    required this.item,
  });
  final String title;
  final Future<List<Map<String, dynamic>>> future;
  final Future<void> Function() refresh;
  final String empty;
  final Widget Function(Map<String, dynamic>) item;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text(s.error.toString()));
        final data = s.data ?? const [];
        return RefreshIndicator(
          onRefresh: refresh,
          child: data.isEmpty
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(50),
                      child: Center(child: Text(empty)),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: data.map(item).toList(),
                ),
        );
      },
    ),
  );
}
