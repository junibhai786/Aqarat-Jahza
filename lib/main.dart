import 'package:aqarat_app/app.dart';
import 'package:aqarat_app/injection_container.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await AppLocaleController.instance.load(); final authBloc = await InjectionContainer.authBloc(); final propertyBloc = await InjectionContainer.createPropertyBloc(); runApp(AqaratApp(authBloc: authBloc, propertyBloc: propertyBloc)); }
