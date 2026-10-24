import 'package:flutter/material.dart';

import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    if (state.role == UserRole.director) {
      return _DirectorTaskTable(state: state);
    }
    final canCreate = RolePermissions.canManageTasks(state.role);
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Tâches du jour',
            subtitle: 'Organisez le travail dans les parcelles',
            action: canCreate
                ? FilledButton.icon(
                    onPressed: () => _showCreateTask(context),
                    icon: const Icon(Icons.add, size: 19),
                    label: const Text('Nouvelle tâche'),
                  )
                : null,
          ),
          if (state.api == null && !canCreate) const DemoNotice(),
          const SizedBox(height: 14),
          if (state.tasksForSelectedField.isEmpty)
            const SurfaceCard(
              child: EmptyState(
                title: 'Aucune tâche pour le moment',
                description: 'Créez une tâche pour organiser le travail.',
                icon: Icons.assignment_outlined,
              ),
            )
          else
            for (final task in state.tasksForSelectedField)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TaskCard(task: task, state: state),
              ),
        ],
      ),
    );
  }

  Future<void> _showCreateTask(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final selected = <String>{};
    var type = FieldTaskType.assignedWorkers;
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer une tâche',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Description du travail',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Description obligatoire'
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  'Type de tâche',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Ouvriers enregistrés'),
                      selected: type == FieldTaskType.assignedWorkers,
                      onSelected: (_) => setModalState(
                        () => type = FieldTaskType.assignedWorkers,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Saisonniers'),
                      selected: type == FieldTaskType.seasonalWorkers,
                      onSelected: (_) => setModalState(
                        () => type = FieldTaskType.seasonalWorkers,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (type == FieldTaskType.assignedWorkers) ...[
                  Text(
                    'Assigner à',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final worker in state.activeWorkers)
                        FilterChip(
                          label: Text(worker.name),
                          selected: selected.contains(worker.id),
                          onSelected: (value) => setModalState(() {
                            if (value) {
                              selected.add(worker.id);
                            } else {
                              selected.remove(worker.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ] else
                  const Text(
                    'Le nombre de saisonniers et le coût réel seront saisis à la clôture.',
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (type == FieldTaskType.assignedWorkers &&
                          selected.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Choisissez au moins un ouvrier'),
                          ),
                        );
                        return;
                      }
                      final saved = await runApiAction(context, () async {
                        await state.addTask(
                          titleController.text,
                          selected.toList(),
                          type: type,
                        );
                      });
                      if (!saved || !context.mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('Créer la tâche'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tâche ajoutée à la liste')));
    }
  }
}

class _DirectorTaskTable extends StatelessWidget {
  const _DirectorTaskTable({required this.state});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final tasks = [...state.tasksForSelectedField]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final completedTasks = tasks
        .where((task) => task.status == FieldTaskStatus.termine)
        .toList();
    final totalCost = completedTasks.fold<int>(
      0,
      (total, task) => total + (task.actualCost ?? 0),
    );
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            title: 'Suivi des tâches par champ',
            subtitle: 'Dates, durée, coûts réels et effectifs par champ',
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SummaryCard(
                label: 'Tâches terminées',
                value: '${completedTasks.length}',
                icon: Icons.task_alt,
                tint: AppColors.paleGreen,
              ),
              SummaryCard(
                label: 'Coûts réels enregistrés',
                value: formatCfa(totalCost),
                icon: Icons.payments_outlined,
                tint: AppColors.paleGreen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            const SurfaceCard(
              child: EmptyState(
                title: 'Aucune tâche enregistrée',
                description:
                    'Les tâches des champs apparaîtront ici dès leur création.',
                icon: Icons.table_chart_outlined,
              ),
            )
          else
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Champ')),
                    DataColumn(label: Text('Tâche')),
                    DataColumn(label: Text('Début')),
                    DataColumn(label: Text('Fin')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Durée')),
                    DataColumn(label: Text('Coût réel')),
                    DataColumn(label: Text('Ouvriers affectés')),
                    DataColumn(label: Text('Saisonniers')),
                    DataColumn(label: Text('État')),
                  ],
                  rows: [
                    for (final task in tasks)
                      DataRow(
                        cells: [
                          DataCell(Text(task.fieldName ?? '—')),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(task.title),
                            ),
                          ),
                          DataCell(Text(formatShortDate(task.createdAt))),
                          DataCell(
                            Text(
                              task.completedAt == null
                                  ? '—'
                                  : formatShortDate(task.completedAt!),
                            ),
                          ),
                          DataCell(Text(_taskTypeLabel(task.type))),
                          DataCell(Text(_taskDuration(task))),
                          DataCell(
                            Text(
                              task.actualCost == null
                                  ? '—'
                                  : formatCfa(task.actualCost!),
                            ),
                          ),
                          DataCell(Text('${task.assigneeIds.length}')),
                          DataCell(
                            Text(
                              task.type == FieldTaskType.seasonalWorkers
                                  ? '${task.seasonalWorkerCount ?? '—'}'
                                  : '—',
                            ),
                          ),
                          DataCell(Text(_taskStatusLabel(task.status))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _taskDuration(FieldTask task) {
    final completedAt = task.completedAt;
    if (completedAt == null) {
      return task.status == FieldTaskStatus.termine ? '—' : 'En cours';
    }
    final hours = completedAt.difference(task.createdAt).inHours;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    if (days == 0) return '$remainingHours h';
    if (remainingHours == 0) return '$days j';
    return '$days j $remainingHours h';
  }

  String _taskStatusLabel(FieldTaskStatus status) => switch (status) {
    FieldTaskStatus.enCours => 'En cours',
    FieldTaskStatus.aFaire => 'À faire',
    FieldTaskStatus.termine => 'Terminée',
  };

  String _taskTypeLabel(FieldTaskType type) => switch (type) {
    FieldTaskType.assignedWorkers => 'Ouvriers',
    FieldTaskType.seasonalWorkers => 'Saisonniers',
  };
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.state});

  final FieldTask task;
  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final assignees = task.assigneeIds
        .map(
          (id) => state.workersForSelectedField
              .where((worker) => worker.id == id)
              .firstOrNull
              ?.name,
        )
        .whereType<String>()
        .join(', ');
    final statusText = switch (task.status) {
      FieldTaskStatus.enCours => 'En cours',
      FieldTaskStatus.aFaire => 'À faire',
      FieldTaskStatus.termine => 'Terminée',
    };
    final statusColor = task.status == FieldTaskStatus.enCours
        ? AppColors.leaf
        : AppColors.cocoa;
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.agriculture_outlined,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  task.type == FieldTaskType.seasonalWorkers
                      ? 'Équipe saisonnière'
                      : assignees.isEmpty
                      ? 'Aucun ouvrier assigné'
                      : assignees,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (RolePermissions.canManageTasks(state.role))
            PopupMenuButton<FieldTaskStatus>(
              tooltip: 'Modifier le statut de ${task.title}',
              initialValue: task.status,
              onSelected: (status) => _changeStatus(context, status),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: FieldTaskStatus.aFaire,
                  child: Text('À faire'),
                ),
                PopupMenuItem(
                  value: FieldTaskStatus.enCours,
                  child: Text('En cours'),
                ),
                PopupMenuItem(
                  value: FieldTaskStatus.termine,
                  child: Text('Terminée'),
                ),
              ],
              child: StatusPill(label: statusText, color: statusColor),
            )
          else
            StatusPill(label: statusText, color: statusColor),
        ],
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    FieldTaskStatus status,
  ) async {
    int? actualCost;
    int? seasonalWorkerCount;
    if (status == FieldTaskStatus.termine) {
      final details = await _askCompletionDetails(context, task.type);
      if (details == null || !context.mounted) return;
      actualCost = details.$1;
      seasonalWorkerCount = details.$2 ?? 0;
    }
    if (!context.mounted) return;
    await runApiAction(
      context,
      () => state.updateTaskStatus(
        task.id,
        status,
        actualCost: actualCost,
        seasonalWorkerCount: seasonalWorkerCount,
      ),
    );
  }

  Future<(int, int?)?> _askCompletionDetails(
    BuildContext context,
    FieldTaskType type,
  ) async {
    return showDialog<(int, int?)>(
      context: context,
      builder: (_) => _TaskCompletionDialog(type: type),
    );
  }
}

class _TaskCompletionDialog extends StatefulWidget {
  const _TaskCompletionDialog({required this.type});

  final FieldTaskType type;

  @override
  State<_TaskCompletionDialog> createState() => _TaskCompletionDialogState();
}

class _TaskCompletionDialogState extends State<_TaskCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _seasonalController = TextEditingController(text: '0');

  @override
  void dispose() {
    _costController.dispose();
    _seasonalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Clôturer la tâche'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _costController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Coût réel (F CFA)'),
            validator: _nonNegativeIntegerError,
          ),
          if (widget.type == FieldTaskType.seasonalWorkers)
            TextFormField(
              controller: _seasonalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre d’ouvriers saisonniers',
              ),
              validator: _nonNegativeIntegerError,
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _submit,
        child: const Text('Enregistrer et terminer'),
      ),
    ],
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      int.parse(_costController.text.trim()),
      widget.type == FieldTaskType.seasonalWorkers
          ? int.parse(_seasonalController.text.trim())
          : null,
    ));
  }

  String? _nonNegativeIntegerError(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Saisissez un nombre entier';
    if (parsed < 0) return 'La valeur ne peut pas être négative';
    return null;
  }
}
