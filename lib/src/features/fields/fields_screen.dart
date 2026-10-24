import 'package:flutter/material.dart';

import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: 'Champs',
          subtitle: 'Gérez les sites et leurs équipes',
          action: FilledButton.icon(
            onPressed: () => _showCreateFieldForm(context),
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('Créer un champ'),
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
          child: state.fields.isEmpty
              ? const EmptyState(
                  title: 'Aucun champ enregistré',
                  description: 'Créez un champ pour organiser les équipes.',
                  icon: Icons.landscape_outlined,
                )
              : Column(
                  children: [
                    for (final field in state.fields)
                      _FieldRow(
                        field: field,
                        managerNames: state.accounts
                            .where(
                              (account) =>
                                  account.role == UserRole.fieldManager &&
                                  account.fieldId == field.id,
                            )
                            .map((account) => account.username)
                            .toList(),
                        workerCount: state.workers
                            .where((worker) => worker.fieldId == field.id)
                            .length,
                      ),
                  ],
                ),
        ),
      ],
    ),
  );

  Future<void> _showCreateFieldForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var name = '';
    var location = '';
    var description = '';
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau champ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom du champ'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le nom est obligatoire'
                    : null,
                onSaved: (value) => name = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Localisation'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La localisation est obligatoire'
                    : null,
                onSaved: (value) => location = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (facultative)',
                ),
                onSaved: (value) => description = value?.trim() ?? '',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    final saved = await runApiAction(context, () async {
                      await state.createField(
                        name: name,
                        location: location,
                        description: description,
                      );
                    });
                    if (!saved || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Créer le champ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Champ créé')));
    }
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.managerNames,
    required this.workerCount,
  });

  final PlantationField field;
  final List<String> managerNames;
  final int workerCount;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 6),
    leading: const CircleAvatar(
      backgroundColor: AppColors.paleGreen,
      child: Icon(Icons.landscape_outlined, color: AppColors.forest),
    ),
    title: Text(field.name),
    subtitle: Text(
      [
        field.location,
        if (field.description.isNotEmpty) field.description,
        '$workerCount ouvrier${workerCount == 1 ? '' : 's'} · '
            '${managerNames.isEmpty ? 'Aucun responsable affecté' : managerNames.join(', ')}',
      ].join(' · '),
    ),
    isThreeLine: true,
  );
}
