import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/features/auth/presentation/pages/login_page.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) context.read<AuthBloc>().add(const AuthSessionRequested());
  }

  void _open(Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state.status == AuthStatus.authenticated) _open(const HomePage());
      if (state.status == AuthStatus.initial) _open(const LoginPage());
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'assets/images/aqarat_jahza_logo_ar.png'
                      : 'assets/images/aqarat_jahza_logo.png',
                  width: 300,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 42),
                SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 16),
                Text(context.tr('findingPlace')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
