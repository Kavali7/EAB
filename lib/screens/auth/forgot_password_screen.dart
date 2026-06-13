import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (mounted) setState(() => _emailSent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = 'Erreur : ${e.message}');
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Envoi impossible. Verifiez votre connexion internet puis reessayez.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return AuthPageShell(
        title: 'Email envoye',
        subtitle: 'Consultez votre boite de reception.',
        icon: Icons.mark_email_read_outlined,
        child: AuthSuccessPanel(
          icon: Icons.mark_email_read_outlined,
          title: 'Lien envoye',
          message:
              'Un lien de reinitialisation a ete envoye a ${_emailController.text.trim()}.',
          color: Colors.blue,
        ),
      );
    }

    return AuthPageShell(
      title: 'Mot de passe oublie',
      subtitle: 'Recevez un lien pour redefinir votre acces.',
      icon: Icons.lock_reset_outlined,
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
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
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _resetPassword,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isLoading ? 'Envoi...' : 'Envoyer le lien'),
            ),
          ),
        ],
      ),
    );
  }
}
