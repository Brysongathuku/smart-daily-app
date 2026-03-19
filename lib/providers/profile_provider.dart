// ✅ No dart:io import — XFile works on Web + Mobile
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _service = ProfileService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ FIXED: profileImage is now XFile? instead of File?
  Future<bool> updateProfile({
    required int userId,
    required String token,
    String? firstName,
    String? lastName,
    String? contactPhone,
    String? address,
    String? farmLocation,
    String? farmSize,
    int? numberOfCows,
    XFile? profileImage, // ✅ XFile works on Web + Mobile
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _user = await _service.updateProfile(
        userId: userId,
        token: token,
        firstName: firstName,
        lastName: lastName,
        contactPhone: contactPhone,
        address: address,
        farmLocation: farmLocation,
        farmSize: farmSize,
        numberOfCows: numberOfCows,
        profileImage: profileImage,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required int userId,
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _service.changePassword(
        userId: userId,
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}