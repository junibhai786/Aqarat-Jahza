import 'package:aqarat_app/app.dart';
import 'package:aqarat_app/features/auth/domain/entities/user.dart';
import 'package:aqarat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aqarat_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/get_saved_session_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/features/properties/domain/entities/property.dart';
import 'package:aqarat_app/features/properties/domain/repositories/property_repository.dart';
import 'package:aqarat_app/features/properties/presentation/bloc/property_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override Future<AuthResult> login({required String phone, required String password}) async => throw UnimplementedError();
  @override Future<AuthResult> register({required String fullName, required String phone, required String password, required String role}) async => throw UnimplementedError();
  @override Future<void> logout() async {}
  @override Future<User?> getSavedUser() async => null;
}

class _FakePropertyRepository implements PropertyRepository {
  @override Future<Property> details(int id) async => throw UnimplementedError();
  @override Future<List<String>> regions() async => [];
  @override Future<void> recordView(int id) async {}
  @override Future<PropertyResult> search({Map<String, dynamic>? filters, int page = 1}) async => const PropertyResult(properties: [], page: 1, hasMore: false);
}

void main() {
  testWidgets('starts on login page', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(AqaratApp(authBloc: AuthBloc(LoginUseCase(repository), RegisterUseCase(repository), GetSavedSessionUseCase(repository), LogoutUseCase(repository)), propertyBloc: PropertyBloc(_FakePropertyRepository())));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
