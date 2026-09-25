import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';

/// Reached from Sign In's "Forgot password?" link. Uses the existing
/// server-side /reset_password endpoint (already wired up in
/// CycleProvider.resetPassword) -- this screen was the missing piece,
/// since Sign In's button previously had an empty onPressed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isDone = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorText = 'Please enter a valid email address.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final error = await context.read<CycleProvider>().resetPassword(
      email: email,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorText = error;
        _isSubmitting = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = false;
      _isDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Reset Password', style: AppTextStyles.serif(size: 24)),
              const SizedBox(height: 8),
              Text(
                _isDone
                    ? 'Your password has been updated.'
                    : 'Enter your email and choose a new password.',
                style: AppTextStyles.sans(
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              if (_isDone) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Sign In',
                      style: AppTextStyles.sans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Email',
                  style: AppTextStyles.sans(size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                Text(
                  'New Password',
                  style: AppTextStyles.sans(size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _newPasswordController,
                  hint: 'At least 6 characters',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirm New Password',
                  style: AppTextStyles.sans(size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _confirmController,
                  hint: 'Re-enter new password',
                  obscureText: _obscurePassword,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    style: AppTextStyles.sans(
                      size: 12,
                      color: AppColors.periodRed,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleReset,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Reset Password',
                            style: AppTextStyles.sans(
                              size: 14,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTextStyles.sans(size: 14),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.sans(
            size: 13,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
