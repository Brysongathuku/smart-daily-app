import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NotificationService {
  final String _baseUrl = AppConstants.baseUrl;

  // ── Get unread count ───────────────────────────────────────────────────
  Future<int> getUnreadCount(int farmerID, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread/$farmerID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['unreadCount'] ?? 0;
    }
    return 0;
  }

  // ── Reset unread count ─────────────────────────────────────────────────
  Future<void> resetUnreadCount(int farmerID, String token) async {
    await http.put(
      Uri.parse('$_baseUrl/notifications/reset/$farmerID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
