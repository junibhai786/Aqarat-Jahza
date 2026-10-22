import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:flutter/material.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key, required this.repository, required this.regions});

  final BuyerRepository repository;
  final List<String> regions;

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  late Future<List<Map<String, dynamic>>> _leads;

  @override
  void initState() {
    super.initState();
    _leads = widget.repository.leads();
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(builder: (_) => _CreateLeadPage(repository: widget.repository, regions: widget.regions)));
    if (created == true && mounted) setState(() => _leads = widget.repository.leads());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.tr('requests')),
          actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.search))],
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: Text(context.tr('newRequest'))),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _leads,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final leads = snapshot.data ?? const <Map<String, dynamic>>[];
            return RefreshIndicator(
              onRefresh: () async => setState(() => _leads = widget.repository.leads()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(context.tr('yourPersonalSpace'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(context.tr('propertySearchRequests'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(context.tr('allDetailsOnePlace'), style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),
                  if (leads.isEmpty)
                    _empty(context)
                  else
                    ...leads.map((lead) => _leadCard(context, lead)),
                ],
              ),
            );
          },
        ),
      );

  Widget _empty(BuildContext context) => Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
        child: Column(children: [const Icon(Icons.chat_bubble_outline, size: 45, color: Color(0xFF91AE9D)), const SizedBox(height: 12), Text(context.tr('noRequests')), const SizedBox(height: 12), FilledButton(onPressed: _create, child: Text(context.tr('newRequest')))]),
      );

  Widget _leadCard(BuildContext context, Map<String, dynamic> lead) {
    final purpose = lead['purpose']?.toString() ?? '-';
    final region = lead['region']?.toString() ?? '-';
    final budget = lead['budget']?.toString() ?? '-';
    final rooms = lead['rooms']?.toString() ?? '-';
    final details = lead['details']?.toString() ?? '';
    final status = lead['status']?.toString() ?? 'new';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(_purposeLabel(context, purpose), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))), Chip(label: Text(status))]),
        const SizedBox(height: 8),
        Text('$region • $budget EGP', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$rooms ${context.tr('bedrooms')}', style: const TextStyle(color: Colors.black54)),
        if (details.isNotEmpty) ...[const Divider(height: 22), Text(details)],
      ]),
    );
  }

  String _purposeLabel(BuildContext context, String purpose) => purpose == 'rent' ? context.tr('forRent') : purpose == 'sale' ? context.tr('forSale') : purpose;
}

class _CreateLeadPage extends StatefulWidget {
  const _CreateLeadPage({required this.repository, required this.regions});
  final BuyerRepository repository;
  final List<String> regions;

  @override
  State<_CreateLeadPage> createState() => _CreateLeadPageState();
}

class _CreateLeadPageState extends State<_CreateLeadPage> {
  final _budget = TextEditingController();
  final _details = TextEditingController();
  String? _purpose;
  String? _region;
  String? _rooms;
  bool _saving = false;

  @override
  void dispose() { _budget.dispose(); _details.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_purpose == null || _region == null || _rooms == null || _budget.text.trim().isEmpty || _details.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('completeAllFields'))));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.createLead(purpose: _purpose!, region: _region!, budget: num.tryParse(_budget.text.replaceAll(',', '')) ?? 0, rooms: int.tryParse(_rooms!) ?? 0, details: _details.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('requestSent'))));
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('newRequest'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(context.tr('tellUsNeed'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(context.tr('tellUsNeedHint'), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(value: _purpose, hint: Text(context.tr('choosePurpose')), items: [DropdownMenuItem(value: 'sale', child: Text(context.tr('forSale'))), DropdownMenuItem(value: 'rent', child: Text(context.tr('forRent')))], onChanged: (value) => setState(() => _purpose = value)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(value: _region, hint: Text(context.tr('chooseArea')), items: widget.regions.map((region) => DropdownMenuItem(value: region, child: Text(region))).toList(), onChanged: (value) => setState(() => _region = value)),
          const SizedBox(height: 14),
          TextField(controller: _budget, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: context.tr('maximumBudget'))),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(value: _rooms, hint: Text(context.tr('bedrooms')), items: const [DropdownMenuItem(value: '1', child: Text('1')), DropdownMenuItem(value: '2', child: Text('2')), DropdownMenuItem(value: '3', child: Text('3')), DropdownMenuItem(value: '4', child: Text('4+'))], onChanged: (value) => setState(() => _rooms = value)),
          const SizedBox(height: 14),
          TextField(controller: _details, minLines: 5, maxLines: 7, decoration: InputDecoration(labelText: context.tr('helpfulDetails'), hintText: context.tr('detailsHint'), alignLabelWithHint: true)),
          const SizedBox(height: 22),
          SizedBox(height: 52, child: FilledButton.icon(onPressed: _saving ? null : _submit, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.arrow_forward), label: Text(context.tr('sendRequest')))),
        ]),
      );
}
