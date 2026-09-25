import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import 'sign_up_screen.dart';
import 'home_shell.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter both email and password.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorText = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final cycle = context.read<CycleProvider>();
    final error = await cycle.signIn(email: email, password: password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorText = error;
        _isSubmitting = false;
      });
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeShell()),
      (route) => false,
    );
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;
    String? debugCode;
    bool codeSent = false;
    bool isSubmitting = false;

    InputDecoration fieldDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.sans(size: 12, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reset Password',
            style: AppTextStyles.sans(size: 16, weight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  codeSent
                      ? 'Enter the verification code and choose a new password.'
                      : 'Enter your email to request a verification code.',
                  style: AppTextStyles.sans(
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Email',
                  style: AppTextStyles.sans(size: 12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  enabled: !codeSent,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.sans(size: 13),
                  cursorColor: AppColors.primary,
                  decoration: fieldDecoration('you@example.com'),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Verification Code',
                    style: AppTextStyles.sans(
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    style: AppTextStyles.sans(size: 13),
                    cursorColor: AppColors.primary,
                    decoration: fieldDecoration('8-digit code'),
                  ),
                  if (debugCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Development code: $debugCode',
                      style: AppTextStyles.sans(
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'New Password',
                    style: AppTextStyles.sans(
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: AppTextStyles.sans(size: 13),
                    cursorColor: AppColors.primary,
                    decoration: fieldDecoration('Min. 6 characters'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confirm Password',
                    style: AppTextStyles.sans(
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    style: AppTextStyles.sans(size: 13),
                    cursorColor: AppColors.primary,
                    decoration: fieldDecoration('Re-enter new password'),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: AppTextStyles.sans(
                      size: 11,
                      color: AppColors.periodRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AppTextStyles.sans(
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (!codeSent) {
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(
                            () => errorText =
                                'Please enter a valid email address.',
                          );
                          return;
                        }
                        setDialogState(() {
                          errorText = null;
                          isSubmitting = true;
                        });
                        final result = await ctx
                            .read<CycleProvider>()
                            .requestPasswordReset(email: email);
                        if (!ctx.mounted) return;
                        if (result.error != null) {
                          setDialogState(() {
                            errorText = result.error;
                            isSubmitting = false;
                          });
                          return;
                        }
                        setDialogState(() {
                          codeSent = true;
                          debugCode = result.debugCode;
                          if (result.debugCode != null) {
                            codeController.text = result.debugCode!;
                          }
                          isSubmitting = false;
                        });
                        return;
                      }

                      final code = codeController.text.trim();
                      final password = passwordController.text;
                      final confirm = confirmController.text;
                      if (!RegExp(r'^\d{8}$').hasMatch(code)) {
                        setDialogState(
                          () => errorText =
                              'Enter the 8-digit verification code.',
                        );
                        return;
                      }
                      if (password.length < 6) {
                        setDialogState(
                          () => errorText =
                              'Password must be at least 6 characters.',
                        );
                        return;
                      }
                      if (password != confirm) {
                        setDialogState(
                          () => errorText = 'Passwords do not match.',
                        );
                        return;
                      }
                      setDialogState(() {
                        errorText = null;
                        isSubmitting = true;
                      });
                      final error = await ctx
                          .read<CycleProvider>()
                          .confirmPasswordReset(
                            email: email,
                            code: code,
                            newPassword: password,
                          );
                      if (!ctx.mounted) return;
                      if (error != null) {
                        setDialogState(() {
                          errorText = error;
                          isSubmitting = false;
                        });
                        return;
                      }
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Password reset successful. Please sign in with your new password.',
                            style: AppTextStyles.sans(size: 13),
                          ),
                          backgroundColor: AppColors.ovulationTeal,
                        ),
                      );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      codeSent ? 'Reset Password' : 'Send Code',
                      style: AppTextStyles.sans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Wellness ',
                        style: AppTextStyles.serif(
                          size: 24,
                          weight: FontWeight.w600,
                          color: AppColors.accent,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(
                        text: 'Saheli',
                        style: AppTextStyles.serif(
                          size: 24,
                          weight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Welcome back. Sign in to continue.',
                  style: AppTextStyles.sans(
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 36),
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
                'Password',
                style: AppTextStyles.sans(size: 12, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'Enter your password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showResetPasswordDialog,
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.sans(
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                  onPressed: _isSubmitting ? null : _handleSignIn,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: AppTextStyles.sans(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.sans(
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.sans(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
