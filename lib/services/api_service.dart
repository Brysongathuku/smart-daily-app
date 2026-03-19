import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // POST Request
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('POST Request to: $url');
      print('Body: ${jsonEncode(body)}');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectTimeout);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } on Exception catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // GET Request
  static Future<Map<String, dynamic>> get({
    required String endpoint,
    String? token,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('GET Request to: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } on Exception catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // PUT Request
  static Future<Map<String, dynamic>> put({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } on Exception catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // DELETE Request
  static Future<Map<String, dynamic>> delete({
    required String endpoint,
    String? token,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .delete(url, headers: headers)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Failed to connect to server. Please try again.');
    } on Exception catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Handle HTTP Response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (response.body.isEmpty) {
      throw Exception('Empty response from server');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Invalid response format from server');
    }

    if (statusCode >= 200 && statusCode < 300) {
      // Success
      return data;
    } else if (statusCode == 400) {
      // Bad Request
      throw Exception(data['message'] ?? 'Invalid request');
    } else if (statusCode == 401) {
      // Unauthorized
      throw Exception(data['message'] ?? 'Invalid credentials');
    } else if (statusCode == 403) {
      // Forbidden
      throw Exception(data['message'] ?? 'Access denied');
    } else if (statusCode == 404) {
      // Not Found
      throw Exception(data['message'] ?? 'Resource not found');
    } else if (statusCode == 500) {
      // Server Error
      throw Exception(data['error'] ?? 'Server error. Please try again later.');
    } else {
      throw Exception(data['message'] ?? 'Something went wrong');
    }
  }
}
