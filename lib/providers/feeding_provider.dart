import 'package:flutter/material.dart';
import '../models/feeding_habit_model.dart';
import '../services/feeding_service.dart';

class FeedingProvider with ChangeNotifier {
  final FeedingService _service = FeedingService();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<FeedingHabitModel> _feedingHistory = [];
  FeedingHabitModel? _selectedFeeding;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FeedingHabitModel> get feedingHistory => _feedingHistory;
  FeedingHabitModel? get selectedFeeding => _selectedFeeding;

  // ── Internals ─────────────────────────────────────────────────────────────
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

  // ── Create feeding habit ──────────────────────────────────────────────────
  Future<FeedingHabitModel?> createFeedingHabit(
    CreateFeedingHabitRequest request,
    String token,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _service.createFeedingHabit(request, token);
      // Add to top of local list
      _feedingHistory.insert(0, result);
      _setLoading(false);
      notifyListeners();
      return result;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  // ── Get feeding history by farmer ─────────────────────────────────────────
  Future<void> getFeedingByFarmer(int farmerID, String token) async {
    _setLoading(true);
    _setError(null);

    try {
      _feedingHistory = await _service.getFeedingByFarmer(farmerID, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Get feeding by specific date ──────────────────────────────────────────
  Future<List<FeedingHabitModel>> getFeedingByDate(
    int farmerID,
    String date,
    String token,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final results = await _service.getFeedingByDate(farmerID, date, token);
      _setLoading(false);
      notifyListeners();
      return results;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return [];
    }
  }

  // ── Clear history (e.g. on logout or screen change) ───────────────────────
  void clearFeedingHistory() {
    _feedingHistory = [];
    _selectedFeeding = null;
    notifyListeners();
  }
}
