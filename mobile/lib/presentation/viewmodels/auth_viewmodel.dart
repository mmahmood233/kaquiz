// This ViewModel sits between the auth screens and AuthRepository.
// Screens call these methods, then this class calls the backend through the repository.
import 'package:flutter/foundation.dart';

// AuthRepository contains the actual HTTP calls to /api/auth and /api/users.
import '../../data/repositories/auth_repository.dart';

// UserModel stores the user object returned by the backend.
import '../../data/models/user_model.dart';

// The UI reads this state to know whether to show loading, errors, or the app.
enum AuthState { initial, loading, authenticated, unauthenticated, error }

// AuthViewModel keeps the current logged-in user in memory.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Private values can only be changed from inside this ViewModel.
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  UserModel? _currentUser;

  // Screens read these values but cannot change them directly.
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  // Runs on app start.
  // It checks local storage first, then asks the backend if the token is valid.
  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authRepository.isLoggedIn();

    // No token on the device means the user must sign in again.
    if (!isLoggedIn) {
      _currentUser = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    // GET /api/auth/me confirms that the saved token still belongs to a user.
    final response = await _authRepository.getMe();
    if (response.success && response.data != null) {
      _currentUser = response.data;
      _state = AuthState.authenticated;
    } else {
      // Bad or expired tokens are removed so the app does not keep retrying them.
      await _authRepository.logout();
      _currentUser = null;
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Called by RegisterScreen.
  // It sends the new email/password to the backend and updates the UI state.
  Future<bool> register(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.register(email, password);

    // If the backend created the account, keep the returned user in memory.
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

  // Called by LoginScreen.
  // It sends credentials to the backend and returns true when login works.
  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.login(email, password);

    // If the backend accepts the login, store the returned user in memory.
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

  // Called by ProfileScreen when the user edits their display name.
  // The repository sends the change to the backend, then we update local state.
  Future<bool> updateProfile(String name) async {
    _errorMessage = null;
    notifyListeners();

    final response = await _authRepository.updateProfile(name);
    if (response.success && response.data != null) {
      // The backend returns the updated user, so the profile screen refreshes.
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

  // Called on logout.
  // It clears secure storage and tells the app to return to the login screen.
  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
