import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final formKey =
      GlobalKey<FormState>();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final provider =
        context.read<AuthProvider>();

    final success = await provider.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _navigateByRole(
        provider.user!.role,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                'Login failed',
          ),
        ),
      );
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case AppConstants.neighbour:
        Navigator.pushReplacementNamed(
          context,
          '/neighbour-dashboard',
        );
        break;

      case AppConstants.restaurantOwner:
        Navigator.pushReplacementNamed(
          context,
          '/restaurant-dashboard',
        );
        break;

      case AppConstants.driver:
        Navigator.pushReplacementNamed(
          context,
          '/driver-dashboard',
        );
        break;

      case AppConstants.recyclingManager:
        Navigator.pushReplacementNamed(
          context,
          '/recycling-manager-dashboard',
        );
        break;

      default:
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unknown user role',
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.recycling,
                    size: 90,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  AuthTextField(
                    controller:
                        emailController,
                    label: 'Email',
                    hint:
                        'Enter your email',
                    icon: Icons.email,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    validator:
                        (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Email is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  AuthTextField(
                    controller:
                        passwordController,
                    label: 'Password',
                    hint:
                        'Enter your password',
                    icon: Icons.lock,
                    obscureText: true,
                    validator:
                        (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Password is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment:
                        Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  AuthButton(
                    text: 'LOGIN',
                    loading: loading,
                    onPressed: _login,
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}