import 'package:flutter/material.dart';

import '../../data/plantation_api.dart';
import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final canPay = RolePermissions.canRecordPayment(state.role);
    final canOvertime = RolePermissions.canRecordOvertime(state.role);
    final canViewPayments = RolePermissions.canViewPayments(state.role);
    final canViewOvertime = RolePermissions.canViewOvertime(state.role);
    final canViewEstimate = RolePermissions.canViewPayrollEstimate(state.role);
    final canConfigureSalary = RolePermissions.canManageAccounts(state.role);
    final payrollNotice = canViewEstimate
        ? 'Le directeur fixe le salaire mensuel. L’assistant peut régler directement le cumul dû à chaque ouvrier avec le bouton « Payer ».'
        : 'Les paiements saisis par l’assistant sont consultables ici.';
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Paie',
            subtitle: 'Salaires indicatifs et paiements enregistrés',
            action: canConfigureSalary
                ? OutlinedButton.icon(
                    onPressed: () => _showSalarySettingsForm(context),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Salaire'),
                  )
                : canOvertime && state.activeWorkers.isNotEmpty
                ? OutlinedButton.icon(
                    onPressed: () => _showOvertimeForm(context),
                    icon: const Icon(Icons.more_time, size: 18),
                    label: const Text('Heures sup.'),
                  )
                : null,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paleYellow,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              payrollNotice,
              style: const TextStyle(color: Color(0xFF70561D), fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SummaryCard(
                label: 'Équipe active',
                value: '${state.activeWorkers.length} ouvriers',
                icon: Icons.groups_outlined,
                tint: AppColors.leaf,
              ),
              if (canViewEstimate)
                SummaryCard(
                  label: 'Salaire estimé du mois',
                  value: formatCfa(state.estimatedPayrollTotal),
                  icon: Icons.calculate_outlined,
                  tint: AppColors.cocoa,
                  detail:
                      'Salaire de référence · ${state.monthlyRequiredHours} h complètes',
                ),
              if (canViewPayments) ...[
                SummaryCard(
                  label: 'Paiements enregistrés',
                  value: '${state.paymentsForSelectedField.length}',
                  icon: Icons.payments_outlined,
                  tint: const Color(0xFF5472A2),
                ),
                SummaryCard(
                  label: 'Montant enregistré',
                  value: formatCfa(
                    state.paymentsForSelectedField.fold<int>(
                      0,
                      (total, payment) => total + payment.amount,
                    ),
                  ),
                  icon: Icons.account_balance_wallet_outlined,
                  tint: AppColors.cocoa,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: canViewEstimate
                      ? 'Salaire estimé selon les heures'
                      : 'Paiements enregistrés',
                  action: canViewEstimate
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Mois précédent',
                              onPressed: () => runApiAction(
                                context,
                                () => state.selectPayrollMonth(
                                  DateTime(
                                    state.payrollMonth.year,
                                    state.payrollMonth.month - 1,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(_monthLabel(state.payrollMonth)),
                            IconButton(
                              tooltip: 'Mois suivant',
                              onPressed: () => runApiAction(
                                context,
                                () => state.selectPayrollMonth(
                                  DateTime(
                                    state.payrollMonth.year,
                                    state.payrollMonth.month + 1,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        )
                      : null,
                ),
                if (canViewEstimate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Le calcul utilise le salaire mensuel propre à chaque ouvrier et ${state.monthlyRequiredHours} h complètes par mois.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                for (final worker in state.workersForSelectedField.where(
                  (worker) => worker.active || state.payrollDueFor(worker) > 0,
                ))
                  _PayrollWorkerRow(
                    worker: worker,
                    workedMinutes: canViewEstimate
                        ? state.workedMinutesFor(worker.id)
                        : null,
                    estimatedAmount: canViewEstimate
                        ? state.estimatedPayrollFor(worker)
                        : null,
                    payments: state.paymentsForSelectedField
                        .where((payment) => payment.workerId == worker.id)
                        .toList(),
                    dueAmount: state.payrollDueFor(worker),
                    canPay: canPay,
                    onPay: () => _payWorker(
                      context,
                      worker,
                      state.payrollDueFor(worker),
                    ),
                  ),
              ],
            ),
          ),
          if (canViewPayments) ...[
            const SizedBox(height: 18),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Derniers paiements'),
                  if (state.paymentsForSelectedField.isEmpty)
                    const EmptyState(
                      title: 'Aucun paiement enregistré',
                      description: 'Les paiements apparaîtront ici.',
                      icon: Icons.payments_outlined,
                    )
                  else
                    for (final payment in state.paymentsForSelectedField.take(
                      5,
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.leaf,
                        ),
                        title: Text(_workerName(payment.workerId)),
                        subtitle: Text(
                          '${formatShortDate(payment.recordedAt)} · ${formatTime(payment.recordedAt)} · ${payment.recordedBy}',
                        ),
                        trailing: Text(
                          formatCfa(payment.amount),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                ],
              ),
            ),
          ],
          if (canViewOvertime && state.overtimeForSelectedField.isNotEmpty) ...[
            const SizedBox(height: 18),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Heures supplémentaires déclarées'),
                  for (final overtime in state.overtimeForSelectedField.take(5))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.more_time,
                        color: AppColors.cocoa,
                      ),
                      title: Text(_workerName(overtime.workerId)),
                      subtitle: Text(
                        '${overtime.description} · ${formatTime(overtime.recordedAt)}',
                      ),
                      trailing: Text('${overtime.hours} h'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _workerName(String workerId) =>
      state.workersForSelectedField
          .where((worker) => worker.id == workerId)
          .firstOrNull
          ?.name ??
      'Ouvrier';

  String _monthLabel(DateTime month) {
    const names = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  Future<void> _showSalarySettingsForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final salaryController = TextEditingController(
      text: '${state.monthlySalary}',
    );
    final hoursController = TextEditingController(
      text: '${state.monthlyRequiredHours}',
    );
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
                'Paramètres de paie',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Salaire mensuel de référence (F CFA)',
                  helperText:
                      'Appliqué à l’équipe, sauf salaire individuel modifié par assistant.',
                ),
                validator: _positiveIntegerValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Heures complètes par mois',
                ),
                validator: _positiveIntegerValidator,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final saved = await runApiAction(context, () async {
                      if (!await state.savePayrollSettings(
                        salary: int.parse(salaryController.text.trim()),
                        requiredHours: int.parse(hoursController.text.trim()),
                      )) {
                        throw const ApiException(
                          'La configuration est réservée au directeur.',
                        );
                      }
                    });
                    if (!saved || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Enregistrer les paramètres'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres de paie mis à jour')),
      );
    }
  }

  Future<void> _payWorker(
    BuildContext context,
    Worker worker,
    int amount,
  ) async {
    if (amount <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
          'Confirmer le versement de ${formatCfa(amount)} à ${worker.name} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Payer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final saved = await runApiAction(context, () async {
      if (!await state.recordPayrollPayment(worker.id)) {
        throw const ApiException('Le paiement n’a pas pu être enregistré.');
      }
    });
    if (saved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paiement enregistré')));
    }
  }

  Future<void> _showOvertimeForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final hoursController = TextEditingController();
    final descriptionController = TextEditingController();
    var workerId = state.activeWorkers.first.id;
    final saved = await showModalBottomSheet<bool>(
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
                  'Déclarer des heures supplémentaires',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: workerId,
                  decoration: const InputDecoration(labelText: 'Ouvrier'),
                  items: [
                    for (final worker in state.activeWorkers)
                      DropdownMenuItem(
                        value: worker.id,
                        child: Text(worker.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setModalState(() => workerId = value);
                  },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: hoursController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nombre d’heures',
                  ),
                  validator: (value) {
                    final hours = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    return hours == null || hours <= 0
                        ? 'Entrez une durée supérieure à zéro'
                        : null;
                  },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Motif'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Motif obligatoire'
                      : null,
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final saved = await runApiAction(context, () async {
                        if (!await state.addOvertime(
                          workerId,
                          double.parse(
                            hoursController.text.trim().replaceAll(',', '.'),
                          ),
                          descriptionController.text,
                        )) {
                          throw const ApiException(
                            'La déclaration est refusée pour ce profil.',
                          );
                        }
                      });
                      if (!saved || !context.mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('Enregistrer les heures'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heures supplémentaires enregistrées')),
      );
    }
  }
}

