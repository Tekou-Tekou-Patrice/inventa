import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';
import 'package:inventa/src/state/role_permissions.dart';

void main() {
  group('Role permissions', () {
    test(
      'payment and overtime actions are limited to their assigned roles',
      () {
        expect(RolePermissions.canRecordPayment(UserRole.assistant), isTrue);
        expect(RolePermissions.canRecordPayment(UserRole.director), isFalse);
        expect(
          RolePermissions.canRecordPayment(UserRole.fieldManager),
          isFalse,
        );
        expect(
          RolePermissions.canRecordHarvestSale(UserRole.assistant),
          isTrue,
        );
        expect(
          RolePermissions.canRecordHarvestSale(UserRole.fieldManager),
          isTrue,
        );
        expect(
          RolePermissions.canRecordHarvestSale(UserRole.director),
          isFalse,
        );
        expect(
          RolePermissions.canRecordOvertime(UserRole.fieldManager),
          isTrue,
        );
        expect(RolePermissions.canRecordOvertime(UserRole.assistant), isFalse);
        expect(RolePermissions.canManageWorkers(UserRole.fieldManager), isTrue);
        expect(RolePermissions.canManageWorkers(UserRole.director), isFalse);
      },
    );

    test('each role sees only its assigned sections and data', () {
      expect(RolePermissions.visibleSections(UserRole.director), {
        AppSection.dashboard,
        AppSection.fields,
        AppSection.attendance,
        AppSection.workers,
        AppSection.accounts,
        AppSection.tasks,
        AppSection.report,
        AppSection.payroll,
        AppSection.stock,
        AppSection.expenses,
      });
      expect(RolePermissions.visibleSections(UserRole.assistant), {
        AppSection.dashboard,
        AppSection.attendance,
        AppSection.workers,
        AppSection.tasks,
        AppSection.report,
        AppSection.stock,
        AppSection.expenses,
        AppSection.payroll,
      });
      expect(RolePermissions.visibleSections(UserRole.fieldManager), {
        AppSection.dashboard,
        AppSection.attendance,
        AppSection.workers,
        AppSection.tasks,
        AppSection.stock,
        AppSection.expenses,
      });
      expect(RolePermissions.canViewTasks(UserRole.director), isTrue);
      expect(RolePermissions.canViewExpenses(UserRole.director), isTrue);
      expect(RolePermissions.canViewBudget(UserRole.director), isTrue);
      expect(RolePermissions.canViewBudget(UserRole.assistant), isTrue);
      expect(RolePermissions.canViewBudget(UserRole.fieldManager), isTrue);
      expect(RolePermissions.canSetBudgetLimit(UserRole.director), isTrue);
      expect(RolePermissions.canSetBudgetLimit(UserRole.assistant), isFalse);
      expect(RolePermissions.canAllocateBudget(UserRole.assistant), isTrue);
      expect(RolePermissions.canAllocateBudget(UserRole.director), isFalse);
      expect(
        RolePermissions.canRecordBudgetExpense(UserRole.assistant),
        isTrue,
      );
      expect(
        RolePermissions.canRecordBudgetExpense(UserRole.fieldManager),
        isTrue,
      );
      expect(RolePermissions.canViewStock(UserRole.director), isTrue);
      expect(RolePermissions.canViewAttendance(UserRole.assistant), isTrue);
      expect(RolePermissions.canViewPayments(UserRole.fieldManager), isFalse);
      expect(
        RolePermissions.canViewPayrollEstimate(UserRole.fieldManager),
        isFalse,
      );
      expect(RolePermissions.canViewOvertime(UserRole.assistant), isFalse);
      expect(RolePermissions.canManageAccounts(UserRole.director), isTrue);
      expect(RolePermissions.canManageAccounts(UserRole.assistant), isFalse);
      expect(RolePermissions.canManageAccounts(UserRole.fieldManager), isFalse);
      expect(RolePermissions.canManageFields(UserRole.director), isTrue);
      expect(RolePermissions.canManageFields(UserRole.assistant), isFalse);
      expect(
        RolePermissions.canManageWorkerContacts(UserRole.assistant),
        isTrue,
      );
      expect(
        RolePermissions.canManageWorkerContacts(UserRole.director),
        isFalse,
      );
      expect(RolePermissions.canManageWorkerSalary(UserRole.assistant), isTrue);
      expect(RolePermissions.canManageWorkerSalary(UserRole.director), isTrue);
      expect(
        RolePermissions.canManageWorkerSalary(UserRole.fieldManager),
        isFalse,
      );
      expect(RolePermissions.canApprovePayroll(UserRole.director), isTrue);
      expect(RolePermissions.canApprovePayroll(UserRole.assistant), isFalse);
    });

    test('state rejects unauthorized payments and overtime', () async {
      final state = PlantationState();
      expect(await state.requestPayroll('w1', DateTime.now()), isFalse);
      expect(await state.addOvertime('w1', 2, 'Récolte'), isTrue);
      expect(state.payments, hasLength(1));
      expect(state.overtimeRecords, hasLength(1));

      state.setRole(UserRole.director);
      expect(await state.requestPayroll('w1', DateTime.now()), isFalse);
      expect(await state.addOvertime('w1', 2, 'Récolte'), isFalse);

      state.setRole(UserRole.assistant);
      state.payrollDueAmounts['w1'] = 3000;
      expect(await state.requestPayroll('w1', DateTime.now()), isTrue);
      expect(await state.addOvertime('w1', 2, 'Récolte'), isFalse);
      state.dispose();
    });

    test(
      'shared salary updates defaults but preserves individual adjustments',
      () async {
        final state = PlantationState();
        final individualWorker = state.workers[1];
        state.setRole(UserRole.assistant);
        await state.updateWorkerSalary(individualWorker.id, 125000);

        state.setRole(UserRole.director);
        expect(
          await state.savePayrollSettings(salary: 110000, requiredHours: 200),
          isTrue,
        );
        expect(state.monthlySalary, 110000);
        expect(
          state.workers.firstWhere((worker) => worker.id == 'w1').salary,
          110000,
        );
        final adjusted = state.workers.firstWhere(
          (worker) => worker.id == individualWorker.id,
        );
        expect(adjusted.salary, 125000);
        expect(adjusted.salaryIsIndividual, isTrue);
        state.dispose();
      },
    );

    test(
      'assistant and field manager can record sales but director cannot',
      () async {
        final state = PlantationState();
        expect(
          await state.addHarvestSale(
            product: 'Cabosses',
            quantity: 3,
            totalPrice: 15000,
          ),
          isTrue,
        );
        expect(state.sales.single.totalPrice, 15000);

        state.setRole(UserRole.assistant);
        expect(
          await state.addHarvestSale(
            product: 'Fèves',
            quantity: 10,
            totalPrice: 50000,
          ),
          isTrue,
        );
        state.setRole(UserRole.director);
        expect(
          await state.addHarvestSale(
            product: 'Fèves',
            quantity: 10,
            totalPrice: 50000,
          ),
          isFalse,
        );
        expect(state.sales, hasLength(2));
        state.dispose();
      },
    );

    test(
      'assistant and director can modify salary, field manager cannot',
      () async {
        final state = PlantationState();
        final worker = state.workers.first;

        state.setRole(UserRole.fieldManager);
        await state.updateWorkerSalary(worker.id, 120000);
        expect(
          state.workers.firstWhere((value) => value.id == worker.id).salary,
          worker.salary,
        );

        state.setRole(UserRole.director);
        await state.updateWorkerSalary(worker.id, 120000);
        expect(
          state.workers.firstWhere((value) => value.id == worker.id).salary,
          120000,
        );

        state.setRole(UserRole.assistant);
        await state.updateWorkerSalary(worker.id, 160000);
        expect(
          state.workers.firstWhere((value) => value.id == worker.id).salary,
          160000,
        );
        state.dispose();
      },
    );

    test('stock usage cannot exceed available stock', () async {
      final state = PlantationState();
      state.setRole(UserRole.fieldManager);
      expect(
        await state.addStockMovement(
          itemId: 's1',
          kind: StockMovementKind.receipt,
          quantity: 25,
          description: 'Réception',
          paidAmount: 5000,
        ),
        isFalse,
      );
      expect(state.stockItems.first.quantity, 24);
      state.dispose();
    });

    test(
      'stock deliveries require a prepared order and field confirmation',
      () async {
        final state = PlantationState();
        final quantityBefore = state.stockItems.first.quantity;
        state.setRole(UserRole.fieldManager);
        await state.reportMaterialAlert(
          itemId: 's1',
          kind: MaterialAlertKind.delivery,
          quantity: 4,
          description: 'Livraison de sacs au champ',
        );

        expect(state.materialAlerts, isEmpty);
        expect(state.stockItems.first.quantity, quantityBefore);
        state.materialAlerts = [
          MaterialAlert(
            id: 'legacy-delivery',
            itemId: 's1',
            kind: MaterialAlertKind.delivery,
            quantity: 4,
            description: 'Ancienne livraison',
            recordedAt: DateTime.now(),
            recordedBy: UserRole.fieldManager.label,
          ),
        ];
        state.setRole(UserRole.assistant);
        expect(await state.resolveMaterialAlert('legacy-delivery'), isFalse);
        expect(state.stockItems.first.quantity, quantityBefore);
        expect(state.materialAlerts.single.resolved, isFalse);
        state.dispose();
      },
    );

    test('attendance records remain separate for selected dates', () async {
      final state = PlantationState();
      final today = DateTime.now();
      final anotherDate = today.add(const Duration(days: 1));
      expect(state.attendanceFor('w1')?.status, AttendanceStatus.present);

      await state.selectDate(anotherDate);
      expect(state.attendanceFor('w1'), isNull);
      await state.markAttendance('w1', AttendanceStatus.absent);
      await state.selectDate(today);

      expect(state.attendanceFor('w1')?.status, AttendanceStatus.present);
      await state.selectDate(anotherDate);
      expect(state.attendanceFor('w1')?.status, AttendanceStatus.absent);
      state.dispose();
    });

    test('field selection keeps demonstration records separated', () async {
      final state = PlantationState();
      state.setRole(UserRole.director);

      await state.selectField('field-douala');

      expect(state.workersForSelectedField.map((worker) => worker.id), {
        'w2',
        'w3',
        'w5',
      });
      expect(state.stockItemsForSelectedField.map((item) => item.id), {
        's2',
        's3',
      });
      expect(state.tasksForSelectedField.single.id, 't2');
      expect(
        state.expensesForSelectedField.map((expense) => expense.description),
        {'Petit matériel'},
      );

      await state.selectField(null);
      expect(state.workersForSelectedField, hasLength(5));
      state.dispose();
    });

    test(
      'field manager is limited to the assigned field and its screens',
      () async {
        final state = PlantationState();
        state
          ..setAssignedFieldId('field-douala')
          ..setRole(UserRole.fieldManager);
        state.workers = [
          ...state.workers,
          const Worker(
            id: 'unassigned',
            name: 'Ouvrier sans champ',
            group: 'Équipe',
            salary: 90000,
            active: true,
          ),
        ];

        await state.selectField('field-yaounde');

        expect(state.selectedFieldId, 'field-douala');
        expect(
          state.workersForSelectedField.map((worker) => worker.id).toSet(),
          {'w2', 'w3', 'w5'},
        );
        expect(RolePermissions.visibleSections(state.role), {
          AppSection.dashboard,
          AppSection.attendance,
          AppSection.workers,
          AppSection.tasks,
          AppSection.stock,
          AppSection.expenses,
        });
        state.dispose();
      },
    );
  });
}
