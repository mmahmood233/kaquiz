import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  UserModel? _currentUser;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    _state = isLoggedIn ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> register(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.register(email, password);

    if (response.success && response.data != null) {
      _currentUser = UserModel.fromJson(response.data!['user']);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Registration failed';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.login(email, password);

    if (response.success && response.data != null) {
      _currentUser = UserModel.fromJson(response.data!['user']);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Login failed';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
