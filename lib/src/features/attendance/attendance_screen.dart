import 'package:flutter/material.dart';

import '../../data/plantation_api.dart';
import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/widgets.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final isManager = RolePermissions.canMarkAttendance(state.role);
    final canEditAttendance = isManager && state.canEditSelectedDate;
    final present = state.presentCount;
    final marked = state.attendanceRecords.values
        .where(
          (record) =>
              record.date.year == state.selectedDate.year &&
              record.date.month == state.selectedDate.month &&
              record.date.day == state.selectedDate.day &&
              record.status != AttendanceStatus.unmarked,
        )
        .length;
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Présences',
            subtitle: 'Le pointage de votre équipe',
            action: isManager
                ? FilledButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(formatShortDate(state.selectedDate)),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(formatShortDate(state.selectedDate)),
                  ),
          ),
          if (state.api == null && !isManager) ...[
            const DemoNotice(),
            const SizedBox(height: 14),
          ],
          if (isManager && !state.canEditSelectedDate) ...[
            const SurfaceCard(
              child: Text(
                'Cette date est passée. Les pointages sont consultables, mais ne peuvent plus être modifiés.',
              ),
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SummaryCard(
                label: 'Présents',
                value: '$present',
                icon: Icons.check_circle_outline,
                tint: AppColors.leaf,
              ),
              SummaryCard(
                label: 'Absents',
                value: '${marked - present}',
                icon: Icons.cancel_outlined,
                tint: const Color(0xFFBF6658),
              ),
              SummaryCard(
                label: 'Équipe active',
                value: '${state.activeWorkers.length}',
                icon: Icons.groups_outlined,
                tint: const Color(0xFF5472A2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Column(
              children: [
                for (final worker in state.activeWorkers)
                  _AttendanceWorkerRow(
                    worker: worker,
                    record: state.attendanceFor(worker.id),
                    canEdit: canEditAttendance,
                    onCheckIn: () => runApiAction(
                      context,
                      () => state.markAttendance(
                        worker.id,
                        AttendanceStatus.present,
                      ),
                    ),
                    onCheckOut: () => runApiAction(context, () async {
                      if (!await state.checkOutWorker(worker.id)) {
                        throw const ApiException(
                          'Le départ ne peut pas être enregistré.',
                        );
                      }
                    }),
                    onMarkAbsent: () => runApiAction(
                      context,
                      () => state.markAttendance(
                        worker.id,
                        AttendanceStatus.absent,
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

  Future<void> _pickDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choisir une date',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (selected != null && context.mounted) {
      await runApiAction(context, () => state.selectDate(selected));
    }
  }
}

class _AttendanceWorkerRow extends StatelessWidget {
  const _AttendanceWorkerRow({
    required this.worker,
    required this.record,
    required this.canEdit,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onMarkAbsent,
  });

  final Worker worker;
  final AttendanceRecord? record;
  final bool canEdit;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback onMarkAbsent;

  @override
  Widget build(BuildContext context) {
    final status = record?.status ?? AttendanceStatus.unmarked;
    final statusLabel = switch (status) {
      AttendanceStatus.present => 'Présent',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.unmarked => 'À pointer',
    };
    final statusColor = switch (status) {
      AttendanceStatus.present => AppColors.leaf,
      AttendanceStatus.absent => const Color(0xFFBF6658),
      AttendanceStatus.unmarked => AppColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                Text(
                  worker.group,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(label: statusLabel, color: statusColor),
              if (record?.checkIn != null)
                Text(
                  'Arrivée ${formatTime(record!.checkIn!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (record?.checkOut != null)
                Text(
                  'Départ ${formatTime(record!.checkOut!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(width: 5),
            if (status != AttendanceStatus.present)
              IconButton(
                tooltip: 'Enregistrer l’arrivée de ${worker.name}',
                onPressed: onCheckIn,
                icon: const Icon(Icons.login),
                color: AppColors.forest,
              )
            else if (record?.checkOut == null)
              IconButton(
                tooltip: 'Enregistrer le départ de ${worker.name}',
                onPressed: onCheckOut,
                icon: const Icon(Icons.logout),
                color: AppColors.cocoa,
              ),
            PopupMenuButton<String>(
              tooltip: 'Autres actions pour ${worker.name}',
              onSelected: (_) => onMarkAbsent(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'absent', child: Text('Marquer absent')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ],
      ),
    );
  }
}
