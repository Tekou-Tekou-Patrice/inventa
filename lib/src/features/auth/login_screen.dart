import 'package:flutter/material.dart';

import '../../data/plantation_api.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onLogin,
    this.canRegisterDirector,
    this.onOpenRegistration,
    this.sessionRestoreError,
    this.onRetrySessionRestore,
    super.key,
  });

  final Future<void> Function(String username, String password) onLogin;
  final Future<bool> Function()? canRegisterDirector;
  final VoidCallback? onOpenRegistration;
  final String? sessionRestoreError;
  final Future<void> Function()? onRetrySessionRestore;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;
  String? _registrationError;
  bool _registrationAvailable = false;
  bool _checkingRegistration = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final check = widget.canRegisterDirector;
    if (check == null || _checkingRegistration) return;
    setState(() {
      _checkingRegistration = true;
      _registrationError = null;
    });
    try {
      final available = await check();
      if (mounted) setState(() => _registrationAvailable = available);
    } on ApiException catch (error) {
      if (mounted) setState(() => _registrationError = error.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _registrationError =
              'Vérification de l’inscription indisponible. Réessayez plus tard.',
        );
      }
    } finally {
      if (mounted) setState(() => _checkingRegistration = false);
    }
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(
        () => _error = 'Saisissez votre identifiant et votre mot de passe.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onLogin(username, password);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _error =
              'Connexion impossible. Vérifiez le serveur puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 25),
                  Text(
                    'Bienvenue sur Inventa',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Connectez-vous pour accéder aux activités de la plantation.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.sessionRestoreError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'La session enregistrée n’a pas pu être restaurée : '
                      '${widget.sessionRestoreError}',
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 13,
                      ),
                    ),
                    if (widget.onRetrySessionRestore != null)
                      TextButton(
                        onPressed: _loading
                            ? null
                            : widget.onRetrySessionRestore,
                        child: const Text('Réessayer sans ressaisir le mot de passe'),
                      ),
                  ],
                  const SizedBox(height: 22),
                  TextField(
                    controller: _username,
                    enabled: !_loading,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Identifiant',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    enabled: !_loading,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration:
                        const InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
                        ).copyWith(
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Masquer le mot de passe'
                                : 'Afficher le mot de passe',
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 13),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter'),
                  ),
                  if (_registrationAvailable &&
                      widget.onOpenRegistration != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : widget.onOpenRegistration,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Inscrire le directeur'),
                    ),
                  ],
                  if (_registrationError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _registrationError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: _checkingRegistration
                          ? null
                          : _checkRegistration,
                      child: Text(
                        _checkingRegistration
                            ? 'Vérification…'
                            : 'Réessayer la vérification',
                      ),
                    ),
                  ],
                  const SizedBox(height: 17),
                  const Text(
                    'Connexion sécurisée · les accès sont définis par votre responsable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.eco_outlined, color: Colors.white, size: 27),
    ),
  );
}
