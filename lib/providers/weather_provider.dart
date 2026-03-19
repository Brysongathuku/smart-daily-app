import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _service = WeatherService();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  List<WeatherModel> _weatherHistory = [];
  WeatherModel? _selectedDayWeather;
  LiveWeatherModel? _currentWeather;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WeatherModel> get weatherHistory => _weatherHistory;
  WeatherModel? get selectedDayWeather => _selectedDayWeather;
  LiveWeatherModel? get currentWeather => _currentWeather;

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

  // ── Get all weather history for a farmer ──────────────────────────────────
  Future<void> getWeatherByFarmer(int farmerID, String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _weatherHistory = await _service.getWeatherByFarmer(farmerID, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Get weather for a specific date ───────────────────────────────────────
  Future<void> getWeatherByDate(
    int farmerID,
    String date,
    String token,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedDayWeather =
          await _service.getWeatherByDate(farmerID, date, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Get live current weather ──────────────────────────────────────────────
  Future<void> getCurrentWeather(int farmerID, String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentWeather = await _service.getCurrentWeather(farmerID, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      // Fail silently — weather widget should not crash the screen
      _setLoading(false);
      notifyListeners();
    }
  }

  // ── Fetch + save today's weather ──────────────────────────────────────────
  Future<WeatherModel?> fetchAndSaveWeather(
    int farmerID,
    String token,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _service.fetchAndSaveWeather(farmerID, token);
      if (result != null) {
        _selectedDayWeather = result;
        // Add to history if not already present
        final exists =
            _weatherHistory.any((w) => w.recordDate == result.recordDate);
        if (!exists) _weatherHistory.insert(0, result);
      }
      _setLoading(false);
      notifyListeners();
      return result;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  // ── Clear on logout ───────────────────────────────────────────────────────
  void clearWeatherData() {
    _weatherHistory = [];
    _selectedDayWeather = null;
    _currentWeather = null;
    notifyListeners();
  }
}
