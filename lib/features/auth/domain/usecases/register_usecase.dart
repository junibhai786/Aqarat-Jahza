import 'package:aqarat_app/features/auth/domain/repositories/auth_repository.dart';
class RegisterUseCase { const RegisterUseCase(this._repository); final AuthRepository _repository; Future<AuthResult> call({required String fullName, required String phone, required String password, required String role}) => _repository.register(fullName: fullName, phone: phone, password: password, role: role); }
