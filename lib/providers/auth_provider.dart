import 'package:flutter/material.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null && _token != null;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Register User
  Future<bool> register(RegisterRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.register(request);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Verify User
  Future<bool> verify(VerifyRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.verify(request);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Login User
  Future<bool> login(LoginRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(request);

      if (response.token != null && response.user != null) {
        _token = response.token;
        _currentUser = response.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setLoading(false);
        _setError('Invalid response from server');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Load saved user data on app start
  Future<void> loadSavedUser() async {
    _setLoading(true);

    try {
      final userData = await _authService.getCurrentUserData();

      if (userData != null) {
        _token = userData['token'];
        _currentUser = userData['user'];
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      print('Error loading saved user: $e');
    }
  }

  // ✅ ADDED: Update current user directly from API response after profile update.
  // This avoids loadSavedUser() which reads stale cached data and loses the new imageUrl.
  void updateCurrentUser(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _token = null;
    notifyListeners();
  }

  // Check if user is farmer
  bool get isFarmer => _currentUser?.isFarmer ?? false;

  // Check if user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;
}