import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> signUp(String name, String email, String password);
  Future<UserCredential> logIn(String email, String password);
  Future<void> logOut();
}