import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/plantation_api.dart';
import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class FieldReportScreen extends StatelessWidget {
  const FieldReportScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.api == null ? null : state.dailyReportSnapshot;
    final attendanceRecords =
        snapshot?.attendance ??
        state.attendanceRecords.values
            .where((record) => _sameDate(record.date, state.selectedDate))
            .where(
              (record) => state.workersForSelectedField.any(
                (worker) => worker.id == record.workerId,
              ),
            )
            .toList();
    final report = _reportText(
      attendanceRecords,
      snapshot?.tasks ?? state.tasksForSelectedField,
      snapshot?.movements ?? state.stockMovementsForSelectedField,
      snapshot?.alerts ?? state.materialAlertsForSelectedField,
      snapshot?.expenses ?? state.expensesForSelectedField,
      snapshot?.payments ?? state.paymentsForSelectedField,
      snapshot?.sales ?? state.salesForSelectedField,
    );
    final directorAwaitingValidation =
        state.role == UserRole.director && snapshot?.validated != true;
    return ContentWidth(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              title: 'Rapport quotidien',
              subtitle:
                  'Synthèse des activités du ${formatShortDate(state.selectedDate)}',
              action: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Date précédente',
                    onPressed: () => runApiAction(
                      context,
                      () => state.selectDate(
                        state.selectedDate.subtract(const Duration(days: 1)),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: state.selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && context.mounted) {
                        await runApiAction(
                          context,
                          () => state.selectDate(date),
                        );
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(formatShortDate(state.selectedDate)),
                  ),
                  IconButton(
                    tooltip: 'Date suivante',
                    onPressed: _sameDate(state.selectedDate, DateTime.now())
                        ? null
                        : () => runApiAction(
                            context,
                            () => state.selectDate(
                              state.selectedDate.add(const Duration(days: 1)),
                            ),
                          ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  if (!directorAwaitingValidation)
                    IconButton(
                      tooltip: 'Copier le rapport',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: report));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Rapport copié, prêt à être transmis',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                ],
              ),
            ),
            if (state.api == null) const DemoNotice(),
            const SizedBox(height: 14),
            if (RolePermissions.canViewPayments(state.role))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OutlinedButton.icon(
                  onPressed: () => _showMonthlyReport(context),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Consulter les rapports du mois'),
                ),
              ),
            if (directorAwaitingValidation)
              const SurfaceCard(
                child: Text(
                  'Ce rapport n’est pas encore validé par l’assistant. '
                  'Son contenu reste masqué au directeur.',
                ),
              )
            else ...[
              if (state.api != null && state.role == UserRole.assistant)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: snapshot?.validated == true
                        ? null
                        : () => runApiAction(context, () async {
                            if (!await state.validateDailyReport()) {
                              throw const ApiException(
                                'Le rapport quotidien n’a pas pu être validé.',
                              );
                            }
                          }),
                    icon: Icon(
                      snapshot?.validated == true
                          ? Icons.verified_outlined
                          : Icons.fact_check_outlined,
                    ),
                    label: Text(
                      snapshot?.validated == true
                          ? 'Rapport validé'
                          : 'Valider et transmettre au directeur',
                    ),
                  ),
                ),
              SurfaceCard(
                child: SelectableText(
                  report,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthlyReport(BuildContext context) async {
    final initialMonth = state.paymentReportMonth;
    final loaded = await runApiAction(
      context,
      () => state.loadMonthlyReport(initialMonth),
    );
    if (!loaded || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final month = state.paymentReportMonth;
          final report = state.monthlyReportSnapshot;
          bool inSelectedField(String? fieldId) =>
              state.selectedFieldId == null ||
              fieldId == null ||
              fieldId == state.selectedFieldId;
          final attendance = report.attendance
              .where((record) => inSelectedField(record.fieldId))
              .toList();
          final tasks = report.tasks
              .where((record) => inSelectedField(record.fieldId))
              .toList();
          final movements = report.movements
              .where((record) => inSelectedField(record.fieldId))
              .toList();
          final alerts = report.alerts
              .where((record) => inSelectedField(record.fieldId))
              .toList();
          final expenses = report.expenses
              .where((record) => inSelectedField(record.fieldId))
              .toList();
          final payments = state.monthlyPaymentsForSelectedField;
          final sales = report.sales
              .where((record) => inSelectedField(record.fieldId))
              .toList();
          final overtime = state.monthlyOvertimeForSelectedField;
          final expenseTotal = expenses.fold<int>(
            0,
            (sum, expense) => sum + expense.amount,
          );
          final paymentTotal = payments.fold<int>(
            0,
            (sum, payment) => sum + payment.amount,
          );
          final salesTotal = sales.fold<int>(
            0,
            (sum, sale) => sum + sale.totalPrice,
          );

          Future<void> selectMonth(DateTime value) async {
            final success = await runApiAction(
              context,
              () => state.loadMonthlyReport(value),
            );
            if (success && dialogContext.mounted) {
              setDialogState(() {});
            }
          }

          return AlertDialog(
            title: const Text('Récapitulatif mensuel des rapports'),
            content: SizedBox(
              width: MediaQuery.sizeOf(context).width * .9,
              height: MediaQuery.sizeOf(context).height * .62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Mois précédent',
                        onPressed: () =>
                            selectMonth(DateTime(month.year, month.month - 1)),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: month,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              helpText: 'Choisir un mois',
                            );
                            if (selected != null) {
                              await selectMonth(selected);
                            }
                          },
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                          ),
                          label: Text(_monthLabel(month)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mois suivant',
                        onPressed:
                            month.year == DateTime.now().year &&
                                month.month == DateTime.now().month
                            ? null
                            : () => selectMonth(
                                DateTime(month.year, month.month + 1),
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Text(
                    '${state.monthlyReportValidatedDates.length} journée(s) validée(s) par l’assistant',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _monthlyMetric(
                        'Présences',
                        '${attendance.where((record) => record.status == AttendanceStatus.present).length} présentes · ${attendance.where((record) => record.status == AttendanceStatus.absent).length} absences',
                      ),
                      _monthlyMetric('Tâches', '${tasks.length}'),
                      _monthlyMetric('Mouvements stock', '${movements.length}'),
                      _monthlyMetric('Dépenses', formatCfa(expenseTotal)),
                      _monthlyMetric('Paiements', formatCfa(paymentTotal)),
                      _monthlyMetric('Ventes', formatCfa(salesTotal)),
                      _monthlyMetric(
                        'Heures sup.',
                        '${overtime.fold<double>(0, (sum, item) => sum + item.hours).toStringAsFixed(1)} h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        _monthlyTable(
                          context,
                          'Présences',
                          const [
                            'Date',
                            'Ouvrier',
                            'Statut',
                            'Arrivée',
                            'Départ',
                            'Champ',
                          ],
                          attendance.map((record) {
                            final worker = state.workers
                                .where((item) => item.id == record.workerId)
                                .firstOrNull;
                            return [
                              formatShortDate(record.date),
                              worker?.name ?? 'Ouvrier',
                              record.status == AttendanceStatus.present
                                  ? 'Présent'
                                  : 'Absent',
                              record.checkIn == null
                                  ? '—'
                                  : formatTime(record.checkIn!),
                              record.checkOut == null
                                  ? '—'
                                  : formatTime(record.checkOut!),
                              record.fieldName ?? '—',
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Tâches',
                          const ['Date', 'Tâche', 'État', 'Champ'],
                          tasks.map((task) {
                            return [
                              formatShortDate(task.createdAt),
                              task.title,
                              switch (task.status) {
                                FieldTaskStatus.aFaire => 'À faire',
                                FieldTaskStatus.enCours => 'En cours',
                                FieldTaskStatus.termine => 'Terminée',
                              },
                              task.fieldName ?? '—',
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Mouvements de stock',
                          const [
                            'Date',
                            'Matériel',
                            'Type',
                            'Quantité',
                            'Motif',
                            'Montant',
                            'Champ',
                          ],
                          movements.map((movement) {
                            return [
                              formatShortDate(movement.recordedAt),
                              _itemName(movement.itemId),
                              movement.kind == StockMovementKind.receipt
                                  ? 'Entrée'
                                  : 'Sortie',
                              movement.quantity.toStringAsFixed(1),
                              movement.description,
                              movement.paidAmount == null
                                  ? '—'
                                  : formatCfa(movement.paidAmount!),
                              movement.fieldName ?? '—',
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Alertes matériel',
                          const [
                            'Date',
                            'Matériel',
                            'Alerte',
                            'Quantité',
                            'Motif',
                            'État',
                            'Champ',
                          ],
                          alerts.map((alert) {
                            return [
                              formatShortDate(alert.recordedAt),
                              _itemName(alert.itemId),
                              alert.kind == MaterialAlertKind.delivery
                                  ? 'Livraison'
                                  : 'Manque',
                              alert.quantity.toStringAsFixed(1),
                              alert.description,
                              alert.resolved ? 'Résolue' : 'En attente',
                              alert.fieldName ?? '—',
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Dépenses',
                          const [
                            'Date',
                            'Champ',
                            'Motif',
                            'Montant',
                            'Enregistré par',
                          ],
                          expenses.map((expense) {
                            return [
                              formatShortDate(expense.recordedAt),
                              expense.fieldName ?? '—',
                              expense.description,
                              formatCfa(expense.amount),
                              expense.recordedBy,
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Paiements',
                          const [
                            'Ouvrier',
                            'Champ',
                            'Période payée',
                            'Date',
                            'Montant',
                            'Enregistré par',
                          ],
                          payments.map((payment) {
                            final worker = state.workers
                                .where((item) => item.id == payment.workerId)
                                .firstOrNull;
                            return [
                              worker?.name ?? 'Ouvrier supprimé',
                              payment.fieldName ?? '—',
                              payment.paidThroughEnd == null
                                  ? 'Non précisée'
                                  : 'Jusqu’au ${formatShortDate(payment.paidThroughEnd!)}',
                              formatShortDate(payment.recordedAt),
                              formatCfa(payment.amount),
                              payment.recordedBy,
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Ventes de récolte',
                          const [
                            'Date',
                            'Produit',
                            'Quantité',
                            'Montant',
                            'Champ',
                            'Enregistré par',
                          ],
                          sales.map((sale) {
                            return [
                              formatShortDate(sale.recordedAt),
                              sale.product,
                              sale.quantity.toStringAsFixed(1),
                              formatCfa(sale.totalPrice),
                              sale.fieldName ?? '—',
                              sale.recordedBy,
                            ];
                          }).toList(),
                        ),
                        _monthlyTable(
                          context,
                          'Heures supplémentaires',
                          const ['Date', 'Ouvrier', 'Heures', 'Motif', 'Champ'],
                          overtime.map((record) {
                            final worker = state.workers
                                .where((item) => item.id == record.workerId)
                                .firstOrNull;
                            return [
                              formatShortDate(record.recordedAt),
                              worker?.name ?? 'Ouvrier',
                              '${record.hours.toStringAsFixed(1)} h',
                              record.description,
                              record.fieldName ?? '—',
                            ];
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _monthlyMetric(String label, String value) => Chip(
    label: Text('$label : $value'),
    visualDensity: VisualDensity.compact,
  );

  Widget _monthlyTable(
    BuildContext context,
    String title,
    List<String> columns,
    List<List<String>> rows,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            const Text('Aucune donnée pour cette rubrique.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final column in columns) DataColumn(label: Text(column)),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      cells: [for (final cell in row) DataCell(Text(cell))],
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

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

  String _reportText(
    List<AttendanceRecord> attendanceRecords,
    List<FieldTask> tasks,
    List<StockMovement> movements,
    List<MaterialAlert> alerts,
    List<Expense> expenses,
    List<Payment> payments,
    List<HarvestSale> sales,
  ) {
    final field = state.fields
        .where((field) => field.id == state.selectedFieldId)
        .firstOrNull
        ?.name;
    final dailyTasks = tasks
        .where((task) => _sameDate(task.createdAt, state.selectedDate))
        .toList();
    final dailyMovements = movements
        .where((movement) => _sameDate(movement.recordedAt, state.selectedDate))
        .toList();
    final dailyAlerts = alerts
        .where((alert) => _sameDate(alert.recordedAt, state.selectedDate))
        .toList();
    final dailyExpenses = expenses
        .where((expense) => _sameDate(expense.recordedAt, state.selectedDate))
        .toList();
    final dailyPayments = payments
        .where((payment) => _sameDate(payment.recordedAt, state.selectedDate))
        .toList();
    final dailySales = sales
        .where((sale) => _sameDate(sale.recordedAt, state.selectedDate))
        .toList();
    final workerNames = {
      for (final worker in state.workersForSelectedField)
        worker.id: worker.name,
    };
    return [
      'RAPPORT QUOTIDIEN — INVENTA',
      'Destinataire : Directeur',
      'Date : ${formatShortDate(state.selectedDate)}',
      if (field != null) 'Champ : $field',
      '',
      'ÉQUIPE ET PRÉSENCES',
      'Présents : ${attendanceRecords.where((record) => record.status == AttendanceStatus.present).length}',
      'Absents : ${attendanceRecords.where((record) => record.status == AttendanceStatus.absent).length}',
      for (final record in attendanceRecords)
        '- ${workerNames[record.workerId] ?? 'Ouvrier'} : '
            '${record.status == AttendanceStatus.present ? 'présent' : 'absent'}, '
            'arrivée ${record.checkIn == null ? 'non notée' : formatTime(record.checkIn!)}, '
            'départ ${record.checkOut == null ? 'non noté' : formatTime(record.checkOut!)}',
      '',
      'TÂCHES',
      if (dailyTasks.isEmpty)
        '- Aucune tâche créée ce jour'
      else
        for (final task in dailyTasks)
          '- ${task.title} (${switch (task.status) {
            FieldTaskStatus.aFaire => 'à faire',
            FieldTaskStatus.enCours => 'en cours',
            FieldTaskStatus.termine => 'terminée',
          }})',
      '',
      'MATÉRIEL',
      if (dailyMovements.isEmpty)
        '- Aucun mouvement de stock ce jour'
      else
        for (final movement in dailyMovements.take(10))
          '- ${movement.kind == StockMovementKind.receipt ? 'Entrée' : 'Sortie'} : '
              '${_itemName(movement.itemId)} x${movement.quantity.toStringAsFixed(0)} '
              '— ${movement.description}'
              '${movement.kind == StockMovementKind.receipt && movement.paidAmount != null ? ' — payé ${formatCfa(movement.paidAmount!)}' : ''}',
      if (dailyAlerts.isNotEmpty)
        for (final alert in dailyAlerts)
          '- ${alert.kind == MaterialAlertKind.delivery ? 'Livraison à valider' : 'Manque signalé'} : '
              '${_itemName(alert.itemId)} x${alert.quantity.toStringAsFixed(0)} '
              '— ${alert.description}${alert.resolved ? ' (traité)' : ' (à traiter)'}',
      '',
      'DÉPENSES',
      if (dailyExpenses.isEmpty)
        '- Aucune dépense enregistrée ce jour'
      else
        for (final expense in dailyExpenses.take(10))
          '- ${expense.description} : ${formatCfa(expense.amount)}',
      'Total des dépenses du jour : ${formatCfa(dailyExpenses.fold<int>(0, (total, expense) => total + expense.amount))}',
      '',
      'VENTES DE PRODUITS RÉCOLTÉS',
      if (dailySales.isEmpty)
        '- Aucune vente enregistrée ce jour'
      else
        for (final sale in dailySales)
          '- ${sale.product} : ${sale.quantity.toStringAsFixed(2).replaceAll('.', ',')} vendus · '
              'prix total ${formatCfa(sale.totalPrice)} · ${sale.recordedBy}',
      'Total des ventes du jour : ${formatCfa(dailySales.fold<int>(0, (total, sale) => total + sale.totalPrice))}',
      '',
      'PAIES CONFIRMÉES',
      if (dailyPayments.isEmpty)
        '- Aucune paie confirmée ce jour'
      else
        for (final payment in dailyPayments)
          '- ${workerNames[payment.workerId] ?? 'Ouvrier'} : ${formatCfa(payment.amount)} à ${formatTime(payment.recordedAt)} par ${payment.recordedBy}',
    ].join('\n');
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _itemName(String itemId) =>
      state.stockItemsForSelectedField
          .where((item) => item.id == itemId)
          .firstOrNull
          ?.name ??
      'Matériel';
}
