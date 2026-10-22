import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/get_saved_session_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aqarat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:aqarat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
export 'auth_event.dart'; export 'auth_state.dart';
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUseCase, this._registerUseCase, this._getSavedSessionUseCase, this._logoutUseCase) : super(const AuthState()) { on<AuthSessionRequested>(_restoreSession); on<AuthLogoutRequested>(_logout); on<LoginSubmitted>(_login); on<SignUpSubmitted>(_register); }
  final LoginUseCase _loginUseCase; final RegisterUseCase _registerUseCase; final GetSavedSessionUseCase _getSavedSessionUseCase; final LogoutUseCase _logoutUseCase;
  Future<void> _logout(AuthLogoutRequested event, Emitter<AuthState> emit) async { await _logoutUseCase(); emit(const AuthState()); }
  Future<void> _restoreSession(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final user = await _getSavedSessionUseCase();
      debugPrint('[Aqarat Session] ${user == null ? 'No valid saved session.' : 'Session restored for ${user.fullName}.'}');
      emit(user == null ? const AuthState() : AuthState(status: AuthStatus.authenticated, user: user));
    } catch (error, stackTrace) {
      debugPrint('[Aqarat Session] Restore failed: $error\n$stackTrace');
      emit(const AuthState());
    }
  }
  bool _validPhone(String phone) => phone.trim().length >= 8;
  Future<void> _login(LoginSubmitted e, Emitter<AuthState> emit) async { if (!_validPhone(e.phone) || e.password.length < 6) { emit(const AuthState(status: AuthStatus.failure, errorMessage: 'Enter a valid phone number and a password of at least 6 characters.')); return; } emit(const AuthState(status: AuthStatus.loading)); try { final result = await _loginUseCase(phone: e.phone, password: e.password); emit(AuthState(status: AuthStatus.authenticated, user: result.user)); } on ApiException catch (error) { emit(AuthState(status: AuthStatus.failure, errorMessage: error.message)); } }
  Future<void> _register(SignUpSubmitted e, Emitter<AuthState> emit) async { if (e.fullName.trim().isEmpty || !_validPhone(e.phone) || e.password.length < 6) { emit(const AuthState(status: AuthStatus.failure, errorMessage: 'Complete all fields. Password must be at least 6 characters.')); return; } emit(const AuthState(status: AuthStatus.loading)); try { final result = await _registerUseCase(fullName: e.fullName, phone: e.phone, password: e.password, role: e.role); emit(AuthState(status: AuthStatus.authenticated, user: result.user)); } on ApiException catch (error) { emit(AuthState(status: AuthStatus.failure, errorMessage: error.message)); } }
}
