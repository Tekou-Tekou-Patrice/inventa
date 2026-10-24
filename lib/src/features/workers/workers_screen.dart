import 'package:flutter/material.dart';

import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({required this.state, super.key});

  final PlantationState state;

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final canAdd = RolePermissions.canManageWorkers(widget.state.role);
    final workers = widget.state.workersForSelectedField
        .where(
          (worker) => worker.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Ouvriers',
            subtitle:
                '${widget.state.activeWorkers.length} actifs · ${widget.state.workersForSelectedField.length} au total',
            action: canAdd
                ? FilledButton.icon(
                    onPressed: _showAddWorker,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Ajouter'),
                  )
                : null,
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un ouvrier…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 15),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: workers.isEmpty
                ? const EmptyState(
                    title: 'Aucun résultat',
                    description: 'Essayez avec un autre nom.',
                  )
                : Column(
                    children: [
                      for (final worker in workers)
                        _WorkerRow(
                          worker: worker,
                          role: widget.state.role,
                          hourlyRate: widget.state.hourlyRateFor(worker),
                          onEditSalary: () => _showSalaryForm(worker),
                          onEditPhone: () => _showPhoneForm(worker),
                          onArchive: () => _confirmArchive(worker),
                          onToggleActive: () => runApiAction(
                            context,
                            () => widget.state.setWorkerActive(
                              worker.id,
                              !worker.active,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhoneForm(Worker worker) async {
    final phoneController = TextEditingController(text: worker.phoneNumber);
    final saved = await showModalBottomSheet<bool>(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Téléphone — ${worker.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                helperText: 'Laissez vide pour effacer le numéro.',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final saved = await runApiAction(context, () async {
                    await widget.state.updateWorkerPhone(
                      worker.id,
                      phoneController.text,
                    );
                  });
                  if (!saved || !context.mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Enregistrer le téléphone'),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléphone de l’ouvrier mis à jour')),
      );
    }
  }

  Future<void> _confirmArchive(Worker worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la fiche ?'),
        content: Text(
          'La fiche de ${worker.name} sera archivée. Les présences et paies '
          'passées sont conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await runApiAction(context, () => widget.state.archiveWorker(worker.id));
  }

  Future<void> _showSalaryForm(Worker worker) async {
    final formKey = GlobalKey<FormState>();
    final salaryController = TextEditingController(text: '${worker.salary}');
    final saved = await showModalBottomSheet<bool>(
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
                'Salaire de base — ${worker.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Salaire de base mensuel (F CFA)',
                  helperText: widget.state.role == UserRole.assistant
                      ? 'Montant individuel indiqué par le directeur.'
                      : 'Modification limitée à cet ouvrier.',
                ),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  return amount == null || amount <= 0
                      ? 'Entrez un salaire supérieur à zéro'
                      : null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final updated = await runApiAction(context, () async {
                      await widget.state.updateWorkerSalary(
                        worker.id,
                        int.parse(salaryController.text.trim()),
                      );
                    });
                    if (!updated || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Enregistrer le salaire de base'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salaire de l’ouvrier mis à jour')),
      );
    }
  }

  Future<void> _showAddWorker() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final groupController = TextEditingController();
    final phoneController = TextEditingController();
    final result = await showModalBottomSheet<bool>(
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
                'Nouvel ouvrier',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nom obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: groupController,
                decoration: const InputDecoration(
                  labelText: 'Parcelle / équipe',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Numéro de téléphone obligatoire'
                    : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final saved = await runApiAction(context, () async {
                        await widget.state.addWorker(
                          name: nameController.text,
                          group: groupController.text,
                          phoneNumber: phoneController.text,
                        );
                      });
                      if (!saved || !context.mounted) return;
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Ajouter à l’équipe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ouvrier ajouté à l’équipe')),
      );
    }
  }
}

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({
    required this.worker,
    required this.role,
    required this.hourlyRate,
    required this.onEditSalary,
    required this.onEditPhone,
    required this.onArchive,
    required this.onToggleActive,
  });

  final Worker worker;
  final UserRole role;
  final double hourlyRate;
  final VoidCallback onEditSalary;
  final VoidCallback onEditPhone;
  final VoidCallback onArchive;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Opacity(
          opacity: worker.active ? 1 : .55,
          child: PersonAvatar(name: worker.name),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(worker.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                [
                  worker.group,
                  if (worker.fieldName != null) worker.fieldName!,
                  worker.active ? 'Actif' : 'Inactif',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (worker.phoneNumber.isNotEmpty ||
                  role == UserRole.assistant) ...[
                const SizedBox(height: 3),
                Text(
                  worker.phoneNumber.isEmpty
                      ? 'Téléphone non renseigné'
                      : worker.phoneNumber,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              Text(
                '${worker.salaryIsIndividual ? 'Salaire individuel' : 'Salaire de référence'} : '
                '${formatCfa(worker.salary)} / mois · '
                'Taux : ${hourlyRate.toStringAsFixed(2).replaceAll('.', ',')} F / h',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.forest),
              ),
            ],
          ),
        ),
        Text(
          '${formatCfa(worker.salary)} / mois',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (RolePermissions.canManageWorkerSalary(role))
          IconButton(
            tooltip: 'Modifier le salaire de base de ${worker.name}',
            onPressed: onEditSalary,
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        if (RolePermissions.canManageWorkers(role))
          IconButton(
            tooltip: worker.active
                ? 'Désactiver ${worker.name}'
                : 'Réactiver ${worker.name}',
            onPressed: onToggleActive,
            icon: Icon(
              worker.active ? Icons.person_off_outlined : Icons.person_outline,
              size: 18,
            ),
            color: worker.active ? AppColors.cocoa : AppColors.forest,
            visualDensity: VisualDensity.compact,
          ),
        if (RolePermissions.canManageWorkerContacts(role))
          IconButton(
            tooltip: 'Modifier le téléphone de ${worker.name}',
            onPressed: onEditPhone,
            icon: const Icon(Icons.phone_android_outlined, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        if (role == UserRole.assistant)
          IconButton(
            tooltip: worker.active
                ? 'Supprimer la fiche de ${worker.name}'
                : 'Réactiver ${worker.name}',
            onPressed: worker.active ? onArchive : onToggleActive,
            icon: Icon(
              worker.active ? Icons.delete_outline : Icons.person_outline,
              size: 18,
            ),
            color: worker.active ? AppColors.cocoa : AppColors.forest,
            visualDensity: VisualDensity.compact,
          ),
      ],
    ),
  );
}
