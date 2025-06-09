import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:e_rents_desktop/widgets/auth/auth_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/providers/app_state_providers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  String? _errorMessage;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final rememberedEmail = await _storage.read(key: 'remembered_email');
    if (rememberedEmail != null) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        LoginRequestModel(
          usernameOrEmail: _emailController.text,
          password: _passwordController.text,
        ),
      );

      if (success) {
        if (_rememberMe) {
          await _storage.write(
            key: 'remembered_email',
            value: _emailController.text,
          );
        } else {
          await _storage.delete(key: 'remembered_email');
        }

        if (mounted) {
          context.go('/');
        }
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage;
        });
      }
    } catch (e, s) {
      final appError = AppError.fromException(e, s);

      setState(() {
        _errorMessage = appError.userMessage;
      });

      if (mounted) {
        context.read<AppErrorProvider>().setError(appError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      formWidget: _buildLoginForm(),
      customSideContent: _buildDefaultSideContent(context),
    );
  }

  Widget _buildDefaultSideContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apartment, size: 120, color: Colors.black54),
          const SizedBox(height: 24),
          Text(
            'eRents Property Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your properties with ease',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text('Remember Me'),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: _login,
                label: 'Login',
                isLoading: _isLoading,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.vertical,
                children: [
                  TextButton(
                    onPressed: () {
                      context.push('/signup');
                    },
                    child: const Text('Don\'t have an account? Sign up'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/forgot-password');
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
