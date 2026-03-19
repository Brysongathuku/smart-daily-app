import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/constants.dart';

class WeatherService {
  final String _baseUrl = AppConstants.baseUrl;

  // ── Get all weather records for a farmer ──────────────────────────────────
  Future<List<WeatherModel>> getWeatherByFarmer(
    int farmerID,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/weather/farmer/$farmerID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => WeatherModel.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return []; // No records yet — not an error
    } else {
      throw Exception('Failed to fetch weather records');
    }
  }

  // ── Get weather for a specific date ───────────────────────────────────────
  Future<WeatherModel?> getWeatherByDate(
    int farmerID,
    String date,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/weather/farmer/$farmerID/date/$date'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return WeatherModel.fromJson(json['data']);
    } else if (response.statusCode == 404) {
      return null; // No record for this date
    } else {
      throw Exception('Failed to fetch weather for date');
    }
  }

  // ── Get live current weather (not saved to DB) ────────────────────────────
  Future<LiveWeatherModel?> getCurrentWeather(
    int farmerID,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/weather/current/$farmerID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return LiveWeatherModel.fromJson(json['data']);
    } else {
      return null; // Fail silently — weather is not critical
    }
  }

  // ── Trigger fetch + save for today ────────────────────────────────────────
  Future<WeatherModel?> fetchAndSaveWeather(
    int farmerID,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/weather/fetch/$farmerID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return WeatherModel.fromJson(json['data']);
    } else {
      return null;
    }
  }
}
