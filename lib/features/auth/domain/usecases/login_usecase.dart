import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<UserCredential> call({
    required String email,
    required String password,
  }) {
    return repository.logIn(email, password);
  }
}
