import 'package:aqarat_app/features/auth/domain/entities/user.dart';
import 'package:aqarat_app/features/auth/domain/repositories/auth_repository.dart';

class GetSavedSessionUseCase {
  const GetSavedSessionUseCase(this._repository);
  final AuthRepository _repository;

  Future<User?> call() => _repository.getSavedUser();
}
