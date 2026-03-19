import '../models/feeding_habit_model.dart';
import 'api_service.dart';

class FeedingService {
  Future<FeedingHabitModel> createFeedingHabit(
      CreateFeedingHabitRequest request, String token) async {
    final response = await ApiService.post(
      endpoint: '/feeding',
      body: request.toJson(),
      token: token,
    );
    return FeedingHabitModel.fromJson(response['data']);
  }

  Future<List<FeedingHabitModel>> getFeedingByFarmer(
      int farmerID, String token) async {
    final response = await ApiService.get(
      endpoint: '/feeding/farmer/$farmerID',
      token: token,
    );
    final list = response['data'] as List;
    return list.map((e) => FeedingHabitModel.fromJson(e)).toList();
  }

  Future<List<FeedingHabitModel>> getFeedingByDate(
      int farmerID, String date, String token) async {
    final response = await ApiService.get(
      endpoint: '/feeding/farmer/$farmerID/date/$date',
      token: token,
    );
    final list = response['data'] as List;
    return list.map((e) => FeedingHabitModel.fromJson(e)).toList();
  }
}
