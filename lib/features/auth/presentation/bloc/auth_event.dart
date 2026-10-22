sealed class AuthEvent { const AuthEvent(); }
class AuthSessionRequested extends AuthEvent { const AuthSessionRequested(); }
class AuthLogoutRequested extends AuthEvent { const AuthLogoutRequested(); }
class LoginSubmitted extends AuthEvent { const LoginSubmitted({required this.phone, required this.password}); final String phone; final String password; }
class SignUpSubmitted extends AuthEvent { const SignUpSubmitted({required this.fullName, required this.phone, required this.password, required this.role}); final String fullName; final String phone; final String password; final String role; }
