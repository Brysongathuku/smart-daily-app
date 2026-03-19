import 'package:flutter/material.dart';
import '../models/recommendation_model.dart';
import '../services/gemini_service.dart';

class GeminiProvider with ChangeNotifier {
  final GeminiService _service = GeminiService();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  RecommendationModel? _recommendation;
  int? _lastFarmerID;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RecommendationModel? get recommendation => _recommendation;
  bool get hasData => _recommendation != null;

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

  // ── Get recommendations ────────────────────────────────────────────────────
  Future<void> getRecommendations(int farmerID, String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _recommendation = await _service.getRecommendations(farmerID, token);
      _lastFarmerID = farmerID;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Refresh — force new recommendations ───────────────────────────────────
  Future<void> refresh(int farmerID, String token) async {
    _recommendation = null; // clear old data first
    notifyListeners();
    await getRecommendations(farmerID, token);
  }

  // ── Clear on logout ────────────────────────────────────────────────────────
  void clearRecommendations() {
    _recommendation = null;
    _lastFarmerID = null;
    _errorMessage = null;
    notifyListeners();
  }
}
