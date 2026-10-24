import 'package:flutter/material.dart';

import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/field_select_form_field.dart';
import '../shared/widgets.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final canAdd = RolePermissions.canRecordExpense(state.role);
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Dépenses',
            subtitle: 'Les sorties du jour de la plantation',
            action: canAdd
                ? FilledButton.icon(
                    onPressed: () => _showExpenseForm(context),
                    icon: const Icon(Icons.add, size: 19),
                    label: const Text('Ajouter'),
                  )
                : null,
          ),
          if (RolePermissions.canViewBudget(state.role) &&
              state.budgetSummary != null) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final title = state.role == UserRole.fieldManager
                          ? 'Budget de mon champ'
                          : 'Enveloppe de fonctionnement';
                      final actions = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (RolePermissions.canSetBudgetLimit(state.role))
                            OutlinedButton.icon(
                              onPressed: () => _showBudgetLimitForm(context),
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              label: const Text('Modifier'),
                            ),
                          if (RolePermissions.canSetBudgetLimit(state.role))
                            FilledButton.tonalIcon(
                              onPressed: () => _showAddFundingForm(context),
                              icon: const Icon(Icons.add, size: 17),
                              label: const Text('Ajouter des fonds'),
                            ),
                          if (RolePermissions.canAllocateBudget(state.role))
                            FilledButton.tonalIcon(
                              onPressed: state.fields.isEmpty
                                  ? null
                                  : () => _showAllocationForm(context),
                              icon: const Icon(Icons.call_split, size: 17),
                              label: const Text('Attribuer'),
                            ),
                        ],
                      );
                      if (constraints.maxWidth < 680) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              actions,
                            ],
                          ),
                        );
                      }
                      return SectionTitle(title: title, action: actions);
                    },
                  ),
                  Wrap(
                    spacing: 22,
                    runSpacing: 12,
                    children: [
                      _BudgetValue(
                        label: state.role == UserRole.fieldManager
                            ? 'Attribué à mon champ'
                            : 'Enveloppe',
                        value: state.budgetSummary!.fundingLimit,
                      ),
                      _BudgetValue(
                        label: 'Solde disponible',
                        value: state.budgetSummary!.remainingAmount,
                      ),
                      if (state.role != UserRole.fieldManager)
                        _BudgetValue(
                          label: 'Non attribué',
                          value: state.budgetSummary!.unallocatedAmount,
                        ),
                      _BudgetValue(
                        label: 'À rapprocher',
                        value: state.budgetSummary!.pendingExpenses,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (state.budgetSummary!.fields.isEmpty)
                    const Text(
                      'Aucun budget n’a encore été attribué à un champ.',
                    )
                  else
                    for (final field in state.budgetSummary!.fields)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(field.fieldName),
                        subtitle: Text(
                          'Attribué : ${formatCfa(field.allocatedAmount)}'
                          '${field.pendingExpenses > 0 ? ' · À rapprocher : ${formatCfa(field.pendingExpenses)}' : ''}'
                          '${field.blocked ? ' · Dépenses suspendues' : ''}',
                        ),
                        trailing: Text(
                          formatCfa(field.remainingAmount),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                ],
              ),
            ),
          ],
          if (state.api == null) const DemoNotice(),
          const SizedBox(height: 16),
          SummaryCard(
            label: 'Total des dépenses affichées',
            value: formatCfa(state.expenseTotal),
            icon: Icons.account_balance_wallet_outlined,
            tint: AppColors.cocoa,
            detail:
                '${state.expensesForSelectedField.length} opérations affichées',
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 5),
            child: state.expensesForSelectedField.isEmpty
                ? const EmptyState(
                    title: 'Aucune dépense enregistrée',
                    description: 'Ajoutez les sorties de la journée.',
                    icon: Icons.receipt_long_outlined,
                  )
                : Column(
                    children: [
                      for (final expense in state.expensesForSelectedField)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFF3D5),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.cocoa,
                            ),
                          ),
                          title: Text(expense.description),
                          subtitle: Text(
                            '${expense.fieldName == null ? '' : '${expense.fieldName} · '}${formatShortDate(expense.recordedAt)} · ${formatTime(expense.recordedAt)} · ${expense.recordedBy}'
                            '${expense.status == ExpenseStatus.queuedOffline ? ' · En attente de synchronisation' : ''}'
                            '${expense.status == ExpenseStatus.pendingReconciliation ? ' · À rapprocher avec le directeur' : ''}',
                          ),
                          trailing: Text(
                            formatCfa(expense.amount),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetLimitForm(BuildContext context) async {
    final controller = TextEditingController(
      text: '${state.budgetSummary?.fundingLimit ?? 0}',
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enveloppe de fonctionnement'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant (F CFA)'),
            validator: (value) {
              final amount = int.tryParse((value ?? '').trim());
              return amount == null || amount < 0
                  ? 'Entrez un montant positif ou nul'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final completed = await runApiAction(context, () async {
                await state.setBudgetLimit(int.parse(controller.text.trim()));
              });
              if (completed && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enveloppe mise à jour')));
    }
  }

  Future<void> _showAddFundingForm(BuildContext context) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddBudgetFundingDialog(state: state),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonds ajoutés à l’enveloppe')),
      );
    }
  }

  Future<void> _showAllocationForm(BuildContext context) async {
    if (state.fields.isEmpty) return;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var fieldId =
        state.fields
            .where((field) => field.id == state.selectedFieldId)
            .firstOrNull
            ?.id ??
        state.fields.first.id;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Attribuer un budget à un champ'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: fieldId,
                  decoration: const InputDecoration(labelText: 'Champ'),
                  items: [
                    for (final field in state.fields)
                      DropdownMenuItem(
                        value: field.id,
                        child: Text(field.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => fieldId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant à attribuer (F CFA)',
                  ),
                  validator: (value) {
                    final amount = int.tryParse((value ?? '').trim());
                    return amount == null || amount <= 0
                        ? 'Entrez un montant supérieur à zéro'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (facultatif)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final completed = await runApiAction(context, () async {
                  await state.allocateFieldBudget(
                    fieldId: fieldId,
                    amount: int.parse(amountController.text.trim()),
                    note: noteController.text,
                  );
                });
                if (completed && dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Attribuer'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget attribué au champ')));
    }
  }

  Future<void> _showExpenseForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String? fieldId = state.assignedFieldId ?? state.selectedFieldId;
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
                'Nouvelle dépense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (state.role == UserRole.fieldManager &&
                  state.budgetSummary != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Disponible pour votre champ : '
                  '${formatCfa(state.budgetSummary!.remainingAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Motif',
                  hintText: 'Ex. transport des récoltes',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Motif obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant (F CFA)'),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  return amount == null || amount <= 0
                      ? 'Entrez un montant supérieur à zéro'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              if (state.role != UserRole.fieldManager)
                FieldSelectFormField(
                  state: state,
                  onSaved: (value) => fieldId = value,
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    final saved = await runApiAction(context, () async {
                      await state.addExpense(
                        descriptionController.text,
                        int.parse(amountController.text.trim()),
                        fieldId: fieldId,
                      );
                    });
                    if (!saved || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Enregistrer la dépense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dépense ajoutée à la liste')),
      );
    }
  }
}

class _AddBudgetFundingDialog extends StatefulWidget {
  const _AddBudgetFundingDialog({required this.state});

  final PlantationState state;

  @override
  State<_AddBudgetFundingDialog> createState() =>
      _AddBudgetFundingDialogState();
}

class _AddBudgetFundingDialogState extends State<_AddBudgetFundingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Ajouter des fonds à l’enveloppe'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enveloppe actuelle : '
            '${formatCfa(widget.state.budgetSummary?.fundingLimit ?? 0)}',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant à ajouter (F CFA)',
            ),
            validator: (value) {
              final amount = int.tryParse((value ?? '').trim());
              return amount == null || amount <= 0
                  ? 'Entrez un montant supérieur à zéro'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Motif (facultatif)'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Annuler'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Ajouter')),
    ],
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final completed = await runApiAction(context, () async {
      await widget.state.addBudgetFunding(
        amount: int.parse(_amountController.text.trim()),
        note: _noteController.text,
      );
    });
    if (completed && mounted) Navigator.pop(context, true);
  }
}

class _BudgetValue extends StatelessWidget {
  const _BudgetValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      Text(formatCfa(value), style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}
