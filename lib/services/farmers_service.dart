import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class FarmersService {
  // Get all farmers
  Future<List<UserModel>> getAllFarmers(String token) async {
    try {
      final response = await ApiService.get(
        endpoint: ApiConfig.farmers,
        token: token,
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get farmer by ID
  Future<UserModel> getFarmerById(int id, String token) async {
    try {
      final response = await ApiService.get(
        endpoint: '/customer/$id',
        token: token,
      );

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
