import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';

class ResetPasswordScreen
    extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final otpController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  Future<void> _reset() async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the 6-digit OTP',
          ),
        ),
      );

      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 6 characters',
          ),
        ),
      );

      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match',
          ),
        ),
      );

      return;
    }

    final provider =
        context.read<AuthProvider>();

    final success =
        await provider.resetPassword(
      email: widget.email,
      otp: otpController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset successfully',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                'Password reset failed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.lock_reset,
              size: 80,
            ),

            const SizedBox(height: 20),

            Text(
              'OTP sent to ${widget.email}',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            AuthTextField(
              controller: otpController,
              label: 'OTP',
              hint: 'Enter 6-digit OTP',
              icon: Icons.pin,
              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller: passwordController,
              label: 'New Password',
              hint: 'Enter new password',
              icon: Icons.lock,
              obscureText: true,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller:
                  confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm new password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),

            const SizedBox(height: 24),

            AuthButton(
              text: 'RESET PASSWORD',
              loading: loading,
              onPressed: _reset,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}