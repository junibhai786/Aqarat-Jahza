import 'package:aqarat_app/core/network/dio_client.dart';
import 'package:aqarat_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aqarat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aqarat_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/get_saved_session_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:aqarat_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/features/buyer/data/datasources/buyer_remote_datasource.dart';
import 'package:aqarat_app/features/buyer/data/repositories/buyer_repository_impl.dart';
import 'package:aqarat_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:aqarat_app/features/properties/data/datasources/property_remote_datasource.dart';
import 'package:aqarat_app/features/properties/data/repositories/property_repository_impl.dart';
import 'package:aqarat_app/features/properties/presentation/bloc/property_bloc.dart';
import 'package:aqarat_app/features/seller/data/datasources/seller_remote_datasource.dart';
import 'package:aqarat_app/features/seller/data/repositories/seller_repository_impl.dart';
import 'package:aqarat_app/features/seller/domain/repositories/seller_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InjectionContainer {
  static Future<AuthBloc> authBloc() async {
    final preferences = await SharedPreferences.getInstance();
    final client = DioClient(preferences);
    final repository = AuthRepositoryImpl(AuthRemoteDataSource(client), preferences, client);
    return AuthBloc(LoginUseCase(repository), RegisterUseCase(repository), GetSavedSessionUseCase(repository), LogoutUseCase(repository));
  }

  static Future<PropertyBloc> createPropertyBloc() async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PropertyRepositoryImpl(PropertyRemoteDataSource(DioClient(preferences)));
    return PropertyBloc(repository);
  }

  static Future<BuyerRepository> buyerRepository() async {
    final preferences = await SharedPreferences.getInstance();
    return BuyerRepositoryImpl(BuyerRemoteDataSource(DioClient(preferences)));
  }

  static Future<SellerRepository> sellerRepository() async {
    final preferences = await SharedPreferences.getInstance();
    return SellerRepositoryImpl(SellerRemoteDataSource(DioClient(preferences)));
  }
}
