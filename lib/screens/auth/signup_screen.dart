import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import 'auth_layout.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _signupSuccess = false;
  int _rateLimitSeconds = 0;
  Timer? _rateLimitTimer;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_rateLimitSeconds > 0) {
      setState(() {
        _errorMessage =
            'Trop de demandes. Patientez encore $_rateLimitSeconds secondes avant de reessayer.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );
      if (mounted) setState(() => _signupSuccess = true);
    } on AuthException catch (e) {
      if (mounted) {
        final shouldCooldown = _isRateLimitError(e.message);
        setState(() => _errorMessage = _translateAuthError(e.message));
        if (shouldCooldown) _startRateLimitCooldown();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Inscription impossible. Verifiez votre connexion internet puis reessayez.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String message) {
    final normalized = message.toLowerCase();
    if (_isRateLimitError(message)) {
      return 'Trop de demandes d inscription ou d email de confirmation. Patientez avant de reessayer. En production, configurez un SMTP personnalise dans Supabase.';
    }
    if (normalized.contains('email_address_invalid') ||
        normalized.contains('email address') &&
            normalized.contains('invalid')) {
      return 'Adresse email refusee. Utilisez une adresse email reelle.';
    }
    if (message.contains('User already registered')) {
      return 'Un compte existe deja avec cette adresse email.';
    }
    if (message.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caracteres.';
    }
    if (message.contains('Unable to validate email')) {
      return 'Adresse email invalide.';
    }
    return 'Erreur : $message';
  }

  bool _isRateLimitError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('email rate limit') ||
        normalized.contains('rate limit') ||
        normalized.contains('too many requests');
  }

  void _startRateLimitCooldown({int seconds = 60}) {
    _rateLimitTimer?.cancel();
    setState(() => _rateLimitSeconds = seconds);
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_rateLimitSeconds <= 1) {
        timer.cancel();
        setState(() => _rateLimitSeconds = 0);
      } else {
        setState(() => _rateLimitSeconds -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_signupSuccess) {
      return AuthPageShell(
        title: 'Compte cree',
        subtitle: 'Confirmez votre email avant de vous connecter.',
        icon: Icons.how_to_reg_outlined,
        child: AuthSuccessPanel(
          icon: Icons.check_circle_outline,
          title: 'Inscription reussie',
          message:
              'Un email de confirmation a ete envoye a ${_emailController.text.trim()}. Verifiez votre boite de reception avant de vous connecter.',
        ),
      );
    }

    return AuthPageShell(
      title: 'Creer un compte',
      subtitle: 'Demandez un acces a l\'espace de gestion de votre eglise.',
      icon: Icons.person_add_alt_1_outlined,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Deja un compte ?', style: AppTextStyles.bodySmall),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
            child: const Text('Se connecter'),
          ),
        ],
      ),
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) return 'Adresse email invalide';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              if (value.length < 6) {
                return 'Au moins 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signup(),
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _rateLimitSeconds > 0 ? null : _signup,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _rateLimitSeconds > 0
                          ? Icons.hourglass_bottom
                          : Icons.person_add_alt_1,
                    ),
              label: Text(
                _isLoading
                    ? 'Creation...'
                    : _rateLimitSeconds > 0
                    ? 'Reessayer dans ${_rateLimitSeconds}s'
                    : 'Creer le compte',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
