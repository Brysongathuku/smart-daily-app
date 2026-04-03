class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? contactPhone;
  final String? address;
  final String? imageUrl;
  final String? farmLocation;
  final String? farmSize;
  final int? numberOfCows;
  final String? cowBreed;
  final int unreadNotifications; // ← NEW

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.contactPhone,
    this.address,
    this.imageUrl,
    this.farmLocation,
    this.farmSize,
    this.numberOfCows,
    this.cowBreed,
    this.unreadNotifications = 0, // ← NEW
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? json['customerID'] ?? json['customer_id'] ?? 0,
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      contactPhone: json['contact_phone'] ?? json['contactPhone'],
      address: json['address'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      farmLocation: json['farm_location'] ?? json['farmLocation'],
      farmSize: json['farm_size'] ?? json['farmSize'],
      numberOfCows: json['number_of_cows'] ?? json['numberOfCows'],
      cowBreed: json['cow_breed'] ?? json['cowBreed'],
      unreadNotifications: // ← NEW
          json['unread_notifications'] ?? json['unreadNotifications'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'contact_phone': contactPhone,
      'address': address,
      'image_url': imageUrl,
      'farm_location': farmLocation,
      'farm_size': farmSize,
      'number_of_cows': numberOfCows,
      'cow_breed': cowBreed,
      'unread_notifications': unreadNotifications, // ← NEW
    };
  }

  String get fullName => '$firstName $lastName';
  bool get isFarmer => role == 'user';
  bool get isAdmin => role == 'admin';

  List<String> get cowBreedList {
    if (cowBreed == null || cowBreed!.trim().isEmpty) return [];
    return cowBreed!.split(',').map((b) => b.trim()).toList();
  }

  String get cowBreedDisplay {
    if (cowBreedList.isEmpty) return 'Not specified';
    return cowBreedList.join(' + ');
  }
}
