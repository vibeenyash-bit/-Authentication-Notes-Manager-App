import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class SignupUsecase {
  final AuthRepository repository;

  SignupUsecase(this.repository);

  Future<UserCredential> call({
    required String name,
    required String email,
    required String password,
  }) {
    return repository.signUp(name, email, password);
  }
}
