// ✅ Removed: import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/image_picker_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({Key? key}) : super(key: key);

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _numberOfCowsController = TextEditingController();

  String? _selectedFarmSize;
  XFile? _profileImage;
  Uint8List? _imageBytes;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.contactPhone ?? '';
      _addressController.text = user.address ?? '';
      _farmLocationController.text = user.farmLocation ?? '';
      _numberOfCowsController.text = user.numberOfCows?.toString() ?? '';
      _selectedFarmSize = user.farmSize;
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePickerService.showImageSourceDialog(context);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImage = image;
        _imageBytes = bytes;
      });
    }
  }

  // ✅ FIX: Build full URL from relative or absolute imageUrl
  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    // Remove leading slash if present to avoid double slash
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '${AppConstants.baseUrl}$path';
  }

  // ✅ Web-safe image preview widget with full URL fix
  Widget _buildProfileImage(dynamic user) {
    if (_imageBytes != null) {
      // Newly picked image (works on web + mobile)
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }

    final resolvedUrl = _resolveImageUrl(user?.imageUrl);
    if (resolvedUrl != null) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        // ✅ Show spinner while loading
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppConstants.primaryColor,
              strokeWidth: 2,
            ),
          );
        },
        // ✅ Fallback to initials on error
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              user?.firstName[0].toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          );
        },
      );
    }

    // No image — show initials
    return Center(
      child: Text(
        user?.firstName[0].toUpperCase() ?? '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    final success = await profileProvider.updateProfile(
      userId: authProvider.currentUser!.userId,
      token: authProvider.token!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      farmLocation: _farmLocationController.text.trim(),
      farmSize: _selectedFarmSize,
      numberOfCows: _numberOfCowsController.text.isNotEmpty
          ? int.tryParse(_numberOfCowsController.text)
          : null,
      profileImage: _profileImage,
    );

    if (success && mounted) {
      // ✅ FIX: update AuthProvider directly with the fresh user from API response
      // loadSavedUser() reads old cached data — profileProvider.user has the new imageUrl
      if (profileProvider.user != null) {
        authProvider.updateCurrentUser(profileProvider.user!);
      } else {
        await authProvider.loadSavedUser();
      }
      showSnackBar(context, 'Profile updated successfully!');
      setState(() {
        _isEditing = false;
        _profileImage = null;
        _imageBytes = null;
      });
    } else if (mounted) {
      showSnackBar(
        context,
        profileProvider.errorMessage ?? 'Failed to update profile',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: LoadingOverlay(
            isLoading: profileProvider.isLoading,
            message: 'Updating profile...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              AppConstants.primaryColor.withOpacity(0.1),
                          child: ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: _buildProfileImage(user),
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hint: 'Enter first name',
                              prefixIcon: Icons.person_outline,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hint: 'Enter last name',
                              prefixIcon: Icons.person_outline,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller:
                                  TextEditingController(text: user?.email),
                              label: 'Email',
                              hint: 'Email',
                              prefixIcon: Icons.email_outlined,
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'Enter phone number',
                              prefixIcon: Icons.phone_outlined,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _addressController,
                              label: 'Address',
                              hint: 'Enter address',
                              prefixIcon: Icons.home_outlined,
                              maxLines: 2,
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Farm Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Farm Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _farmLocationController,
                              label: 'Farm Location',
                              hint: 'e.g., Nairobi County',
                              prefixIcon: Icons.location_on_outlined,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedFarmSize,
                              decoration: InputDecoration(
                                labelText: 'Farm Size',
                                prefixIcon:
                                    const Icon(Icons.landscape_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabled: _isEditing,
                              ),
                              items: AppConstants.farmSizes.map((size) {
                                return DropdownMenuItem(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                              onChanged: _isEditing
                                  ? (value) =>
                                      setState(() => _selectedFarmSize = value)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _numberOfCowsController,
                              label: 'Number of Cows',
                              hint: 'Enter number of cows',
                              prefixIcon: Icons.pets_outlined,
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _profileImage = null;
                                  _imageBytes = null;
                                  _loadUserData();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: 'Save Changes',
                              onPressed: _saveProfile,
                              backgroundColor: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _farmLocationController.dispose();
    _numberOfCowsController.dispose();
    super.dispose();
  }
}