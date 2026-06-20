import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserCredential> signUp(String name, String email, String password) async {
    return await remoteDataSource.signUp(name: name, email: email, password: password);
  }

  @override
  Future<UserCredential> logIn(String email, String password) async {
    return await remoteDataSource.logIn(email: email, password: password);
  }

  @override
  Future<void> logOut() async {
    await remoteDataSource.logOut();
  }
}