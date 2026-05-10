// ChangeNotifier lets screens rebuild when auth state changes.
import 'package:flutter/foundation.dart';

// Repository talks to backend auth endpoints.
import '../../data/repositories/auth_repository.dart';

// Current user model.
import '../../data/models/user_model.dart';

// Possible authentication states for the UI.
enum AuthState { initial, loading, authenticated, unauthenticated, error }

// AuthViewModel holds auth state for login/register/profile screens.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Private state values.
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  UserModel? _currentUser;

  // Public read-only state values.
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  // Check if a saved token exists and is still valid.
  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();

    // No saved token means user is logged out.
    if (!isLoggedIn) {
      _currentUser = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    // Validate token by asking backend for current user.
    final response = await _authRepository.getMe();
    if (response.success && response.data != null) {
      _currentUser = response.data;
      _state = AuthState.authenticated;
    } else {
      // Bad or expired token is cleared.
      await _authRepository.logout();
      _currentUser = null;
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Register and update UI state.
  Future<bool> register(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.register(email, password);

    // Save user in memory if backend created the account.
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

  // Login and update UI state.
  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.login(email, password);

    // Save user in memory if backend accepted the login.
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

  // Update the user's display name.
  Future<bool> updateProfile(String name) async {
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.updateProfile(name);
    if (response.success && response.data != null) {
      // Backend returns updated user data.
      final userData = response.data!['user'] ?? response.data;
      if (userData != null) {
        _currentUser = UserModel.fromJson(userData as Map<String, dynamic>);
      }
      notifyListeners();
      return true;
    }
    _errorMessage = response.message ?? 'Update failed';
    notifyListeners();
    return false;
  }

  // Clear saved token and reset auth state.
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
