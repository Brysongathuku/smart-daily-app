import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Register User
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await ApiService.post(
        endpoint: ApiConfig.register,
        body: request.toJson(),
      );

      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Verify User
  Future<AuthResponse> verify(VerifyRequest request) async {
    try {
      final response = await ApiService.post(
        endpoint: ApiConfig.verify,
        body: request.toJson(),
      );

      return AuthResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Login User
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await ApiService.post(
        endpoint: ApiConfig.login,
        body: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response);

      // Save token and user data to local storage
      if (authResponse.token != null && authResponse.user != null) {
        await saveAuthData(authResponse.token!, authResponse.user!);
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Save auth data to local storage
  Future<void> saveAuthData(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get saved user data
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Get current user with token
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final token = await getToken();
    final user = await getSavedUser();

    if (token != null && user != null) {
      return {'token': token, 'user': user};
    }
    return null;
  }
}
