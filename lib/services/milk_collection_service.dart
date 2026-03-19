import '../config/api_config.dart';
import '../models/milk_collection_model.dart';
import 'api_service.dart';

class MilkCollectionService {
  // Create milk collection
  Future<MilkCollectionModel> createMilkCollection(
    CreateMilkCollectionRequest request,
    String token,
  ) async {
    try {
      final response = await ApiService.post(
        endpoint: '/milk/collection',
        body: request.toJson(),
        token: token,
      );

      if (response['data'] != null) {
        return MilkCollectionModel.fromJson(response['data']);
      } else {
        throw Exception('No data in response');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get all milk collections
  Future<List<MilkCollectionModel>> getAllCollections(String token) async {
    try {
      final response = await ApiService.get(
        endpoint: '/milk/collections',
        token: token,
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => MilkCollectionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get milk collections by farmer
  Future<List<MilkCollectionModel>> getCollectionsByFarmer(
    int farmerID,
    String token,
  ) async {
    try {
      final response = await ApiService.get(
        endpoint: '/milk/farmer/$farmerID',
        token: token,
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => MilkCollectionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get milk collections by collector
  Future<List<MilkCollectionModel>> getCollectionsByCollector(
    int collectorID,
    String token,
  ) async {
    try {
      final response = await ApiService.get(
        endpoint: '/milk/collector/$collectorID',
        token: token,
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => MilkCollectionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get farmer milk summary
  Future<Map<String, dynamic>> getFarmerSummary(
    int farmerID,
    String token,
  ) async {
    try {
      final response = await ApiService.get(
        endpoint: '/milk/farmer/$farmerID/summary',
        token: token,
      );

      return response['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  // ── Get collections by date range ────────────────────────────────────────
  // Calls GET /milk/collections/date-range?startDate=...&endDate=...
  Future<List<MilkCollectionModel>> getCollectionsByDateRange(
    String startDate,
    String endDate,
    String token,
  ) async {
    try {
      final response = await ApiService.get(
        endpoint:
            '/milk/collections/date-range?startDate=$startDate&endDate=$endDate',
        token: token,
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => MilkCollectionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
