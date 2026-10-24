import 'package:flutter/material.dart';

import '../../data/plantation_api.dart';
import '../../theme/app_theme.dart';

class DirectorRegistrationScreen extends StatefulWidget {
  const DirectorRegistrationScreen({
    required this.onRegister,
    required this.onBack,
    super.key,
  });

  final Future<void> Function({
    required String username,
    required String password,
    required String phoneNumber,
  })
  onRegister;
  final VoidCallback onBack;

  @override
  State<DirectorRegistrationScreen> createState() =>
      _DirectorRegistrationScreenState();
}

class _DirectorRegistrationScreenState
    extends State<DirectorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _phoneNumber.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onRegister(
        username: _username.text.trim(),
        password: _password.text,
        phoneNumber: _phoneNumber.text.trim(),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _error =
              'Inscription impossible. Vérifiez le serveur puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Retour à la connexion',
        onPressed: _loading ? null : widget.onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Inscription du directeur'),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Créer le premier compte directeur',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cette inscription est disponible uniquement tant qu’aucun directeur n’existe.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _username,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Identifiant',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Identifiant obligatoire'
                          : value.trim().length > 80
                          ? '80 caractères maximum'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneNumber,
                      enabled: !_loading,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Numéro de téléphone obligatoire'
                          : value.trim().length > 40
                          ? '40 caractères maximum'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      enabled: !_loading,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(
                            labelText: 'Mot de passe',
                            helperText: '5 à 12 caractères',
                            prefixIcon: Icon(Icons.lock_outline),
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'Masquer le mot de passe'
                                  : 'Afficher le mot de passe',
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 5) {
                          return '5 caractères minimum';
                        }
                        if (password.length > 12) {
                          return '12 caractères maximum';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmation,
                      enabled: !_loading,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value != _password.text
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer le compte directeur'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
