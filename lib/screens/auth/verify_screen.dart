import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_response_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import 'login_screen.dart';

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final verifyRequest = VerifyRequest(
      email: widget.email,
      code: _codeController.text.trim(),
    );

    final success = await authProvider.verify(verifyRequest);

    if (success) {
      if (!mounted) return;

      showSnackBar(
        context,
        'Account verified successfully! You can now login.',
      );

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      showSnackBar(
        context,
        authProvider.errorMessage ?? 'Verification failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Verify Account'),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: LoadingOverlay(
            isLoading: authProvider.isLoading,
            message: 'Verifying...',
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Verification Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail_outline,
                          size: 80,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We\'ve sent a 6-digit verification code to:',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Verification Code Field
                      CustomTextField(
                        controller: _codeController,
                        label: 'Verification Code',
                        hint: 'Enter 6-digit code',
                        prefixIcon: Icons.security,
                        keyboardType: TextInputType.number,
                        validator: Validators.validateVerificationCode,
                      ),
                      const SizedBox(height: 24),
                      // Verify Button
                      CustomButton(
                        text: 'Verify',
                        onPressed: _handleVerify,
                        isLoading: authProvider.isLoading,
                        backgroundColor: AppConstants.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      // Resend Code (you can implement this later)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement resend verification code
                              showSnackBar(
                                context,
                                'Resend feature coming soon!',
                              );
                            },
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Back to Login
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
