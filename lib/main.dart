import 'package:auth_notes_manager/core/theme/app_theme.dart';
import 'package:auth_notes_manager/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auth_notes_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auth_notes_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:auth_notes_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:auth_notes_manager/features/auth/domain/usecases/signup_usecase.dart';
import 'package:auth_notes_manager/features/auth/presentation/controllers/auth_bloc.dart';
import 'package:auth_notes_manager/features/auth/presentation/screen/login_screen.dart';
import 'package:auth_notes_manager/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
    );

    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        signupUsecase: SignupUsecase(authRepository),
        loginUsecase: LoginUsecase(authRepository),
        logoutUsecase: LogoutUsecase(authRepository),
      ),
      child: MaterialApp(
        title: 'Authentication & Notes Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );
  }
}
