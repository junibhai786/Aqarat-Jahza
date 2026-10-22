import 'package:aqarat_app/features/auth/domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, failure }
class AuthState { const AuthState({this.status = AuthStatus.initial, this.errorMessage, this.user}); final AuthStatus status; final String? errorMessage; final User? user; }
