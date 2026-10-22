import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/features/auth/presentation/pages/login_page.dart';
import 'package:aqarat_app/features/auth/presentation/pages/signup_page.dart';
import 'package:aqarat_app/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/properties/presentation/bloc/property_bloc.dart';
class AqaratApp extends StatelessWidget {
  const AqaratApp({super.key, required this.authBloc, required this.propertyBloc}); final AuthBloc authBloc; final PropertyBloc propertyBloc;
  @override Widget build(BuildContext context) => ValueListenableBuilder<Locale>(valueListenable: AppLocaleController.instance, builder: (_, locale, __) => MultiBlocProvider(providers: [BlocProvider.value(value: authBloc), BlocProvider.value(value: propertyBloc)], child: MaterialApp(debugShowCheckedModeBanner: false, title: 'Aqarat Jahza', locale: locale, supportedLocales: const [Locale('en'), Locale('ar')], localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate], theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)), scaffoldBackgroundColor: const Color(0xFFF8FAF8)), home: const SplashPage(), routes: {'/login': (_) => const LoginPage(), '/signup': (_) => const SignUpPage()})));
}
