import 'package:flutter/material.dart';

import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Comptes de l’équipe',
            subtitle: 'Recrutez les assistants et responsables de terrain',
            action: FilledButton.icon(
              onPressed: () => _showCreateAccountForm(context),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Créer un compte'),
            ),
          ),
          const SurfaceCard(
            child: Text(
              'Le mot de passe est choisi par le directeur et n’est jamais affiché dans la liste. '
              'Transmettez-le à la personne recrutée de façon sûre.',
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: state.accounts.isEmpty
                ? const EmptyState(
                    title: 'Aucun compte recruté',
                    description:
                        'Créez un accès pour un assistant ou un responsable de terrain.',
                    icon: Icons.manage_accounts_outlined,
                  )
                : Column(
                    children: [
                      for (final account in state.accounts)
                        _AccountRow(
                          account: account,
                          onToggle: () => _toggleAccount(context, account),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAccountForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var username = '';
    var password = '';
    var phoneNumber = '';
    var showPassword = false;
    var role = UserRole.assistant;
    var fieldId = state.fields.firstOrNull?.id;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recruter un membre',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant de connexion',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Identifiant obligatoire'
                        : value.trim().length > 80
                        ? '80 caractères maximum'
                        : null,
                    onSaved: (value) => username = value!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Numéro de téléphone obligatoire'
                        : null,
                    onSaved: (value) => phoneNumber = value!.trim(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    isExpanded: true,
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Rôle'),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.assistant,
                        child: Text('Assistant'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.fieldManager,
                        child: Text('Responsable de terrain'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setModalState(() => role = value);
                    },
                  ),
                  if (role == UserRole.fieldManager) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Ce responsable verra uniquement les écrans et les données du champ sélectionné.',
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: fieldId,
                      decoration: const InputDecoration(
                        labelText: 'Champ de rattachement',
                      ),
                      items: [
                        for (final field in state.fields)
                          DropdownMenuItem(
                            value: field.id,
                            child: Text(field.name),
                          ),
                      ],
                      validator: (value) => value == null
                          ? 'Créez d’abord un champ et affectez ce compte'
                          : null,
                      onChanged: (value) {
                        if (value != null) setModalState(() => fieldId = value);
                      },
                      onSaved: (value) => fieldId = value,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    obscureText: !showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration:
                        const InputDecoration(
                          labelText: 'Mot de passe initial',
                          helperText: '5 à 12 caractères',
                        ).copyWith(
                          suffixIcon: IconButton(
                            tooltip: showPassword
                                ? 'Masquer le mot de passe'
                                : 'Afficher le mot de passe',
                            onPressed: () => setModalState(
                              () => showPassword = !showPassword,
                            ),
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.length < 5) {
                        return 'Le mot de passe doit contenir au moins 5 caractères';
                      }
                      if (password.length > 12) {
                        return '12 caractères maximum';
                      }
                      return null;
                    },
                    onSaved: (value) => password = value!,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        formKey.currentState!.save();
                        final saved = await runApiAction(context, () async {
                          await state.createManagedAccount(
                            username: username,
                            password: password,
                            phoneNumber: phoneNumber,
                            accountRole: role,
                            assignedFieldId: fieldId,
                          );
                        });
                        if (!saved || !context.mounted) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Créer le compte'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compte créé avec succès')));
    }
  }

  Future<void> _toggleAccount(
    BuildContext context,
    ManagedAccount account,
  ) async {
    final enabled = !account.enabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          enabled ? 'Réactiver ce compte ?' : 'Suspendre ce compte ?',
        ),
        content: Text(
          enabled
              ? '${account.username} pourra de nouveau se connecter.'
              : '${account.username} ne pourra plus se connecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(enabled ? 'Réactiver' : 'Suspendre'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await runApiAction(
      context,
      () => state.setManagedAccountEnabled(account.id, enabled),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.onToggle});

  final ManagedAccount account;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: CircleAvatar(
      backgroundColor: account.enabled ? AppColors.paleGreen : AppColors.line,
      child: Icon(
        account.role == UserRole.assistant
            ? Icons.shopping_bag_outlined
            : Icons.agriculture_outlined,
        color: account.enabled ? AppColors.forest : AppColors.muted,
      ),
    ),
    title: Text(account.username),
    subtitle: Text(
      [
        account.role.label,
        if (account.phoneNumber.isNotEmpty) account.phoneNumber,
        if (account.fieldName != null) account.fieldName!,
        account.enabled ? 'Accès actif' : 'Accès suspendu',
      ].join(' · '),
    ),
    trailing: IconButton(
      tooltip: account.enabled
          ? 'Suspendre ${account.username}'
          : 'Réactiver ${account.username}',
      onPressed: onToggle,
      icon: Icon(
        account.enabled ? Icons.person_off_outlined : Icons.person_outline,
      ),
    ),
  );
}
