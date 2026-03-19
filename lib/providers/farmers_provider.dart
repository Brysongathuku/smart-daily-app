import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/farmers_service.dart';

class FarmersProvider with ChangeNotifier {
  final FarmersService _service = FarmersService();

  List<UserModel> _farmers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get farmers => _farmers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // Get all farmers
  Future<void> getAllFarmers(String token) async {
    _setLoading(true);
    _setError(null);

    try {
      _farmers = await _service.getAllFarmers(token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Get farmer by ID
  Future<UserModel?> getFarmerById(int id, String token) async {
    try {
      return await _service.getFarmerById(id, token);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
}
