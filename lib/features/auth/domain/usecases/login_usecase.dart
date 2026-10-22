import 'package:aqarat_app/features/auth/domain/repositories/auth_repository.dart';
class LoginUseCase { const LoginUseCase(this._repository); final AuthRepository _repository; Future<AuthResult> call({required String phone, required String password}) => _repository.login(phone: phone, password: password); }
