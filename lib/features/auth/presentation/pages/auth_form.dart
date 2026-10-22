import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.isSignUp});

  final bool isSignUp;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String _role = 'buyer';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSignUp && _password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('passwordsDoNotMatch'))),
      );
      return;
    }
    final bloc = context.read<AuthBloc>();
    if (widget.isSignUp) {
      bloc.add(SignUpSubmitted(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        role: _role,
      ));
    } else {
      bloc.add(LoginSubmitted(phone: _phone.text.trim(), password: _password.text));
    }
  }

  InputDecoration _field(String label, IconData icon, {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAF9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5E1)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final signup = widget.isSignUp;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const HomePage()),
            (_) => false,
          );
        }
        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? context.tr('authenticationFailed'))),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _hero(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('oneStepCloser'),
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Text(signup ? context.tr('getToKnowYou') : context.tr('welcomeBack'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(signup ? context.tr('createAccountHint') : context.tr('signInHint'), style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 26),
                        if (signup) ...[
                          _rolePicker(context),
                          const SizedBox(height: 22),
                          TextField(controller: _name, textInputAction: TextInputAction.next, decoration: _field(context.tr('fullName'), Icons.person_outline, hint: context.tr('nameHint'))),
                          const SizedBox(height: 16),
                        ],
                        TextField(controller: _phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: _field(context.tr('phoneNumber'), Icons.phone_outlined, hint: context.tr('phoneHint'))),
                        const SizedBox(height: 16),
                        TextField(controller: _password, obscureText: _obscure, onSubmitted: (_) => signup ? null : _submit(), decoration: _field(context.tr('password'), Icons.lock_outline, hint: context.tr('passwordHint'), suffix: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                        if (signup) ...[
                          const SizedBox(height: 16),
                          TextField(controller: _confirm, obscureText: _obscure, decoration: _field(context.tr('confirmPassword'), Icons.lock_reset_outlined)),
                        ],
                        const SizedBox(height: 24),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: state.status == AuthStatus.loading ? null : _submit,
                              icon: state.status == AuthStatus.loading ? const SizedBox(height: 19, width: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward),
                              label: Text(signup ? context.tr('createAccount') : context.tr('signIn')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(signup ? context.tr('alreadyHaveAccount') : context.tr('newHere')),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushReplacementNamed(signup ? '/login' : '/signup'),
                              child: Text(signup ? context.tr('signIn') : context.tr('createAccount')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) => Container(
        width: double.infinity,
        height: 250,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF003F35), Color(0xFF087A61)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        child: Stack(children: [
          Positioned(right: -32, bottom: -38, child: const Icon(Icons.home_work_rounded, color: Colors.white12, size: 260)),
          PositionedDirectional(
            top: 14,
            end: 14,
            child: Material(
              color: Colors.white.withValues(alpha: 0.16),
              shape: const CircleBorder(),
              child: PopupMenuButton<String>(
                tooltip: context.tr('language'),
                icon: const Icon(Icons.language, color: Colors.white),
                onSelected: (languageCode) =>
                    AppLocaleController.instance.setLanguage(languageCode),
                itemBuilder: (menuContext) => [
                  PopupMenuItem(value: 'en', child: Text(context.tr('english'))),
                  PopupMenuItem(value: 'ar', child: Text(context.tr('arabic'))),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Image.asset(_logoAsset(context), width: 170, color: Colors.white),
              const Spacer(),
              Text(context.tr('yourHomeStory'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 33, height: 1.08)),
              const SizedBox(height: 10),
              Text(context.tr('saveCompare'), style: const TextStyle(color: Colors.white70)),
            ]),
          ),
        ]),
      );

  Widget _rolePicker(BuildContext context) => Row(children: [
        _roleButton('buyer', context.tr('buyer'), Icons.search),
        const SizedBox(width: 10),
        _roleButton('seller', context.tr('seller'), Icons.business_outlined),
      ]);

  String _logoAsset(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
          ? 'assets/images/aqarat_jahza_logo_ar.png'
          : 'assets/images/aqarat_jahza_logo.png';

  Widget _roleButton(String value, String label, IconData icon) {
    final selected = _role == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _role = value),
        child: Container(
          height: 58,
          decoration: BoxDecoration(color: selected ? const Color(0xFFE8F5F0) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? const Color(0xFF007A61) : const Color(0xFFDDE5E1))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 19), const SizedBox(width: 7), Text(label, style: const TextStyle(fontSize: 12))]),
        ),
      ),
    );
  }
}
