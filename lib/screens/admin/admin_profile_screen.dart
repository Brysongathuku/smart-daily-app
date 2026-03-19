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

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

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
        // ✅ Show initials while loading
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
                    const SizedBox(height: 8),
                    Text(
                      user?.fullName ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Personal Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person,
                                    color: AppConstants.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

                    // Account Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.admin_panel_settings,
                                    color: AppConstants.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Account Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.badge, 'Role', 'Administrator'),
                            const Divider(),
                            _buildInfoRow(
                                Icons.email, 'Email', user?.email ?? ''),
                            const Divider(),
                            _buildInfoRow(
                              Icons.verified_user,
                              'Status',
                              'Active',
                              valueColor: Colors.green,
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

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}