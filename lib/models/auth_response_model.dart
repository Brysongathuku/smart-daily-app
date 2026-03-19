import 'user_model.dart';

class AuthResponse {
  final String message;
  final String? token;
  final UserModel? user;

  AuthResponse({
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? contactPhone;
  final String? address;
  final String role; // 'user' (farmer) or 'admin'

  // Farmer-specific fields
  final String? farmLocation;
  final String? farmSize;
  final int? numberOfCows;
  final String? cowBreed; // ← NEW: comma-separated e.g. "Friesian, Ayrshire"

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.contactPhone,
    this.address,
    this.role = 'user',
    this.farmLocation,
    this.farmSize,
    this.numberOfCows,
    this.cowBreed, // ← NEW
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'role': role,
    };

    if (contactPhone != null && contactPhone!.isNotEmpty) {
      data['contactPhone'] = contactPhone;
    }
    if (address != null && address!.isNotEmpty) {
      data['address'] = address;
    }

    // Farmer-specific fields
    if (role == 'user') {
      if (farmLocation != null && farmLocation!.isNotEmpty) {
        data['farmLocation'] = farmLocation;
      }
      if (farmSize != null && farmSize!.isNotEmpty) {
        data['farmSize'] = farmSize;
      }
      if (numberOfCows != null) {
        data['numberOfCows'] = numberOfCows;
      }
      if (cowBreed != null && cowBreed!.isNotEmpty) {
        data['cowBreed'] = cowBreed; // ← NEW
      }
    }

    return data;
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class VerifyRequest {
  final String email;
  final String code;

  VerifyRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'verificationCode': code,
    };
  }
}
