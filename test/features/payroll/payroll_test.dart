import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';
import 'package:inventa/src/features/payroll/payroll_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

Future<void> _openSection(WidgetTester tester, String section) async {
  await tester.tap(find.byTooltip('Toutes les rubriques'));
  await tester.pumpAndSettle();
  final sectionItem = find.text(section).last;
  await tester.ensureVisible(sectionItem);
  await tester.tap(sectionItem);
  await tester.pumpAndSettle();
}

void main() {
  test('monthly salary estimate prorates completed clocked hours', () {
    final state = PlantationState(seedDemoData: false);
    const worker = Worker(
      id: '1',
      name: 'Koffi Yao',
      group: 'Nord',
      salary: 120000,
      active: true,
    );
    state.workers = [worker];
    state.payrollMonth = DateTime(2026, 10);
    state.monthlyRequiredHours = 160;
    state.payrollAttendanceRecords = {
      '2026-10-1:1': AttendanceRecord(
        workerId: '1',
        date: DateTime(2026, 10, 1),
        status: AttendanceStatus.present,
        checkIn: DateTime(2026, 10, 1, 8),
        checkOut: DateTime(2026, 10, 1, 12),
      ),
      '2026-10-2:1': AttendanceRecord(
        workerId: '1',
        date: DateTime(2026, 10, 2),
        status: AttendanceStatus.absent,
      ),
      '2026-11-1:1': AttendanceRecord(
        workerId: '1',
        date: DateTime(2026, 11, 1),
        status: AttendanceStatus.present,
        checkIn: DateTime(2026, 11, 1, 8),
        checkOut: DateTime(2026, 11, 1, 16),
      ),
    };

    expect(state.presentDaysFor(worker.id), 1);
    expect(state.workedMinutesFor(worker.id), 240);
    expect(state.estimatedPayrollFor(worker), 3000);
    expect(state.hourlyRateFor(worker), 750);
    expect(state.estimatedPayrollTotal, 3000);
    state.dispose();
  });
  test(
    'director approval is required before assistant records a payment',
    () async {
      final state = PlantationState()
        ..payments = []
        ..setRole(UserRole.assistant)
        ..payrollDueAmounts['w2'] = 3500;
      final scheduledDate = DateTime.now();
      expect(await state.requestPayroll('w2', scheduledDate), isTrue);
      final request = state.payrollRequests.single;
      expect(request.status, PayrollRequestStatus.pending);
      expect(state.payments, isEmpty);

      state.setRole(UserRole.director);
      expect(
        await state.decidePayrollRequest(request.id, approve: true),
        isTrue,
      );
      state.setRole(UserRole.assistant);
      expect(await state.confirmPayrollPaid(request.id, scheduledDate), isTrue);
      expect(state.payments.single.amount, 3500);
      expect(state.payments.single.recordedBy, UserRole.assistant.label);
      expect(state.payrollRequests.single.status, PayrollRequestStatus.paid);
      state.dispose();
    },
  );

  testWidgets('director payroll is read only and has no overtime action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Changer de profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Directeur'));
    await tester.pumpAndSettle();
    await _openSection(tester, 'Paie');

    expect(find.text('Confirmer le paiement'), findsNothing);
    expect(find.text('Heures sup.'), findsNothing);
    expect(find.text('Salaire estimé selon les heures'), findsOneWidget);
  });

  testWidgets('assistant pays a worker directly from the worker row', (
    tester,
  ) async {
    final state = PlantationState()
      ..setRole(UserRole.assistant)
      ..monthlyRequiredHours = 8
      ..payrollMonth = DateTime(DateTime.now().year, DateTime.now().month)
      ..payments = [];
    addTearDown(state.dispose);
    final originalWorker = state.activeWorkers.first;
    final worker = Worker(
      id: originalWorker.id,
      name: originalWorker.name,
      group: originalWorker.group,
      salary: 80000,
      active: true,
      fieldId: originalWorker.fieldId,
      fieldName: originalWorker.fieldName,
    );
    state.workers = [
      for (final value in state.workers)
        if (value.id == worker.id) worker else value,
    ];
    final attendanceDay = DateTime(
      state.payrollMonth.year,
      state.payrollMonth.month,
      1,
    );
    state.payrollAttendanceRecords = {
      'payroll:${worker.id}': AttendanceRecord(
        workerId: worker.id,
        date: attendanceDay,
        status: AttendanceStatus.present,
        checkIn: DateTime(
          attendanceDay.year,
          attendanceDay.month,
          attendanceDay.day,
          8,
        ),
        checkOut: DateTime(
          attendanceDay.year,
          attendanceDay.month,
          attendanceDay.day,
          16,
        ),
      ),
    };
    expect(state.workedMinutesFor(worker.id), 480);
    expect(state.estimatedPayrollFor(worker), 80000);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PayrollScreen(state: state)),
        ),
      ),
    );
    expect(find.textContaining('Mois : 80 000 F'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    final payButton = find.text('Payer').first;
    await tester.ensureVisible(payButton);
    await tester.tap(payButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payer').last);
    await tester.pumpAndSettle();

    expect(state.payments, hasLength(1));
    expect(state.payments.single.amount, 80000);
    expect(state.payments.single.workerId, worker.id);
    expect(state.payments.single.recordedBy, UserRole.assistant.label);
    expect(state.payrollDueFor(worker), 0);
    expect(find.text('Paiement enregistré'), findsOneWidget);
  });

  testWidgets('field manager cannot open the payroll page', (tester) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();

    expect(find.text('Paie'), findsNothing);
    expect(find.text('Toutes les rubriques'), findsOneWidget);
  });

  testWidgets('director configures monthly full-time hours', (tester) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Changer de profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Directeur'));
    await tester.pumpAndSettle();
    await _openSection(tester, 'Paie');

    await tester.tap(find.text('Salaire'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Salaire mensuel de référence (F CFA)',
      ),
      '100000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Heures complètes par mois'),
      '160',
    );
    await tester.tap(find.text('Enregistrer les paramètres'));
    await tester.pumpAndSettle();

    expect(find.text('Salaire de référence · 160 h complètes'), findsOneWidget);
  });

  testWidgets('field manager cannot access payroll or payment history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();

    expect(find.text('Paie'), findsNothing);
    expect(find.text('Derniers paiements'), findsNothing);
    expect(find.text('Confirmer le paiement'), findsNothing);
    expect(find.byTooltip('Enregistrer un paiement'), findsNothing);
  });
}
