import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/auth_service.dart';

abstract class AuthEvent {}
class CheckSession extends AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}
class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  RegisterRequested({required this.name, required this.email, required this.password});
}
class PasswordResetRequestEvent extends AuthEvent {
  final String email;
  PasswordResetRequestEvent({required this.email});
}
class ResetPasswordEvent extends AuthEvent {
  final String token;
  final String newPassword;
  ResetPasswordEvent({required this.token, required this.newPassword});
}
class LogoutRequested extends AuthEvent {}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
class AuthMessageSent extends AuthState {
  final String message;
  AuthMessageSent(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial()) {
    on<CheckSession>((event, emit) async {
      emit(AuthLoading());
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      final success = await _authService.login(email: event.email, password: event.password);
      if (success) {
        emit(Authenticated());
      } else {
        emit(AuthError('Invalid credentials'));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await _authService.register(name: event.name, email: event.email, password: event.password);
      if (result != null) {
        if (result.containsKey('error')) {
          emit(AuthError(result['error']));
        } else {
          emit(AuthMessageSent('Registration successful! Please login.'));
          emit(Unauthenticated());
        }
      } else {
        emit(AuthError('Registration failed'));
      }
    });

    on<PasswordResetRequestEvent>((event, emit) async {
      emit(AuthLoading());
      final success = await _authService.requestPasswordReset(email: event.email);
      if (success) {
        emit(AuthMessageSent('Password reset link sent!'));
      } else {
        emit(AuthError('Failed to initiate password reset'));
      }
    });

    on<ResetPasswordEvent>((event, emit) async {
      emit(AuthLoading());
      final success = await _authService.resetPassword(token: event.token, newPassword: event.newPassword);
      if (success) {
        emit(AuthMessageSent('Password updated successfully!'));
      } else {
        emit(AuthError('Failed to reset password'));
      }
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await _authService.logout();
      emit(Unauthenticated());
    });
  }
}
