import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ Added for MediaType
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ProfileService {
  final String _baseUrl = AppConstants.baseUrl;

  // ✅ FIXED: Uses XFile + readAsBytes() — works on Web AND Mobile
  Future<UserModel> updateProfile({
    required int userId,
    required String token,
    String? firstName,
    String? lastName,
    String? contactPhone,
    String? address,
    String? farmLocation,
    String? farmSize,
    int? numberOfCows,
    XFile? profileImage,
  }) async {
    final uri = Uri.parse('$_baseUrl/customer/$userId');

    // ✅ Always use multipart request (backend expects multipart/form-data)
    final request = http.MultipartRequest('PUT', uri);

    // Add auth header
    request.headers['Authorization'] = 'Bearer $token';

    // Add text fields (only if provided)
    if (firstName != null) request.fields['firstName'] = firstName;
    if (lastName != null) request.fields['lastName'] = lastName;
    if (contactPhone != null) request.fields['contactPhone'] = contactPhone;
    if (address != null) request.fields['address'] = address;
    if (farmLocation != null) request.fields['farmLocation'] = farmLocation;
    if (farmSize != null) request.fields['farmSize'] = farmSize;
    if (numberOfCows != null) {
      request.fields['numberOfCows'] = numberOfCows.toString();
    }

    // ✅ Attach image with explicit content type — fixes Flutter Web mimetype issue
    if (profileImage != null) {
      final Uint8List bytes = await profileImage.readAsBytes();
      final filename = profileImage.name.isNotEmpty
          ? profileImage.name
          : 'profile.jpg';

      // ✅ Detect mime type from extension (Flutter Web sends octet-stream otherwise)
      String mimeType = 'image/jpeg';
      final ext = filename.split('.').last.toLowerCase();
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'profileImage',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType), // ✅ Explicit mime type
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('Update profile status: ${response.statusCode}');
    debugPrint('Update profile body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['data']);
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? json['message'] ?? 'Failed to update profile');
    }
  }

  // Change password
  Future<void> changePassword({
    required int userId,
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/customer/$userId/password');

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? json['message'] ?? 'Failed to change password');
    }
  }
}