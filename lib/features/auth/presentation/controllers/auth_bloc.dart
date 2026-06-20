import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

// ----------------------------- Events -----------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  const AuthSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [name, email, password, confirmPassword];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

// ----------------------------- States -----------------------------

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSignupSuccess extends AuthState {
  const AuthSignupSuccess();
}

class AuthLoginSuccess extends AuthState {
  final User user;

  const AuthLoginSuccess(this.user);

  @override
  List<Object?> get props => [user.uid];
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ----------------------------- Bloc -----------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignupUsecase signupUsecase;
  final LoginUsecase loginUsecase;
  final LogoutUsecase logoutUsecase;

  AuthBloc({
    required this.signupUsecase,
    required this.loginUsecase,
    required this.logoutUsecase,
  }) : super(const AuthInitial()) {
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthErrorCleared>((event, emit) => emit(const AuthInitial()));
  }

  Future<void> _onSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.name.trim().isEmpty) {
      emit(const AuthFailure('Name is required'));
      return;
    }
    if (!event.email.contains('@')) {
      emit(const AuthFailure('Enter a valid email address'));
      return;
    }
    if (event.password.length < 6) {
      emit(const AuthFailure('Password must be at least 6 characters'));
      return;
    }
    if (event.password != event.confirmPassword) {
      emit(const AuthFailure('Passwords do not match'));
      return;
    }

    emit(const AuthLoading());
    try {
      await signupUsecase(
        name: event.name.trim(),
        email: event.email.trim(),
        password: event.password.trim(),
      );
      emit(const AuthSignupSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    } catch (e) {
      emit(const AuthFailure('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.email.contains('@')) {
      emit(const AuthFailure('Enter a valid email'));
      return;
    }
    if (event.password.isEmpty) {
      emit(const AuthFailure('Password is required'));
      return;
    }

    emit(const AuthLoading());
    try {
      final credential = await loginUsecase(
        email: event.email.trim(),
        password: event.password.trim(),
      );
      final user = credential.user;
      if (user == null) {
        emit(const AuthFailure('Login failed. Please try again.'));
        return;
      }
      emit(AuthLoginSuccess(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    } catch (e) {
      emit(const AuthFailure('An unexpected error occurred.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await logoutUsecase();
      emit(const AuthLoggedOut());
    } catch (e) {
      emit(const AuthFailure('Failed to log out. Please try again.'));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    if (e.code == 'user-not-found' ||
        e.code == 'invalid-credential' ||
        e.code == 'wrong-password') {
      return 'Invalid email or password. Please try again.';
    } else if (e.code == 'too-many-requests') {
      return 'Too many attempts. Please try again later.';
    } else if (e.code == 'email-already-in-use') {
      return 'An account already exists for this email.';
    } else if (e.code == 'weak-password') {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (e.message != null) {
      return e.message!;
    }
    return 'An error occurred. Please try again.';
  }
}
