import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation_model.dart';
import '../utils/constants.dart';

class GeminiService {
  final String _baseUrl = AppConstants.baseUrl;

  // ── Get AI recommendations for a farmer ───────────────────────────────────
  Future<RecommendationModel> getRecommendations(
    int farmerID,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/gemini/recommendations/$farmerID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return RecommendationModel.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      final message = json['message'] ?? 'Failed to get recommendations';
      throw Exception(message);
    }
  }
}
