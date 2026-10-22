import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.repository});

  final BuyerRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _profile = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.repository.account();
      if (!mounted) return;
      _profile = profile;
      _name.text = profile['full_name']?.toString() ?? '';
      _phone.text = profile['phone']?.toString() ?? '';
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_newPassword.text.isNotEmpty && _newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('passwordsMatch'))));
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = await widget.repository.updateAccount(
        fullName: _name.text.trim(),
        currentPassword: _currentPassword.text.trim().isEmpty ? null : _currentPassword.text,
        newPassword: _newPassword.text.trim().isEmpty ? null : _newPassword.text,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('profileUpdated'))));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('accountSettings'))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _profileSummary(context),
                  const SizedBox(height: 16),
                  _section(
                    context,
                    title: context.tr('personalInformation'),
                    subtitle: context.tr('personalInformationHint'),
                    children: [
                      TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('fullName'), prefixIcon: const Icon(Icons.person_outline))),
                      const SizedBox(height: 14),
                      TextField(readOnly: true, controller: _phone, decoration: InputDecoration(labelText: context.tr('phoneNumber'), prefixIcon: const Icon(Icons.phone_outlined))),
                      const SizedBox(height: 8),
                      Text(context.tr('phoneUpdateHint'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _section(
                    context,
                    title: context.tr('accountSecurity'),
                    subtitle: context.tr('accountSecurityHint'),
                    children: [
                      TextField(controller: _currentPassword, obscureText: true, decoration: InputDecoration(labelText: context.tr('currentPassword'), prefixIcon: const Icon(Icons.lock_outline))),
                      const SizedBox(height: 14),
                      TextField(controller: _newPassword, obscureText: true, decoration: InputDecoration(labelText: context.tr('newPassword'), prefixIcon: const Icon(Icons.lock_reset_outlined))),
                      const SizedBox(height: 14),
                      TextField(controller: _confirmPassword, obscureText: true, decoration: InputDecoration(labelText: context.tr('confirmNewPassword'), prefixIcon: const Icon(Icons.lock_reset_outlined))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(context.tr('saveChanges')))),
                ],
              ),
      );

  Widget _profileSummary(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
        child: Column(children: [
          CircleAvatar(radius: 32, backgroundColor: const Color(0xFFE8F2EB), child: Text((_profile['full_name']?.toString().isNotEmpty == true ? _profile['full_name'].toString()[0] : '?').toUpperCase(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))),
          const SizedBox(height: 10),
          Text(_profile['full_name']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_profile['role']?.toString() ?? '', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Chip(avatar: const Icon(Icons.circle, color: Colors.green, size: 10), label: Text(_profile['status']?.toString() ?? '-')),
        ]),
      );

  Widget _section(BuildContext context, {required String title, required String subtitle, required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)), const SizedBox(height: 18), ...children]),
      );
}