class _PayrollWorkerRow extends StatelessWidget {
  const _PayrollWorkerRow({
    required this.worker,
    required this.workedMinutes,
    required this.estimatedAmount,
    required this.payments,
    required this.dueAmount,
    required this.canPay,
    required this.onPay,
  });

  final Worker worker;
  final int? workedMinutes;
  final int? estimatedAmount;
  final List<Payment> payments;
  final int dueAmount;
  final bool canPay;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final paid = payments.fold<int>(
      0,
      (total, payment) => total + payment.amount,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          PersonAvatar(name: worker.name),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                if (workedMinutes != null)
                  Text(
                    '${(workedMinutes! / 60).toStringAsFixed(1)} h pointées ce mois',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (estimatedAmount != null || canPay) ...[
                  const SizedBox(height: 3),
                  Text(
                    estimatedAmount != null
                        ? 'Mois : ${formatCfa(estimatedAmount!)} · Cumul à payer : ${formatCfa(dueAmount)}'
                        : '${payments.length} paiement(s) enregistré(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (paid > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusPill(
                label: 'Versé ${formatCfa(paid)}',
                color: AppColors.leaf,
              ),
            ),
          if (canPay && dueAmount > 0)
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Payer'),
            ),
        ],
      ),
    );
  }
}

String? _positiveIntegerValidator(String? value) {
  final amount = int.tryParse(value?.trim() ?? '');
  return amount == null || amount <= 0
      ? 'Entrez un nombre entier supérieur à zéro'
      : null;
}
