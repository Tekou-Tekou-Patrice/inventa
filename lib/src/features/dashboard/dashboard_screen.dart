import 'package:flutter/material.dart';

import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.state,
    required this.onNavigate,
    super.key,
  });

  final PlantationState state;
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 12 => 'Bonjour',
      < 18 => 'Bon après-midi',
      _ => 'Bonsoir',
    };
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Bonjour, ${state.role.shortLabel} 👋',
            subtitle: '$greeting — ${formatShortDate(now)}',
            action: RolePermissions.canMarkAttendance(state.role)
                ? FilledButton.icon(
                    onPressed: () => onNavigate(AppSection.attendance),
                    icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                    label: const Text('Faire le pointage'),
                  )
                : null,
          ),
          if (state.api == null) const DemoNotice(),
          if (state.pendingOfflineOperations > 0)
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.cocoa,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${state.pendingOfflineOperations} opération(s) en attente. '
                      'Envoi automatique dès le retour du réseau.',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 13,
            runSpacing: 13,
            children: [
              SummaryCard(
                label: 'Ouvriers actifs',
                value: '${state.activeWorkers.length}',
                icon: Icons.person_outline,
                tint: AppColors.cocoa,
                detail: 'Dans votre équipe',
              ),
              if (RolePermissions.canViewAttendance(state.role))
                SummaryCard(
                  label: 'Présents pointés',
                  value:
                      '${state.presentCount} / ${state.activeWorkers.length}',
                  icon: Icons.groups_2_outlined,
                  tint: AppColors.leaf,
                  detail: 'Pointage du ${formatShortDate(state.selectedDate)}',
                ),
              if (RolePermissions.canViewPayrollEstimate(state.role))
                SummaryCard(
                  label: 'Paie estimée du mois',
                  value: formatCfa(state.estimatedPayrollTotal),
                  icon: Icons.calculate_outlined,
                  tint: AppColors.cocoa,
                  detail:
                      'Salaires individuels · au prorata des heures pointées',
                ),
              if (RolePermissions.canViewStock(state.role))
                SummaryCard(
                  label: 'Stock disponible',
                  value: '${state.stockQuantity} unités',
                  icon: Icons.inventory_2_outlined,
                  tint: const Color(0xFF5472A2),
                  detail: 'Tous les articles',
                ),
              if (RolePermissions.canViewExpenses(state.role))
                SummaryCard(
                  label: 'Dépenses du jour',
                  value: formatCfa(state.dailyExpenseTotal),
                  icon: Icons.account_balance_wallet_outlined,
                  tint: const Color(0xFFC17839),
                  detail: 'Enregistrées aujourd’hui',
                ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final activity = _ActivityCard(state: state);
              final shortcuts = _ShortcutsCard(
                state: state,
                onNavigate: onNavigate,
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: activity),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: shortcuts),
                  ],
                );
              }
              return Column(
                children: [activity, const SizedBox(height: 16), shortcuts],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.state});

  final PlantationState state;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Activité récente'),
        if (state.expensesForSelectedField.isEmpty &&
            state.paymentsForSelectedField.isEmpty &&
            state.stockMovementsForSelectedField.isEmpty)
          const EmptyState(
            title: 'Pas encore d’activité',
            description: 'Les dernières opérations apparaîtront ici.',
          )
        else ...[
          for (final expense in state.expensesForSelectedField.take(2))
            _ActivityRow(
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFC17839),
              title: expense.description,
              subtitle:
                  '${expense.fieldName == null ? '' : '${expense.fieldName} · '}${formatRelativeTime(expense.recordedAt)} · Dépense',
              amount: '- ${formatCfa(expense.amount)}',
            ),
          for (final payment in state.paymentsForSelectedField.take(2))
            _ActivityRow(
              icon: Icons.payments_outlined,
              color: AppColors.leaf,
              title: 'Paiement — ${_workerName(state, payment.workerId)}',
              subtitle:
                  '${payment.fieldName == null ? '' : '${payment.fieldName} · '}${formatRelativeTime(payment.recordedAt)} · Paie',
              amount: '- ${formatCfa(payment.amount)}',
            ),
          for (final movement in state.stockMovementsForSelectedField.take(1))
            _ActivityRow(
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF5472A2),
              title: movement.description,
              subtitle:
                  '${movement.fieldName == null ? '' : '${movement.fieldName} · '}${formatRelativeTime(movement.recordedAt)} · ${movement.kind == StockMovementKind.receipt ? 'Entrée en stock' : 'Utilisation'}',
              amount:
                  '${movement.kind == StockMovementKind.receipt ? '+' : '−'} ${movement.quantity.toStringAsFixed(0)}',
            ),
        ],
      ],
    ),
  );
}

String _workerName(PlantationState state, String id) =>
    state.workersForSelectedField
        .where((worker) => worker.id == id)
        .firstOrNull
        ?.name ??
    'Ouvrier';

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
      ],
    ),
  );
}

class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard({required this.state, required this.onNavigate});

  final PlantationState state;
  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Accès rapides'),
        for (final section
            in [
              AppSection.attendance,
              AppSection.workers,
              AppSection.accounts,
              AppSection.tasks,
              AppSection.report,
              AppSection.stock,
            ]..removeWhere(
              (section) => !RolePermissions.visibleSections(
                state.role,
              ).contains(section),
            ))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_iconFor(section), color: AppColors.forest, size: 21),
            title: Text(section.label),
            trailing: const Icon(Icons.chevron_right, size: 19),
            onTap: () => onNavigate(section),
          ),
      ],
    ),
  );
}

IconData _iconFor(AppSection section) => switch (section) {
  AppSection.dashboard => Icons.space_dashboard_outlined,
  AppSection.fields => Icons.landscape_outlined,
  AppSection.attendance => Icons.fact_check_outlined,
  AppSection.workers => Icons.groups_outlined,
  AppSection.accounts => Icons.manage_accounts_outlined,
  AppSection.tasks => Icons.assignment_outlined,
  AppSection.report => Icons.summarize_outlined,
  AppSection.stock => Icons.inventory_2_outlined,
  AppSection.expenses => Icons.receipt_long_outlined,
  AppSection.payroll => Icons.payments_outlined,
};
