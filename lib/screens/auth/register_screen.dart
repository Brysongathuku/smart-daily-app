import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/auth_response_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _numberOfCowsController = TextEditingController();

  String _selectedRole = AppConstants.roleFarmer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedFarmSize;

  // ── Multi-breed selection ──────────────────────────────────────────────────
  static const List<String> _allBreeds = [
    'Friesian',
    'Ayrshire',
    'Jersey',
    'Guernsey',
    'Brown Swiss',
    'Holstein',
    'Sahiwal',
    'Crossbreed',
    'Other',
  ];
  final Set<String> _selectedBreeds = {};

  String get _breedsDisplayText {
    if (_selectedBreeds.isEmpty) return 'Select cow breed(s)';
    return _selectedBreeds.join(', ');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    _numberOfCowsController.dispose();
    super.dispose();
  }

  // ── Breed picker bottom sheet ──────────────────────────────────────────────
  void _showBreedPicker() {
    // Temp copy so cancel doesn't affect state
    final tempSelected = Set<String>.from(_selectedBreeds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.pets,
                            color: AppConstants.primaryColor),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Select Cow Breed(s)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Clear all
                        if (tempSelected.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setSheetState(() => tempSelected.clear());
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Breed list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allBreeds.length,
                      itemBuilder: (ctx, index) {
                        final breed = _allBreeds[index];
                        final isSelected = tempSelected.contains(breed);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setSheetState(() {
                              if (checked == true) {
                                tempSelected.add(breed);
                              } else {
                                tempSelected.remove(breed);
                              }
                            });
                          },
                          title: Text(
                            breed,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          secondary: CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected
                                ? AppConstants.primaryColor.withOpacity(0.15)
                                : Colors.grey[100],
                            child: Text(
                              breed[0],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppConstants.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          activeColor: AppConstants.primaryColor,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // Confirm button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedBreeds
                              ..clear()
                              ..addAll(tempSelected);
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          tempSelected.isEmpty
                              ? 'Confirm (None selected)'
                              : 'Confirm ${tempSelected.length} breed${tempSelected.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      showSnackBar(context, 'Passwords do not match', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final registerRequest = RegisterRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      contactPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      role: _selectedRole,
      farmLocation: _selectedRole == AppConstants.roleFarmer &&
              _farmLocationController.text.trim().isNotEmpty
          ? _farmLocationController.text.trim()
          : null,
      farmSize:
          _selectedRole == AppConstants.roleFarmer && _selectedFarmSize != null
              ? _selectedFarmSize
              : null,
      numberOfCows: _selectedRole == AppConstants.roleFarmer &&
              _numberOfCowsController.text.trim().isNotEmpty
          ? int.tryParse(_numberOfCowsController.text.trim())
          : null,
      // Send breeds as comma-separated string, or null if none selected
      cowBreed:
          _selectedRole == AppConstants.roleFarmer && _selectedBreeds.isNotEmpty
              ? _selectedBreeds.join(', ')
              : null,
    );

    final success = await authProvider.register(registerRequest);

    if (success) {
      if (!mounted) return;
      showSnackBar(
        context,
        'Registration successful! Check your email for verification code.',
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      if (!mounted) return;
      showSnackBar(
        context,
        authProvider.errorMessage ?? 'Registration failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: LoadingOverlay(
            isLoading: authProvider.isLoading,
            message: 'Creating account...',
            child: Stack(
              children: [
                // Background Image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.pexels.com/photos/422218/pexels-photo-422218.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppConstants.primaryColor.withOpacity(0.85),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  child: Column(
                    children: [
                      // App Bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 500),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.97),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Join Smart Dairy',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fill in your details to get started',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 24),

                                    // Role Selection
                                    const Text(
                                      'I am a:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _selectedRole ==
                                                      AppConstants.roleFarmer
                                                  ? AppConstants.primaryColor
                                                      .withOpacity(0.1)
                                                  : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _selectedRole ==
                                                        AppConstants.roleFarmer
                                                    ? AppConstants.primaryColor
                                                    : Colors.grey[300]!,
                                                width: 2,
                                              ),
                                            ),
                                            child: RadioListTile<String>(
                                              title: const Text('Farmer'),
                                              value: AppConstants.roleFarmer,
                                              groupValue: _selectedRole,
                                              onChanged: (value) => setState(
                                                  () => _selectedRole = value!),
                                              activeColor:
                                                  AppConstants.primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _selectedRole ==
                                                      AppConstants.roleAdmin
                                                  ? AppConstants.primaryColor
                                                      .withOpacity(0.1)
                                                  : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _selectedRole ==
                                                        AppConstants.roleAdmin
                                                    ? AppConstants.primaryColor
                                                    : Colors.grey[300]!,
                                                width: 2,
                                              ),
                                            ),
                                            child: RadioListTile<String>(
                                              title: const Text('Collector'),
                                              value: AppConstants.roleAdmin,
                                              groupValue: _selectedRole,
                                              onChanged: (value) => setState(
                                                  () => _selectedRole = value!),
                                              activeColor:
                                                  AppConstants.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Personal Fields
                                    CustomTextField(
                                      controller: _firstNameController,
                                      label: 'First Name',
                                      hint: 'Enter your first name',
                                      prefixIcon: Icons.person_outline,
                                      validator: Validators.validateName,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _lastNameController,
                                      label: 'Last Name',
                                      hint: 'Enter your last name',
                                      prefixIcon: Icons.person_outline,
                                      validator: Validators.validateName,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: Validators.validateEmail,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      validator: Validators.validatePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      hint: 'Re-enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscureConfirmPassword,
                                      validator: (value) {
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined),
                                        onPressed: () => setState(() =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number (Optional)',
                                      hint: 'Enter your phone number',
                                      prefixIcon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: Validators.validatePhone,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _addressController,
                                      label: 'Address (Optional)',
                                      hint: 'Enter your address',
                                      prefixIcon: Icons.home_outlined,
                                      maxLines: 2,
                                    ),

                                    // ── Farmer-specific fields ────────────
                                    if (_selectedRole ==
                                        AppConstants.roleFarmer) ...[
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.agriculture,
                                                    color: AppConstants
                                                        .primaryColor,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Farm Information',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppConstants
                                                        .primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            CustomTextField(
                                              controller:
                                                  _farmLocationController,
                                              label: 'Farm Location (Optional)',
                                              hint: 'e.g., Nairobi County',
                                              prefixIcon:
                                                  Icons.location_on_outlined,
                                            ),
                                            const SizedBox(height: 16),
                                            DropdownButtonFormField<String>(
                                              value: _selectedFarmSize,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Farm Size (Optional)',
                                                prefixIcon: const Icon(
                                                    Icons.landscape_outlined),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              items: AppConstants.farmSizes
                                                  .map((size) {
                                                return DropdownMenuItem(
                                                  value: size,
                                                  child: Text(size),
                                                );
                                              }).toList(),
                                              onChanged: (value) => setState(
                                                  () => _selectedFarmSize =
                                                      value),
                                            ),
                                            const SizedBox(height: 16),
                                            CustomTextField(
                                              controller:
                                                  _numberOfCowsController,
                                              label:
                                                  'Number of Cows (Optional)',
                                              hint: 'Enter number of cows',
                                              prefixIcon: Icons.pets_outlined,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              validator:
                                                  Validators.validateNumber,
                                            ),
                                            const SizedBox(height: 16),

                                            // ── Cow Breed Multi-select ────
                                            const Text(
                                              'Cow Breed(s) (Optional)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: _showBreedPicker,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _selectedBreeds
                                                            .isNotEmpty
                                                        ? AppConstants
                                                            .primaryColor
                                                        : Colors.grey[400]!,
                                                    width: _selectedBreeds
                                                            .isNotEmpty
                                                        ? 2
                                                        : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.pets_outlined,
                                                      color: _selectedBreeds
                                                              .isNotEmpty
                                                          ? AppConstants
                                                              .primaryColor
                                                          : Colors.grey[500],
                                                      size: 22,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        _breedsDisplayText,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: _selectedBreeds
                                                                  .isNotEmpty
                                                              ? Colors.black87
                                                              : Colors
                                                                  .grey[500],
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Selected breed chips
                                            if (_selectedBreeds.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 6,
                                                children: _selectedBreeds
                                                    .map((breed) => Chip(
                                                          label: Text(
                                                            breed,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              color: AppConstants
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              AppConstants
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                      0.1),
                                                          deleteIconColor:
                                                              AppConstants
                                                                  .primaryColor,
                                                          onDeleted: () =>
                                                              setState(() =>
                                                                  _selectedBreeds
                                                                      .remove(
                                                                          breed)),
                                                          side: BorderSide(
                                                            color: AppConstants
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.3),
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ))
                                                    .toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 32),
                                    CustomButton(
                                      text: 'Register',
                                      onPressed: _handleRegister,
                                      isLoading: authProvider.isLoading,
                                      backgroundColor:
                                          AppConstants.primaryColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              color: AppConstants.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
