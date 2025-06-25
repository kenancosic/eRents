import 'package:e_rents_desktop/features/auth/state/login_form_state.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:e_rents_desktop/features/auth/widgets/auth_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/providers/app_state_providers.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginFormState(context.read<AuthProvider>()),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginFormState>().loadRememberedCredentials(
        _emailController,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<LoginFormState>();
    final success = await state.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      if (state.rememberMe) {
        await _storage.write(
          key: 'remembered_email',
          value: _emailController.text,
        );
      } else {
        await _storage.delete(key: 'remembered_email');
      }
      context.go('/');
    } else if (!success && mounted) {
      context.read<AppErrorProvider>().setError(
        AppError(
          type: ErrorType.authentication,
          message: state.errorMessage ?? 'Login failed.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(formWidget: _buildLoginForm(context));
  }

  Widget _buildLoginForm(BuildContext context) {
    return Consumer<LoginFormState>(
      builder: (context, state, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                    enabled: !state.isLoading,
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
                    onFieldSubmitted: (_) => _login(context),
                    enabled: !state.isLoading,
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
                        value: state.rememberMe,
                        onChanged: (value) {
                          context.read<LoginFormState>().setRememberMe(value);
                        },
                      ),
                      const Text('Remember Me'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: () => _login(context),
                    label: 'Login',
                    isLoading: state.isLoading,
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.errorMessage!,
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
      },
    );
  }
}
