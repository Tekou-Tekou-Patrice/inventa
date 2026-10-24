import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/offline_operation_store.dart';
import '../data/plantation_api.dart';
import '../models/plantation_models.dart';
import 'role_permissions.dart';

class PlantationState extends ChangeNotifier {
  static int _fieldExpenseSequence = 0;
  Timer? _offlineSyncTimer;
  bool _syncingFieldOperations = false;
  final Set<String> _appliedOfflineOperationIds = {};
  final Future<bool> Function() _networkAvailable;

  static Future<bool> _checkNetworkAvailability() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } on MissingPluginException {
      return true;
    }
  }

  PlantationState({
    this.api,
    bool seedDemoData = true,
    Future<OfflineOperationStore> Function()? offlineStoreFactory,
    Future<bool> Function()? networkAvailable,
  }) : _offlineStoreFactory =
           offlineStoreFactory ?? OfflineOperationStore.openDefault,
       _networkAvailable = networkAvailable ?? _checkNetworkAvailability {
    accounts = [];
    fields = seedDemoData
        ? const [
            PlantationField(
              id: 'field-yaounde',
              name: 'Champ de Yaoundé',
              location: 'Yaoundé',
            ),
            PlantationField(
              id: 'field-douala',
              name: 'Champ de Douala',
              location: 'Douala',
            ),
          ]
        : [];
    if (seedDemoData) selectedFieldId = fields.firstOrNull?.id;
    if (!seedDemoData) {
      workers = [];
      stockItems = [];
      tasks = [];
      attendanceRecords = {};
      payrollAttendanceRecords = {};
      expenses = [];
      payments = [];
      sales = [];
      payrollRequests = [];
      payrollDueAmounts = {};
      dailyReportSnapshot = const DailyReportSnapshot();
      overtimeRecords = [];
      stockMovements = [];
      stockOrders = [];
      budgetSummary = null;
      return;
    }

    final now = DateTime.now();
    workers = [
      const Worker(
        id: 'w1',
        name: 'Koffi Yao',
        group: 'Parcelle Nord',
        salary: 90000,
        active: true,
        fieldId: 'field-yaounde',
        fieldName: 'Champ de Yaoundé',
      ),
      const Worker(
        id: 'w2',
        name: 'Ama Kouassi',
        group: 'Parcelle Est',
        salary: 90000,
        active: true,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
      const Worker(
        id: 'w3',
        name: 'Jean-Marc N’Guessan',
        group: 'Parcelle Sud',
        salary: 90000,
        active: true,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
      const Worker(
        id: 'w4',
        name: 'Adjoua Brou',
        group: 'Parcelle Nord',
        salary: 90000,
        active: true,
        fieldId: 'field-yaounde',
        fieldName: 'Champ de Yaoundé',
      ),
      const Worker(
        id: 'w5',
        name: 'Yao Konan',
        group: 'Parcelle Ouest',
        salary: 90000,
        active: true,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
    ];
    stockItems = [
      const StockItem(
        id: 's1',
        name: 'Sacs de fèves',
        unit: 'sacs',
        quantity: 24,
        unitPrice: 6000,
        fieldId: 'field-yaounde',
        fieldName: 'Champ de Yaoundé',
      ),
      const StockItem(
        id: 's2',
        name: 'Engrais organique',
        unit: 'sacs',
        quantity: 18,
        unitPrice: 3500,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
      const StockItem(
        id: 's3',
        name: 'Outils de récolte',
        unit: 'pièces',
        quantity: 12,
        unitPrice: 2500,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
    ];
    tasks = [
      FieldTask(
        id: 't1',
        title: 'Désherbage parcelle nord',
        assigneeIds: const ['w1', 'w4'],
        status: FieldTaskStatus.enCours,
        createdAt: now,
        fieldId: 'field-yaounde',
        fieldName: 'Champ de Yaoundé',
      ),
      FieldTask(
        id: 't2',
        title: 'Récolte des cabosses mûres',
        assigneeIds: const ['w2', 'w3'],
        status: FieldTaskStatus.aFaire,
        createdAt: now,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
    ];
    attendanceRecords = {
      _attendanceKey(now, 'w1'): AttendanceRecord(
        workerId: 'w1',
        date: DateTime(now.year, now.month, now.day),
        status: AttendanceStatus.present,
        checkIn: DateTime(now.year, now.month, now.day, 6, 42),
      ),
      _attendanceKey(now, 'w2'): AttendanceRecord(
        workerId: 'w2',
        date: DateTime(now.year, now.month, now.day),
        status: AttendanceStatus.present,
        checkIn: DateTime(now.year, now.month, now.day, 6, 48),
      ),
    };
    payrollAttendanceRecords = Map.of(attendanceRecords);
    expenses = [
      Expense(
        description: 'Transport des récoltes',
        amount: 12500,
        recordedAt: now.subtract(const Duration(hours: 2)),
        recordedBy: UserRole.fieldManager.label,
        fieldId: 'field-yaounde',
        fieldName: 'Champ de Yaoundé',
      ),
      Expense(
        description: 'Petit matériel',
        amount: 8000,
        recordedAt: now.subtract(const Duration(hours: 4)),
        recordedBy: UserRole.assistant.label,
        fieldId: 'field-douala',
        fieldName: 'Champ de Douala',
      ),
    ];
    payments = [
      Payment(
        workerId: 'w1',
        amount: 3500,
        recordedAt: now.subtract(const Duration(days: 1)),
        recordedBy: UserRole.assistant.label,
      ),
    ];
    sales = [];
    payrollRequests = [];
    payrollDueAmounts = {};
    dailyReportSnapshot = const DailyReportSnapshot();
    overtimeRecords = [];
    stockMovements = [
      StockMovement(
        itemId: 's1',
        kind: StockMovementKind.receipt,
        quantity: 10,
        description: 'Récolte de la semaine',
        recordedAt: now.subtract(const Duration(days: 1)),
        recordedBy: UserRole.assistant.label,
        paidAmount: 45000,
      ),
    ];
    stockOrders = [];
  }

  final PlantationApi? api;
  final Future<OfflineOperationStore> Function() _offlineStoreFactory;
  int pendingOfflineOperations = 0;
  UserRole role = UserRole.fieldManager;
  String? accountId;
  BudgetSummary? budgetSummary;
  late List<PlantationField> fields;
  String? selectedFieldId;
  String? assignedFieldId;
  late List<Worker> workers;
  late List<ManagedAccount> accounts;
  late List<StockItem> stockItems;
  late List<FieldTask> tasks;
  late Map<String, AttendanceRecord> attendanceRecords;
  late Map<String, AttendanceRecord> payrollAttendanceRecords;
  late List<Expense> expenses;
  late List<Payment> payments;
  late List<HarvestSale> sales;
  late List<PayrollPaymentRequest> payrollRequests;
  late Map<String, int> payrollDueAmounts;
  DailyReportSnapshot dailyReportSnapshot = const DailyReportSnapshot();
  late List<OvertimeRecord> overtimeRecords;
  late List<StockMovement> stockMovements;
  late List<StockOrder> stockOrders;
  late List<MaterialAlert> materialAlerts = [];
  DateTime selectedDate = DateTime.now();
  DateTime payrollMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime paymentReportMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  List<Payment> monthlyPaymentReport = [];
  DailyReportSnapshot monthlyReportSnapshot = const DailyReportSnapshot();
  List<OvertimeRecord> monthlyOvertimeReport = [];
  List<DateTime> monthlyReportValidatedDates = [];
  int monthlySalary = 90000;
  int monthlyRequiredHours = 208;

  void setAccountId(String? value) {
    accountId = value;
  }

  @override
  void dispose() {
    _offlineSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final client = api;
    if (client == null) return;
    final store = accountId == null ? null : await _offlineStoreFactory();
    final workspaceKey = accountId == null
        ? null
        : '$accountId|${role.name}|${assignedFieldId ?? '*'}';
    final networkAvailable = await _networkAvailable();
    final offlineResult = networkAvailable || workspaceKey == null
        ? null
        : await store!.readWorkspaceSnapshot(workspaceKey);
    if (!networkAvailable && offlineResult == null) {
      throw const ApiException(
        'Aucune donnée locale disponible. Reconnectez-vous pour charger le terrain.',
      );
    }
    if (RolePermissions.canViewBudget(role) && accountId != null) {
      final cached = await store!.readBudgetSnapshot(accountId!);
      if (cached != null) {
        budgetSummary = _budgetFromJson(cached);
        notifyListeners();
      }
    }
    if (networkAvailable) {
      try {
        await _synchronizeQueuedExpenses(client);
        await _synchronizeQueuedFieldOperations(client);
      } on ApiException catch (error) {
        if (error.statusCode != null) rethrow;
      }
    }
    final date = _dateParam(selectedDate);
    final emptyResult = <dynamic>[];
    late List<dynamic> result;
    if (offlineResult != null) {
      result = offlineResult;
    } else {
      try {
        result = await Future.wait<dynamic>([
          client.request('GET', _withField('/api/workers')),
          if (RolePermissions.canViewAttendance(role))
            client.request('GET', _withField('/api/attendance?date=$date'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewPayrollEstimate(role))
            client.request(
              'GET',
              _withField(
                '/api/attendance/month?month=${_monthParam(payrollMonth)}',
              ),
            )
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewTasks(role))
            client.request('GET', _withField('/api/tasks'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewStock(role))
            client.request('GET', _withField('/api/stock/items'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewStock(role))
            client.request('GET', _withField('/api/stock/movements'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewExpenses(role))
            client.request('GET', _withField('/api/expenses'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewPayments(role))
            client.request('GET', _withField('/api/payments'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewOvertime(role))
            client.request('GET', _withField('/api/overtime'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canManageAccounts(role))
            client.request('GET', '/api/accounts')
          else
            Future.value(emptyResult),
          client.request('GET', '/api/fields'),
          if (RolePermissions.canViewPayrollEstimate(role))
            client.request('GET', '/api/payroll/settings')
          else
            Future.value(null),
          if (RolePermissions.canViewStock(role))
            client.request('GET', _withField('/api/stock/alerts'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewPayments(role))
            client.request(
              'GET',
              '/api/payroll/due?through=${_monthParam(payrollMonth)}',
            )
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewDailyReport(role))
            client.request(
              'GET',
              '/api/reports/daily?date=${_dateParam(selectedDate)}',
            )
          else
            Future.value(null),
          if (RolePermissions.canViewPayments(role))
            client.request('GET', '/api/payroll/requests')
          else
            Future.value(emptyResult),
          if (role == UserRole.assistant ||
              role == UserRole.director ||
              role == UserRole.fieldManager)
            client.request('GET', '/api/stock/orders')
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewStock(role))
            client.request('GET', _withField('/api/sales'))
          else
            Future.value(emptyResult),
          if (RolePermissions.canViewBudget(role))
            client.getBudgetSnapshot(
              fieldManager: role == UserRole.fieldManager,
            )
          else
            Future.value(null),
        ]);
      } on ApiException catch (error) {
        if (error.statusCode != null || workspaceKey == null) rethrow;
        final cached = await store!.readWorkspaceSnapshot(workspaceKey);
        if (cached == null) rethrow;
        result = cached;
      }
    }
    workers = _asList(result[0])
        .map(
          (json) => Worker(
            id: '${json['id']}',
            name: json['name'] as String,
            group: json['group'] as String,
            salary: (json['salary'] as num).round(),
            salaryIsIndividual: json['salaryIsIndividual'] as bool? ?? false,
            active: json['active'] as bool,
            phoneNumber: json['phoneNumber'] as String? ?? '',
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    attendanceRecords = {
      for (final json in _asList(result[1]))
        _attendanceKey(
          DateTime.parse(json['date'] as String),
          '${json['workerId']}',
        ): AttendanceRecord(
          workerId: '${json['workerId']}',
          date: DateTime.parse(json['date'] as String),
          status: json['status'] == 'PRESENT'
              ? AttendanceStatus.present
              : AttendanceStatus.absent,
          checkIn: json['checkIn'] == null
              ? null
              : DateTime.parse(json['checkIn'] as String).toLocal(),
          checkOut: json['checkOut'] == null
              ? null
              : DateTime.parse(json['checkOut'] as String).toLocal(),
          fieldId: json['fieldId']?.toString(),
          fieldName: json['fieldName'] as String?,
        ),
    };
    payrollAttendanceRecords = _attendanceMap(result[2]);
    tasks = _asList(result[3])
        .map(
          (json) => FieldTask(
            id: '${json['id']}',
            title: json['title'] as String,
            assigneeIds: (json['assigneeIds'] as List<dynamic>)
                .map((id) => '$id')
                .toList(),
            status: switch (json['status']) {
              'IN_PROGRESS' => FieldTaskStatus.enCours,
              'DONE' => FieldTaskStatus.termine,
              _ => FieldTaskStatus.aFaire,
            },
            type: json['type'] == 'SEASONAL_WORKERS'
                ? FieldTaskType.seasonalWorkers
                : FieldTaskType.assignedWorkers,
            createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
            completedAt: json['completedAt'] == null
                ? null
                : DateTime.parse(json['completedAt'] as String).toLocal(),
            actualCost: (json['actualCost'] as num?)?.round(),
            seasonalWorkerCount: (json['seasonalWorkerCount'] as num?)?.toInt(),
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    stockItems = _asList(result[4])
        .map(
          (json) => StockItem(
            id: '${json['id']}',
            name: json['name'] as String,
            unit: json['unit'] as String,
            quantity: (json['quantity'] as num).toDouble(),
            unitPrice: (json['unitPrice'] as num?)?.round(),
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    stockMovements = _asList(result[5])
        .map(
          (json) => StockMovement(
            itemId: '${json['itemId']}',
            kind: json['kind'] == 'RECEIPT'
                ? StockMovementKind.receipt
                : StockMovementKind.usage,
            quantity: (json['quantity'] as num).toDouble(),
            description: json['description'] as String,
            recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
            recordedBy: json['recordedBy'] as String,
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
            paidAmount: (json['paidAmount'] as num?)?.round(),
          ),
        )
        .toList();
    expenses = _asList(result[6]).map(_expenseFromJson).toList();
    payments = _asList(result[7])
        .map(
          (json) => Payment(
            workerId: '${json['workerId']}',
            amount: (json['amount'] as num).round(),
            recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
            recordedBy: json['recordedBy'] as String,
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
            paidThroughEnd: json['paidThroughEnd'] == null
                ? null
                : DateTime.parse(json['paidThroughEnd'] as String).toLocal(),
          ),
        )
        .toList();
    overtimeRecords = _asList(result[8])
        .map(
          (json) => OvertimeRecord(
            workerId: '${json['workerId']}',
            hours: (json['hours'] as num).toDouble(),
            description: json['description'] as String,
            recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    accounts = _asList(result[9])
        .map(
          (json) => ManagedAccount(
            id: '${json['id']}',
            username: json['username'] as String,
            role: UserRole.fromApi(json['role']),
            enabled: json['enabled'] as bool,
            phoneNumber: json['phoneNumber'] as String? ?? '',
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    fields = _asList(result[10])
        .map(
          (json) => PlantationField(
            id: '${json['id']}',
            name: json['name'] as String,
            location: json['location'] as String,
            description: json['description'] as String? ?? '',
          ),
        )
        .toList();
    if (RolePermissions.canViewPayrollEstimate(role)) {
      final payrollSettings = result[11];
      if (payrollSettings is! Map<String, dynamic> ||
          payrollSettings['monthlySalary'] is! num ||
          payrollSettings['monthlyRequiredHours'] is! num) {
        throw const FormatException(
          'La configuration de paie renvoyée par le serveur est invalide.',
        );
      }
      final salary = (payrollSettings['monthlySalary'] as num).round();
      final requiredHours = (payrollSettings['monthlyRequiredHours'] as num)
          .round();
      if (salary <= 0 || requiredHours <= 0) {
        throw const FormatException(
          'Le salaire et les heures mensuelles doivent être supérieurs à zéro.',
        );
      }
      monthlySalary = salary;
      monthlyRequiredHours = requiredHours;
    }
    materialAlerts = _asList(result[12])
        .map(
          (json) => MaterialAlert(
            id: '${json['id']}',
            itemId: '${json['itemId']}',
            kind: json['kind'] == 'DELIVERY'
                ? MaterialAlertKind.delivery
                : MaterialAlertKind.missing,
            quantity: (json['quantity'] as num).toDouble(),
            description: json['description'] as String,
            recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
            recordedBy: json['recordedBy'] as String,
            resolved: json['resolved'] as bool? ?? false,
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    payrollDueAmounts = {
      for (final json in _asList(result[13]))
        '${json['workerId']}': (json['amount'] as num).round(),
    };
    if (RolePermissions.canViewDailyReport(role)) {
      dailyReportSnapshot = _dailyReportSnapshot(result[14]);
    }
    payrollRequests = _asList(result[15])
        .map(
          (json) => PayrollPaymentRequest(
            id: '${json['id']}',
            workerId: '${json['workerId']}',
            workerName: json['workerName'] as String,
            amount: (json['amount'] as num).round(),
            throughDate: DateTime.parse(json['throughDate'] as String),
            scheduledPaymentDate: DateTime.parse(
              json['scheduledPaymentDate'] as String,
            ),
            status: switch (json['status']) {
              'APPROVED' => PayrollRequestStatus.approved,
              'REJECTED' => PayrollRequestStatus.rejected,
              'PAID' => PayrollRequestStatus.paid,
              _ => PayrollRequestStatus.pending,
            },
            requestedAt: DateTime.parse(
              json['requestedAt'] as String,
            ).toLocal(),
            requestedBy: json['requestedBy'] as String,
            decidedAt: json['decidedAt'] == null
                ? null
                : DateTime.parse(json['decidedAt'] as String).toLocal(),
            decidedBy: json['decidedBy'] as String?,
            paidAt: json['paidAt'] == null
                ? null
                : DateTime.parse(json['paidAt'] as String),
            paidBy: json['paidBy'] as String?,
          ),
        )
        .toList();
    stockOrders = _asList(result[16])
        .map(
          (json) => StockOrder(
            id: '${json['id']}',
            itemId: '${json['itemId']}',
            itemName: json['itemName'] as String,
            unit: json['unit'] as String,
            orderedQuantity: (json['orderedQuantity'] as num).toDouble(),
            receivedQuantity: (json['receivedQuantity'] as num).toDouble(),
            description: json['description'] as String,
            orderedAt: DateTime.parse(json['orderedAt'] as String).toLocal(),
            orderedBy: json['orderedBy'] as String,
            status: switch (json['status']) {
              'SENT' => StockOrderStatus.sent,
              'RECEIVED' => StockOrderStatus.received,
              _ => StockOrderStatus.ordered,
            },
            sentAt: json['sentAt'] == null
                ? null
                : DateTime.parse(json['sentAt'] as String).toLocal(),
            sentBy: json['sentBy'] as String?,
            receivedAt: json['receivedAt'] == null
                ? null
                : DateTime.parse(json['receivedAt'] as String).toLocal(),
            receivedBy: json['receivedBy'] as String?,
            paidAmount: (json['paidAmount'] as num?)?.round(),
            unitPriceAtDispatch: (json['unitPriceAtDispatch'] as num?)?.round(),
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    sales = _asList(result[17]).map(_harvestSale).toList();
    budgetSummary = result[18] == null ? null : _budgetFromJson(result[18]);
    if (budgetSummary != null && accountId != null) {
      final store = await _offlineStoreFactory();
      await store.saveBudgetSnapshot(accountId!, _asObjectMap(result[18]));
      final serverExpenses = _asList(result[6]);
      final serverByKey = {
        for (final json in serverExpenses)
          if (json['idempotencyKey'] is String)
            json['idempotencyKey'] as String: json,
      };
      final localPending = <Expense>[];
      for (final entry in await store.expensesForAccount(accountId!)) {
        if (entry.status == 'synced') continue;
        final serverExpense = serverByKey[entry.id];
        if (serverExpense != null) {
          if (serverExpense['reconciliationStatus'] !=
              'PENDING_RECONCILIATION') {
            await store.markExpenseSynced(entry.id, serverExpense);
          }
          continue;
        }
        localPending.add(_expenseFromOfflineEntry(entry));
      }
      expenses = [...localPending, ...expenses];
    }
    if (role == UserRole.fieldManager && selectedFieldId == null) {
      selectedFieldId = assignedFieldId ?? fields.firstOrNull?.id;
    }
    _appliedOfflineOperationIds.clear();
    await _restoreQueuedOperationsLocally();
    if (workspaceKey != null) {
      await store!.saveWorkspaceSnapshot(workspaceKey, result);
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) {
      throw const FormatException('La réponse du serveur n’est pas une liste.');
    }
    return value.cast<Map<String, dynamic>>();
  }

  Map<String, Object?> _asObjectMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('La réponse financière est invalide.');
    }
    return Map<String, Object?>.from(value);
  }

  Expense _expenseFromJson(Map<String, dynamic> json) => Expense(
    description: json['description'] as String,
    amount: (json['amount'] as num).round(),
    recordedAt: DateTime.parse(
      (json['occurredAt'] ?? json['recordedAt']) as String,
    ).toLocal(),
    recordedBy: json['recordedBy'] as String,
    budgeted: json['budgeted'] as bool? ?? false,
    status: json['reconciliationStatus'] == 'PENDING_RECONCILIATION'
        ? ExpenseStatus.pendingReconciliation
        : ExpenseStatus.confirmed,
    idempotencyKey: json['idempotencyKey'] as String?,
    fieldId: json['fieldId']?.toString(),
    fieldName: json['fieldName'] as String?,
  );

  Expense _expenseFromOfflineEntry(OfflineExpenseEntry entry) {
    final fieldId = entry.payload['fieldId']?.toString();
    final field = fields.where((item) => item.id == fieldId).firstOrNull;
    final result = entry.serverResult;
    final serverStatus = result?['reconciliationStatus'];
    return Expense(
      description: entry.payload['description']! as String,
      amount: (entry.payload['amount']! as num).round(),
      recordedAt: DateTime.parse(
        entry.payload['occurredAt']! as String,
      ).toLocal(),
      recordedBy: entry.accountId,
      budgeted: true,
      status:
          serverStatus == 'PENDING_RECONCILIATION' ||
              entry.status == 'pending_reconciliation'
          ? ExpenseStatus.pendingReconciliation
          : ExpenseStatus.queuedOffline,
      idempotencyKey: entry.id,
      fieldId: fieldId,
      fieldName: field?.name,
    );
  }

  BudgetSummary _budgetFromJson(dynamic value) {
    final json = _asObjectMap(value);
    final fieldJson = json['fields'];
    if (fieldJson is! List) {
      throw const FormatException('Les allocations de budget sont invalides.');
    }
    return BudgetSummary(
      fundingLimit: (json['fundingLimit'] as num).round(),
      confirmedExpenses: (json['confirmedExpenses'] as num).round(),
      pendingExpenses: (json['pendingExpenses'] as num).round(),
      remainingAmount: (json['remainingAmount'] as num).round(),
      unallocatedAmount: (json['unallocatedAmount'] as num).round(),
      fields: fieldJson.map((value) {
        final field = _asObjectMap(value);
        return FieldBudget(
          fieldId: '${field['fieldId']}',
          fieldName: field['fieldName'] as String,
          allocatedAmount: (field['allocatedAmount'] as num).round(),
          remainingAmount: (field['remainingAmount'] as num).round(),
          pendingExpenses: (field['pendingExpenses'] as num).round(),
          blocked: field['blocked'] as bool? ?? false,
        );
      }).toList(),
    );
  }

  Future<void> _synchronizeQueuedExpenses(PlantationApi client) async {
    if (!RolePermissions.canRecordBudgetExpense(role) || accountId == null) {
      return;
    }
    final store = await _offlineStoreFactory();
    for (final entry in await store.queuedExpenses(accountId!)) {
      final result = await client.synchronizeOfflineExpense(
        entry.payload,
        entry.id,
      );
      final response = _asObjectMap(result);
      if (response['reconciliationStatus'] == 'PENDING_RECONCILIATION') {
        await store.markExpenseForReconciliation(entry.id, response);
      } else {
        await store.markExpenseSynced(entry.id, response);
      }
    }
  }

  Future<(bool, String?)> _sendOrQueueFieldOperation({
    required String method,
    required String path,
    Map<String, Object?> body = const {},
    String? entityType,
  }) async {
    final client = api;
    if (client == null) return (false, null);
    if (role == UserRole.fieldManager && !await _networkAvailable()) {
      return _queueFieldOperation(
        client,
        method: method,
        path: path,
        body: body,
        entityType: entityType,
      );
    }
    try {
      await client.request(method, path, body: body.isEmpty ? null : body);
      return (false, null);
    } on ApiException catch (error) {
      if (error.statusCode != null || role != UserRole.fieldManager) {
        rethrow;
      }
      return _queueFieldOperation(
        client,
        method: method,
        path: path,
        body: body,
        entityType: entityType,
      );
    }
  }

  Future<(bool, String?)> _queueFieldOperation(
    PlantationApi client, {
    required String method,
    required String path,
    required Map<String, Object?> body,
    String? entityType,
  }) async {
    final account = accountId ?? client.authenticatedUsername;
    if (account == null) {
      throw const ApiException(
        'La session terrain est introuvable pour sauvegarder hors ligne.',
      );
    }
    final store = await _offlineStoreFactory();
    final entry = await store.enqueueOperation(
      accountId: account,
      method: method,
      path: path,
      body: body,
      entityType: entityType,
    );
    accountId = account;
    pendingOfflineOperations = (await store.queuedOperations(account)).length;
    _scheduleOfflineRetry();
    return (true, entry.id);
  }

  void _scheduleOfflineRetry() {
    if (_offlineSyncTimer != null || api == null || accountId == null) return;
    _offlineSyncTimer = Timer(const Duration(seconds: 5), () async {
      _offlineSyncTimer = null;
      final client = api;
      if (client == null || accountId == null) return;
      try {
        final synced = await _synchronizeQueuedFieldOperations(client);
        if (synced) await refresh();
      } on ApiException catch (error) {
        if (error.statusCode != null) {
          debugPrint('Offline operation sync failed: ${error.message}');
        }
        _scheduleOfflineRetry();
      }
    });
  }

  Future<bool> _synchronizeQueuedFieldOperations(PlantationApi client) async {
    if (role != UserRole.fieldManager || accountId == null) return true;
    if (_syncingFieldOperations) return false;
    _syncingFieldOperations = true;
    try {
      final store = await _offlineStoreFactory();
      final entries = await store.queuedOperations(accountId!);
      if (entries.isEmpty) {
        pendingOfflineOperations = 0;
        return true;
      }
      if (!await _networkAvailable()) {
        pendingOfflineOperations = entries.length;
        _scheduleOfflineRetry();
        return false;
      }
      for (final entry in entries) {
        final (path, body) = await store.resolveOperationReferences(entry);
        try {
          final result = await client.request(
            entry.method,
            path,
            body: body.isEmpty ? null : body,
          );
          await store.markOperationSynced(
            entry,
            result is Map ? Map<String, Object?>.from(result) : null,
          );
        } on ApiException catch (error) {
          if (error.statusCode != null) rethrow;
          pendingOfflineOperations = (await store.queuedOperations(
            accountId!,
          )).length;
          _scheduleOfflineRetry();
          return false;
        }
      }
      pendingOfflineOperations = 0;
      _offlineSyncTimer?.cancel();
      _offlineSyncTimer = null;
      return true;
    } finally {
      _syncingFieldOperations = false;
    }
  }

  Future<void> _restoreQueuedOperationsLocally() async {
    if (role != UserRole.fieldManager || accountId == null) return;
    final store = await _offlineStoreFactory();
    for (final entry in await store.queuedOperations(accountId!)) {
      if (!_appliedOfflineOperationIds.add(entry.id)) continue;
      final body = entry.body;
      final path = entry.path;
      String? fieldId = (body['fieldId'] ?? assignedFieldId)?.toString();
      final fieldName = fields
          .where((field) => field.id == fieldId)
          .firstOrNull
          ?.name;
      if (entry.method == 'POST' && path == '/api/workers') {
        workers = [
          ...workers,
          Worker(
            id: entry.id,
            name: body['name']! as String,
            group: (body['groupName'] as String?)?.trim().isNotEmpty == true
                ? body['groupName']! as String
                : 'Équipe terrain',
            salary: (body['salary'] as num?)?.round() ?? monthlySalary,
            salaryIsIndividual: body['salaryIsIndividual'] as bool? ?? false,
            active: true,
            phoneNumber: body['phoneNumber'] as String? ?? '',
            fieldId: fieldId,
            fieldName: fieldName,
          ),
        ];
      } else if (entry.method == 'PUT' &&
          path.startsWith('/api/workers/') &&
          path.endsWith('/active')) {
        final workerId = path.split('/')[3];
        final enabled = body['active'] as bool? ?? true;
        workers = [
          for (final worker in workers)
            if (worker.id == workerId)
              Worker(
                id: worker.id,
                name: worker.name,
                group: worker.group,
                salary: worker.salary,
                salaryIsIndividual: worker.salaryIsIndividual,
                active: enabled,
                phoneNumber: worker.phoneNumber,
                fieldId: worker.fieldId,
                fieldName: worker.fieldName,
              )
            else
              worker,
        ];
      } else if (entry.method == 'PUT' && path.startsWith('/api/attendance/')) {
        final uri = Uri.parse(path);
        final workerId = uri.pathSegments.last;
        final date = DateTime.parse(uri.queryParameters['date']!);
        final key = _attendanceKey(date, workerId);
        final previous = attendanceRecords[key];
        final worker = workers
            .where((value) => value.id == workerId)
            .firstOrNull;
        final checkIn = body['checkIn'] == null
            ? previous?.checkIn
            : DateTime.parse(body['checkIn']! as String).toLocal();
        final checkOut = body['checkOut'] == null
            ? previous?.checkOut
            : DateTime.parse(body['checkOut']! as String).toLocal();
        attendanceRecords[key] = AttendanceRecord(
          workerId: workerId,
          date: date,
          status: body['status'] == 'ABSENT'
              ? AttendanceStatus.absent
              : AttendanceStatus.present,
          checkIn: body['status'] == 'ABSENT' ? null : checkIn,
          checkOut: body['status'] == 'ABSENT' ? null : checkOut,
          fieldId: worker?.fieldId,
          fieldName: worker?.fieldName,
        );
      } else if (entry.method == 'POST' && path == '/api/tasks') {
        tasks = [
          FieldTask(
            id: entry.id,
            title: body['title']! as String,
            assigneeIds: (body['assigneeIds'] as List? ?? [])
                .map((id) => '$id')
                .toList(),
            status: FieldTaskStatus.aFaire,
            type: body['type'] == 'SEASONAL_WORKERS'
                ? FieldTaskType.seasonalWorkers
                : FieldTaskType.assignedWorkers,
            createdAt: entry.createdAt.toLocal(),
            fieldId: fieldId,
            fieldName: fieldName,
          ),
          ...tasks,
        ];
      } else if (entry.method == 'PUT' &&
          path.startsWith('/api/tasks/') &&
          path.endsWith('/status')) {
        final taskId = path.split('/')[3];
        final status = switch (body['status']) {
          'IN_PROGRESS' => FieldTaskStatus.enCours,
          'DONE' => FieldTaskStatus.termine,
          _ => FieldTaskStatus.aFaire,
        };
        tasks = [
          for (final task in tasks)
            if (task.id == taskId)
              FieldTask(
                id: task.id,
                title: task.title,
                assigneeIds: task.assigneeIds,
                status: status,
                type: task.type,
                createdAt: task.createdAt,
                completedAt: status == FieldTaskStatus.termine
                    ? entry.createdAt.toLocal()
                    : null,
                actualCost: (body['actualCost'] as num?)?.round(),
                seasonalWorkerCount: (body['seasonalWorkerCount'] as num?)
                    ?.toInt(),
                fieldId: task.fieldId,
                fieldName: task.fieldName,
              )
            else
              task,
        ];
      } else if (entry.method == 'POST' &&
          path == '/api/expenses/field-budget') {
        expenses = [
          Expense(
            description: body['description']! as String,
            amount: (body['amount']! as num).round(),
            recordedAt: DateTime.parse(body['occurredAt']! as String).toLocal(),
            recordedBy: role.label,
            budgeted: true,
            status: ExpenseStatus.queuedOffline,
            idempotencyKey: body['idempotencyKey'] as String?,
            fieldId: fieldId,
            fieldName: fieldName,
          ),
          ...expenses,
        ];
      } else if (entry.method == 'POST' && path == '/api/sales') {
        sales = [
          HarvestSale(
            id: entry.id,
            product: body['product']! as String,
            quantity: (body['quantity']! as num).toDouble(),
            totalPrice: (body['totalPrice']! as num).round(),
            recordedAt: entry.createdAt.toLocal(),
            recordedBy: role.label,
            fieldId: fieldId,
            fieldName: fieldName,
          ),
          ...sales,
        ];
      } else if (entry.method == 'POST' && path == '/api/stock/movements') {
        final itemId = '${body['itemId']}';
        final quantity = (body['quantity']! as num).toDouble();
        final item = stockItems
            .where((value) => value.id == itemId)
            .firstOrNull;
        if (item != null && body['kind'] == 'USAGE') {
          stockItems = [
            for (final value in stockItems)
              if (value.id == itemId)
                StockItem(
                  id: value.id,
                  name: value.name,
                  unit: value.unit,
                  quantity: value.quantity - quantity,
                  unitPrice: value.unitPrice,
                  fieldId: value.fieldId,
                  fieldName: value.fieldName,
                )
              else
                value,
          ];
          stockMovements = [
            StockMovement(
              itemId: itemId,
              kind: StockMovementKind.usage,
              quantity: quantity,
              description: body['description']! as String,
              recordedAt: entry.createdAt.toLocal(),
              recordedBy: role.label,
              fieldId: item.fieldId,
              fieldName: item.fieldName,
            ),
            ...stockMovements,
          ];
        }
      } else if (entry.method == 'POST' && path == '/api/stock/orders') {
        final itemId = '${body['itemId']}';
        final item = stockItems
            .where((value) => value.id == itemId)
            .firstOrNull;
        if (item != null) {
          stockOrders = [
            StockOrder(
              id: entry.id,
              itemId: item.id,
              itemName: item.name,
              unit: item.unit,
              orderedQuantity: (body['quantity']! as num).toDouble(),
              receivedQuantity: 0,
              description: body['description']! as String,
              orderedAt: entry.createdAt.toLocal(),
              orderedBy: role.label,
              status: StockOrderStatus.ordered,
              fieldId: item.fieldId,
              fieldName: item.fieldName,
            ),
            ...stockOrders,
          ];
        }
      } else if (entry.method == 'PUT' &&
          path.startsWith('/api/stock/orders/') &&
          path.endsWith('/receive')) {
        final orderId = path.split('/')[4];
        final order = stockOrders
            .where((value) => value.id == orderId)
            .firstOrNull;
        if (order != null && order.status == StockOrderStatus.sent) {
          stockItems = [
            for (final item in stockItems)
              if (item.id == order.itemId)
                StockItem(
                  id: item.id,
                  name: item.name,
                  unit: item.unit,
                  quantity: item.quantity + order.receivedQuantity,
                  unitPrice: item.unitPrice,
                  fieldId: item.fieldId,
                  fieldName: item.fieldName,
                )
              else
                item,
          ];
          stockOrders = [
            for (final value in stockOrders)
              if (value.id == orderId)
                StockOrder(
                  id: value.id,
                  itemId: value.itemId,
                  itemName: value.itemName,
                  unit: value.unit,
                  orderedQuantity: value.orderedQuantity,
                  receivedQuantity: value.receivedQuantity,
                  description: value.description,
                  orderedAt: value.orderedAt,
                  orderedBy: value.orderedBy,
                  status: StockOrderStatus.received,
                  sentAt: value.sentAt,
                  sentBy: value.sentBy,
                  receivedAt: entry.createdAt.toLocal(),
                  receivedBy: role.label,
                  paidAmount: value.paidAmount,
                  unitPriceAtDispatch: value.unitPriceAtDispatch,
                  fieldId: value.fieldId,
                  fieldName: value.fieldName,
                )
              else
                value,
          ];
        }
      } else if (entry.method == 'POST' && path == '/api/stock/alerts') {
        final itemId = '${body['itemId']}';
        final item = stockItems
            .where((value) => value.id == itemId)
            .firstOrNull;
        if (item != null) {
          materialAlerts = [
            MaterialAlert(
              id: entry.id,
              itemId: itemId,
              kind: MaterialAlertKind.missing,
              quantity: (body['quantity']! as num).toDouble(),
              description: body['description']! as String,
              recordedAt: entry.createdAt.toLocal(),
              recordedBy: role.label,
              fieldId: item.fieldId,
              fieldName: item.fieldName,
            ),
            ...materialAlerts,
          ];
        }
      } else if (entry.method == 'POST' && path == '/api/overtime') {
        final workerId = '${body['workerId']}';
        final worker = workers
            .where((value) => value.id == workerId)
            .firstOrNull;
        overtimeRecords = [
          OvertimeRecord(
            workerId: workerId,
            hours: (body['hours']! as num).toDouble(),
            description: body['description']! as String,
            recordedAt: entry.createdAt.toLocal(),
            fieldId: worker?.fieldId,
            fieldName: worker?.fieldName,
          ),
          ...overtimeRecords,
        ];
      }
    }
  }

  DailyReportSnapshot _dailyReportSnapshot(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Le récapitulatif quotidien est invalide.');
    }
    final attendanceList = _asList(value['attendance']);
    final tasksList = _asList(value['tasks']);
    final movementList = _asList(value['movements']);
    final alertList = _asList(value['alerts']);
    final expenseList = _asList(value['expenses']);
    final paymentList = _asList(value['payments']);
    final salesList = value['sales'] == null
        ? <Map<String, dynamic>>[]
        : _asList(value['sales']);
    return DailyReportSnapshot(
      attendance: _attendanceMap(attendanceList).values.toList(),
      tasks: tasksList
          .map(
            (json) => FieldTask(
              id: '${json['id']}',
              title: json['title'] as String,
              assigneeIds: (json['assigneeIds'] as List<dynamic>)
                  .map((id) => '$id')
                  .toList(),
              status: switch (json['status']) {
                'IN_PROGRESS' => FieldTaskStatus.enCours,
                'DONE' => FieldTaskStatus.termine,
                _ => FieldTaskStatus.aFaire,
              },
              type: json['type'] == 'SEASONAL_WORKERS'
                  ? FieldTaskType.seasonalWorkers
                  : FieldTaskType.assignedWorkers,
              createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
              completedAt: json['completedAt'] == null
                  ? null
                  : DateTime.parse(json['completedAt'] as String).toLocal(),
              actualCost: (json['actualCost'] as num?)?.round(),
              seasonalWorkerCount: (json['seasonalWorkerCount'] as num?)
                  ?.toInt(),
              fieldId: json['fieldId']?.toString(),
              fieldName: json['fieldName'] as String?,
            ),
          )
          .toList(),
      movements: movementList
          .map(
            (json) => StockMovement(
              itemId: '${json['itemId']}',
              kind: json['kind'] == 'RECEIPT'
                  ? StockMovementKind.receipt
                  : StockMovementKind.usage,
              quantity: (json['quantity'] as num).toDouble(),
              description: json['description'] as String,
              recordedAt: DateTime.parse(
                json['recordedAt'] as String,
              ).toLocal(),
              recordedBy: json['recordedBy'] as String,
              fieldId: json['fieldId']?.toString(),
              fieldName: json['fieldName'] as String?,
              paidAmount: (json['paidAmount'] as num?)?.round(),
            ),
          )
          .toList(),
      alerts: alertList
          .map(
            (json) => MaterialAlert(
              id: '${json['id']}',
              itemId: '${json['itemId']}',
              kind: json['kind'] == 'DELIVERY'
                  ? MaterialAlertKind.delivery
                  : MaterialAlertKind.missing,
              quantity: (json['quantity'] as num).toDouble(),
              description: json['description'] as String,
              recordedAt: DateTime.parse(
                json['recordedAt'] as String,
              ).toLocal(),
              recordedBy: json['recordedBy'] as String,
              resolved: json['resolved'] as bool? ?? false,
              fieldId: json['fieldId']?.toString(),
              fieldName: json['fieldName'] as String?,
            ),
          )
          .toList(),
      expenses: expenseList.map(_expenseFromJson).toList(),
      payments: paymentList
          .map(
            (json) => Payment(
              workerId: '${json['workerId']}',
              amount: (json['amount'] as num).round(),
              recordedAt: DateTime.parse(
                json['recordedAt'] as String,
              ).toLocal(),
              recordedBy: json['recordedBy'] as String,
              fieldId: json['fieldId']?.toString(),
              fieldName: json['fieldName'] as String?,
              paidThroughEnd: json['paidThroughEnd'] == null
                  ? null
                  : DateTime.parse(json['paidThroughEnd'] as String).toLocal(),
            ),
          )
          .toList(),
      sales: salesList.map(_harvestSale).toList(),
      validated: value['validated'] as bool? ?? false,
      validatedAt: value['validatedAt'] == null
          ? null
          : DateTime.parse(value['validatedAt'] as String).toLocal(),
      validatedBy: value['validatedBy'] as String?,
    );
  }

  HarvestSale _harvestSale(Map<String, dynamic> json) => HarvestSale(
    id: '${json['id']}',
    product: json['product'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).round(),
    recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
    recordedBy: json['recordedBy'] as String,
    fieldId: json['fieldId']?.toString(),
    fieldName: json['fieldName'] as String?,
  );

  Map<String, AttendanceRecord> _attendanceMap(dynamic value) => {
    for (final json in _asList(value))
      _attendanceKey(
        DateTime.parse(json['date'] as String),
        '${json['workerId']}',
      ): AttendanceRecord(
        workerId: '${json['workerId']}',
        date: DateTime.parse(json['date'] as String),
        status: json['status'] == 'PRESENT'
            ? AttendanceStatus.present
            : AttendanceStatus.absent,
        checkIn: json['checkIn'] == null
            ? null
            : DateTime.parse(json['checkIn'] as String).toLocal(),
        checkOut: json['checkOut'] == null
            ? null
            : DateTime.parse(json['checkOut'] as String).toLocal(),
        fieldId: json['fieldId']?.toString(),
        fieldName: json['fieldName'] as String?,
      ),
  };

  List<Worker> get workersForSelectedField =>
      workers.where((worker) => _fieldMatches(worker.fieldId)).toList();

  List<Worker> get activeWorkers =>
      workersForSelectedField.where((worker) => worker.active).toList();

  List<StockItem> get stockItemsForSelectedField =>
      stockItems.where((item) => _fieldMatches(item.fieldId)).toList();

  List<StockMovement> get stockMovementsForSelectedField {
    final visibleItemIds = stockItemsForSelectedField
        .map((item) => item.id)
        .toSet();
    return stockMovements
        .where((movement) => visibleItemIds.contains(movement.itemId))
        .toList();
  }

  List<MaterialAlert> get materialAlertsForSelectedField =>
      materialAlerts.where((alert) => _fieldMatches(alert.fieldId)).toList();

  List<FieldTask> get tasksForSelectedField =>
      tasks.where((task) => _fieldMatches(task.fieldId)).toList();

  List<Expense> get expensesForSelectedField =>
      expenses.where((expense) => _fieldMatches(expense.fieldId)).toList();

  List<HarvestSale> get salesForSelectedField =>
      sales.where((sale) => _fieldMatches(sale.fieldId)).toList();

  List<Payment> get paymentsForSelectedField {
    final visibleWorkerIds = workersForSelectedField
        .map((worker) => worker.id)
        .toSet();
    return payments
        .where((payment) => visibleWorkerIds.contains(payment.workerId))
        .toList();
  }

  List<Payment> get monthlyPaymentsForSelectedField => monthlyPaymentReport
      .where((payment) => _fieldMatches(payment.fieldId))
      .toList();

  List<OvertimeRecord> get monthlyOvertimeForSelectedField =>
      monthlyOvertimeReport
          .where((record) => _fieldMatches(record.fieldId))
          .toList();

  List<OvertimeRecord> get overtimeForSelectedField {
    final visibleWorkerIds = workersForSelectedField
        .map((worker) => worker.id)
        .toSet();
    return overtimeRecords
        .where((record) => visibleWorkerIds.contains(record.workerId))
        .toList();
  }

  bool _fieldMatches(String? fieldId) => role == UserRole.fieldManager
      ? selectedFieldId == null
            ? fieldId == null
            : fieldId == selectedFieldId
      : selectedFieldId == null ||
            fieldId == null ||
            fieldId == selectedFieldId;

  int get presentCount => attendanceRecords.values
      .where((record) => _isSelectedDate(record.date))
      .where((record) => record.status == AttendanceStatus.present)
      .where(
        (record) => workersForSelectedField.any(
          (worker) => worker.id == record.workerId,
        ),
      )
      .length;

  int get dailyPayroll =>
      activeWorkers.fold<int>(0, (total, worker) => total + worker.salary);

  int get estimatedPayrollTotal => activeWorkers.fold<int>(
    0,
    (total, worker) => total + estimatedPayrollFor(worker),
  );

  int presentDaysFor(String workerId) => payrollAttendanceRecords.values
      .where((record) => record.workerId == workerId)
      .where((record) => _isSameDateMonth(record.date, payrollMonth))
      .where((record) => record.status == AttendanceStatus.present)
      .length;

  int workedMinutesFor(String workerId) => payrollAttendanceRecords.values
      .where((record) => record.workerId == workerId)
      .where((record) => _isSameDateMonth(record.date, payrollMonth))
      .where((record) => record.status == AttendanceStatus.present)
      .where((record) => record.checkIn != null && record.checkOut != null)
      .fold<int>(
        0,
        (total, record) =>
            total + record.checkOut!.difference(record.checkIn!).inMinutes,
      );

  int estimatedPayrollFor(Worker worker) {
    final fullMonthMinutes = monthlyRequiredHours * 60;
    if (fullMonthMinutes <= 0) return 0;
    return (worker.salary * workedMinutesFor(worker.id) / fullMonthMinutes)
        .round();
  }

  double hourlyRateFor(Worker worker) =>
      monthlyRequiredHours <= 0 ? 0 : worker.salary / monthlyRequiredHours;

  int payrollDueFor(Worker worker) =>
      payrollDueAmounts[worker.id] ?? estimatedPayrollFor(worker);

  Future<bool> recordPayrollPayment(String workerId) async {
    final worker = workersForSelectedField
        .where((value) => value.id == workerId)
        .firstOrNull;
    if (role != UserRole.assistant ||
        worker == null ||
        payrollDueFor(worker) <= 0) {
      return false;
    }
    final amount = payrollDueFor(worker);
    if (api != null) {
      await api!.request(
        'POST',
        '/api/payroll/workers/$workerId/payments?through=${_monthParam(payrollMonth)}',
      );
      await refresh();
      return true;
    }
    payments = [
      Payment(
        workerId: worker.id,
        amount: amount,
        recordedAt: DateTime.now(),
        recordedBy: role.label,
        fieldId: worker.fieldId,
        fieldName: worker.fieldName,
        paidThroughEnd: DateTime(payrollMonth.year, payrollMonth.month + 1, 0),
      ),
      ...payments,
    ];
    payrollDueAmounts[workerId] = 0;
    notifyListeners();
    return true;
  }

  PayrollPaymentRequest? payrollRequestFor(String workerId) => payrollRequests
      .where((request) => request.workerId == workerId)
      .where(
        (request) =>
            request.status == PayrollRequestStatus.pending ||
            request.status == PayrollRequestStatus.approved,
      )
      .firstOrNull;

  int get expenseTotal => expensesForSelectedField.fold<int>(
    0,
    (total, expense) => total + expense.amount,
  );

  int get dailyExpenseTotal {
    final today = DateTime.now();
    return expensesForSelectedField
        .where((expense) => _isSameDate(expense.recordedAt, today))
        .fold<int>(0, (total, expense) => total + expense.amount);
  }

  int get stockQuantity => stockItemsForSelectedField.fold<int>(
    0,
    (total, item) => total + item.quantity.round(),
  );

  AttendanceRecord? attendanceFor(String workerId) {
    return attendanceRecords[_attendanceKey(selectedDate, workerId)];
  }

  bool get canEditSelectedDate {
    final today = DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return !selectedDay.isBefore(todayDate);
  }

  bool _isSelectedDate(DateTime date) =>
      date.year == selectedDate.year &&
      date.month == selectedDate.month &&
      date.day == selectedDate.day;

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _isSameDateMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  String _monthParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  void setRole(UserRole value) {
    role = value;
    if (!RolePermissions.canViewPayments(value)) {
      monthlyPaymentReport = [];
      monthlyReportSnapshot = const DailyReportSnapshot();
      monthlyOvertimeReport = [];
      monthlyReportValidatedDates = [];
    }
    if (value == UserRole.fieldManager) {
      selectedFieldId = assignedFieldId ?? fields.firstOrNull?.id;
    } else {
      selectedFieldId = null;
    }
    notifyListeners();
  }

  void setAssignedFieldId(String? value) {
    assignedFieldId = value;
    if (role == UserRole.fieldManager) selectedFieldId = value;
  }

  Future<void> selectField(String? fieldId) async {
    if (role == UserRole.fieldManager) return;
    if (fieldId != null && fields.every((field) => field.id != fieldId)) {
      throw const ApiException(
        'Ce champ n’existe pas ou n’est plus accessible.',
      );
    }
    final previous = selectedFieldId;
    selectedFieldId = fieldId;
    notifyListeners();
    try {
      await refresh();
    } on Exception {
      selectedFieldId = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createField({
    required String name,
    required String location,
    required String description,
  }) async {
    if (!RolePermissions.canManageFields(role)) return;
    if (api == null) {
      fields = [
        ...fields,
        PlantationField(
          id: 'field-${DateTime.now().microsecondsSinceEpoch}',
          name: name.trim(),
          location: location.trim(),
          description: description.trim(),
        ),
      ];
      notifyListeners();
      return;
    }
    await api!.request(
      'POST',
      '/api/fields',
      body: {
        'name': name.trim(),
        'location': location.trim(),
        'description': description.trim(),
      },
    );
    await refresh();
  }

  String _withField(String path) {
    final fieldId = selectedFieldId;
    if (fieldId == null) return path;
    final separator = path.contains('?') ? '&' : '?';
    return '$path$separator'
        'fieldId=${Uri.encodeQueryComponent(fieldId)}';
  }

  Future<void> selectDate(DateTime value) async {
    final previousDate = selectedDate;
    selectedDate = value;
    notifyListeners();
    try {
      await refresh();
    } on Exception {
      selectedDate = previousDate;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> validateDailyReport() async {
    if (role != UserRole.assistant || api == null) return false;
    await api!.request(
      'PUT',
      '/api/reports/daily/validate?date=${_dateParam(selectedDate)}',
    );
    await refresh();
    return dailyReportSnapshot.validated;
  }

  Future<void> selectPayrollMonth(DateTime value) async {
    if (!RolePermissions.canViewPayrollEstimate(role)) return;
    final month = DateTime(value.year, value.month);
    final previousMonth = payrollMonth;
    final previousRecords = payrollAttendanceRecords;
    payrollMonth = month;
    if (api == null) {
      payrollAttendanceRecords = {
        for (final entry in attendanceRecords.entries)
          if (_isSameDateMonth(entry.value.date, month)) entry.key: entry.value,
      };
      payrollDueAmounts = {
        for (final worker in workersForSelectedField)
          worker.id: estimatedPayrollFor(worker),
      };
      notifyListeners();
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        api!.request(
          'GET',
          _withField('/api/attendance/month?month=${_monthParam(month)}'),
        ),
        if (RolePermissions.canViewPayments(role))
          api!.request('GET', '/api/payroll/due?through=${_monthParam(month)}')
        else
          Future.value(<dynamic>[]),
      ]);
      payrollAttendanceRecords = _attendanceMap(results[0]);
      payrollDueAmounts = {
        for (final json in _asList(results[1]))
          '${json['workerId']}': (json['amount'] as num).round(),
      };
      notifyListeners();
    } on Exception {
      payrollMonth = previousMonth;
      payrollAttendanceRecords = previousRecords;
      rethrow;
    }
  }

  Future<void> loadMonthlyReport(DateTime value) async {
    if (!RolePermissions.canViewPayments(role)) return;
    final month = DateTime(value.year, value.month);
    if (api == null) {
      paymentReportMonth = month;
      monthlyReportSnapshot = DailyReportSnapshot(
        attendance: attendanceRecords.values
            .where((record) => _isSameDateMonth(record.date, month))
            .toList(),
        tasks: tasks
            .where((task) => _isSameDateMonth(task.createdAt, month))
            .toList(),
        movements: stockMovements
            .where((record) => _isSameDateMonth(record.recordedAt, month))
            .toList(),
        alerts: materialAlerts
            .where((record) => _isSameDateMonth(record.recordedAt, month))
            .toList(),
        expenses: expenses
            .where((record) => _isSameDateMonth(record.recordedAt, month))
            .toList(),
        payments: payments
            .where((record) => _isSameDateMonth(record.recordedAt, month))
            .toList(),
        sales: sales
            .where((record) => _isSameDateMonth(record.recordedAt, month))
            .toList(),
      );
      monthlyOvertimeReport = overtimeRecords
          .where((record) => _isSameDateMonth(record.recordedAt, month))
          .toList();
      monthlyPaymentReport = monthlyReportSnapshot.payments;
      notifyListeners();
      return;
    }
    final response = await api!.request(
      'GET',
      '/api/reports/monthly?month=${_monthParam(month)}',
    );
    paymentReportMonth = month;
    monthlyReportSnapshot = _dailyReportSnapshot(response);
    monthlyPaymentReport = monthlyReportSnapshot.payments;
    final report = response as Map<String, dynamic>;
    monthlyOvertimeReport = _asList(report['overtime'])
        .map(
          (json) => OvertimeRecord(
            workerId: '${json['workerId']}',
            hours: (json['hours'] as num).toDouble(),
            description: json['description'] as String,
            recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
            fieldId: json['fieldId']?.toString(),
            fieldName: json['fieldName'] as String?,
          ),
        )
        .toList();
    final validatedDates = report['validatedDates'];
    if (validatedDates is! List) {
      throw const FormatException(
        'Les dates de validation mensuelle sont invalides.',
      );
    }
    monthlyReportValidatedDates = validatedDates
        .map((date) => DateTime.parse(date as String))
        .toList();
    notifyListeners();
  }

  Future<void> markAttendance(String workerId, AttendanceStatus status) async {
    if (!RolePermissions.canMarkAttendance(role)) return;
    if (!canEditSelectedDate) {
      throw const ApiException(
        'Les pointages des dates passées sont en lecture seule.',
      );
    }
    final checkIn = status == AttendanceStatus.present ? DateTime.now() : null;
    if (api != null) {
      final path = _withField(
        '/api/attendance/$workerId?date=${_dateParam(selectedDate)}',
      );
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'PUT',
        path: path,
        body: {
          'status': status == AttendanceStatus.present ? 'PRESENT' : 'ABSENT',
          if (checkIn != null) 'checkIn': checkIn.toUtc().toIso8601String(),
        },
      );
      if (!queued) {
        await refresh();
        if (status == AttendanceStatus.present &&
            attendanceFor(workerId)?.checkIn == null) {
          throw const ApiException(
            'Le serveur n’a pas confirmé l’heure d’arrivée enregistrée.',
          );
        }
        return;
      }
      _appliedOfflineOperationIds.add(operationId!);
    }
    attendanceRecords[_attendanceKey(
      selectedDate,
      workerId,
    )] = AttendanceRecord(
      workerId: workerId,
      date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
      status: status,
      checkIn: checkIn,
      fieldId: workers
          .where((worker) => worker.id == workerId)
          .firstOrNull
          ?.fieldId,
      fieldName: workers
          .where((worker) => worker.id == workerId)
          .firstOrNull
          ?.fieldName,
    );
    notifyListeners();
  }

  Future<bool> checkOutWorker(String workerId) async {
    if (!RolePermissions.canMarkAttendance(role)) return false;
    if (!canEditSelectedDate) return false;
    if (workersForSelectedField.every((worker) => worker.id != workerId)) {
      return false;
    }
    final key = _attendanceKey(selectedDate, workerId);
    final record = attendanceRecords[key];
    if (record?.status != AttendanceStatus.present ||
        record?.checkIn == null ||
        record?.checkOut != null) {
      return false;
    }
    final checkOut = DateTime.now();
    if (api != null) {
      final path = _withField(
        '/api/attendance/$workerId?date=${_dateParam(selectedDate)}',
      );
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'PUT',
        path: path,
        body: {
          'status': 'PRESENT',
          'checkOut': checkOut.toUtc().toIso8601String(),
        },
      );
      if (!queued) {
        await refresh();
        if (attendanceFor(workerId)?.checkOut == null) {
          throw const ApiException(
            'Le serveur n’a pas confirmé l’heure de départ enregistrée.',
          );
        }
        return true;
      }
      _appliedOfflineOperationIds.add(operationId!);
    }
    attendanceRecords[key] = AttendanceRecord(
      workerId: record!.workerId,
      date: record.date,
      status: record.status,
      checkIn: record.checkIn,
      checkOut: checkOut,
      fieldId: record.fieldId,
      fieldName: record.fieldName,
    );
    notifyListeners();
    return true;
  }

  Future<bool> savePayrollSettings({
    required int salary,
    required int requiredHours,
  }) async {
    if (role != UserRole.director || salary <= 0 || requiredHours <= 0) {
      return false;
    }
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/payroll/settings',
        body: {'monthlySalary': salary, 'monthlyRequiredHours': requiredHours},
      );
    }
    workers = [
      for (final worker in workers)
        worker.salaryIsIndividual
            ? worker
            : Worker(
                id: worker.id,
                name: worker.name,
                group: worker.group,
                salary: salary,
                salaryIsIndividual: false,
                active: worker.active,
                phoneNumber: worker.phoneNumber,
                fieldId: worker.fieldId,
                fieldName: worker.fieldName,
              ),
    ];
    monthlySalary = salary;
    monthlyRequiredHours = requiredHours;
    notifyListeners();
    return true;
  }

  Future<void> addWorker({
    required String name,
    required String group,
    required String phoneNumber,
  }) async {
    if (!RolePermissions.canManageWorkers(role)) return;
    if (api != null) {
      final (queued, localId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/workers',
        entityType: 'worker',
        body: {
          'name': name.trim(),
          'groupName': group.trim(),
          'salary': monthlySalary,
          'salaryIsIndividual': false,
          'phoneNumber': phoneNumber.trim(),
          if ((assignedFieldId ?? selectedFieldId) != null)
            'fieldId': int.parse(assignedFieldId ?? selectedFieldId!),
        },
      );
      if (!queued) {
        await refresh();
        return;
      }
      final queuedId = localId!;
      _appliedOfflineOperationIds.add(queuedId);
      workers = [
        ...workers,
        Worker(
          id: queuedId,
          name: name.trim(),
          group: group.trim().isEmpty ? 'Équipe terrain' : group.trim(),
          salary: monthlySalary,
          active: true,
          phoneNumber: phoneNumber.trim(),
          fieldId: selectedFieldId ?? assignedFieldId,
          fieldName: fields
              .where(
                (field) => field.id == (selectedFieldId ?? assignedFieldId),
              )
              .firstOrNull
              ?.name,
        ),
      ];
      notifyListeners();
      return;
    }
    workers = [
      ...workers,
      Worker(
        id: 'w${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        group: group.trim().isEmpty ? 'Équipe terrain' : group.trim(),
        salary: monthlySalary,
        active: true,
        phoneNumber: phoneNumber.trim(),
        fieldId: selectedFieldId ?? assignedFieldId,
        fieldName: fields
            .where((field) => field.id == (selectedFieldId ?? assignedFieldId))
            .firstOrNull
            ?.name,
      ),
    ];
    notifyListeners();
  }

  Future<void> setWorkerActive(String workerId, bool active) async {
    if (!RolePermissions.canManageWorkerRecords(role)) return;
    if (api != null) {
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'PUT',
        path: '/api/workers/$workerId/active',
        body: {'active': active},
      );
      if (!queued) {
        await refresh();
        return;
      }
      _appliedOfflineOperationIds.add(operationId!);
    }
    workers = [
      for (final worker in workers)
        if (worker.id == workerId)
          Worker(
            id: worker.id,
            name: worker.name,
            group: worker.group,
            salary: worker.salary,
            salaryIsIndividual: worker.salaryIsIndividual,
            active: active,
            phoneNumber: worker.phoneNumber,
            fieldId: worker.fieldId,
            fieldName: worker.fieldName,
          )
        else
          worker,
    ];
    notifyListeners();
  }

  Future<void> updateWorkerPhone(String workerId, String phoneNumber) async {
    if (!RolePermissions.canManageWorkerContacts(role)) return;
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/workers/$workerId/contact',
        body: {'phoneNumber': phoneNumber.trim()},
      );
      await refresh();
      return;
    }
    workers = [
      for (final worker in workers)
        if (worker.id == workerId)
          Worker(
            id: worker.id,
            name: worker.name,
            group: worker.group,
            salary: worker.salary,
            salaryIsIndividual: worker.salaryIsIndividual,
            active: worker.active,
            phoneNumber: phoneNumber.trim(),
            fieldId: worker.fieldId,
            fieldName: worker.fieldName,
          )
        else
          worker,
    ];
    notifyListeners();
  }

  Future<void> archiveWorker(String workerId) async {
    if (!RolePermissions.canManageWorkerContacts(role)) return;
    if (api != null) {
      await api!.request('DELETE', '/api/workers/$workerId');
      await refresh();
      return;
    }
    await setWorkerActive(workerId, false);
  }

  Future<void> updateWorkerSalary(String workerId, int salary) async {
    if (!RolePermissions.canManageWorkerSalary(role) || salary <= 0) return;
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/workers/$workerId/salary',
        body: {'salary': salary, 'salaryIsIndividual': true},
      );
    }
    workers = [
      for (final worker in workers)
        if (worker.id == workerId)
          Worker(
            id: worker.id,
            name: worker.name,
            group: worker.group,
            salary: salary,
            salaryIsIndividual: true,
            active: worker.active,
            phoneNumber: worker.phoneNumber,
            fieldId: worker.fieldId,
            fieldName: worker.fieldName,
          )
        else
          worker,
    ];
    notifyListeners();
  }

  Future<void> createManagedAccount({
    required String username,
    required String password,
    required String phoneNumber,
    required UserRole accountRole,
    String? assignedFieldId,
  }) async {
    if (!RolePermissions.canManageAccounts(role)) return;
    if (accountRole == UserRole.director) {
      throw const ApiException(
        'Seuls les comptes assistant et terrain peuvent être créés ici.',
      );
    }
    if (accountRole == UserRole.fieldManager &&
        (assignedFieldId == null ||
            fields.every((field) => field.id != assignedFieldId))) {
      throw const ApiException(
        'Un responsable terrain doit être rattaché à un champ existant.',
      );
    }
    if (api == null) {
      final assignedField = fields
          .where((field) => field.id == assignedFieldId)
          .firstOrNull;
      accounts = [
        ...accounts,
        ManagedAccount(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          username: username.trim(),
          role: accountRole,
          enabled: true,
          phoneNumber: phoneNumber.trim(),
          fieldId: assignedField?.id,
          fieldName: assignedField?.name,
        ),
      ];
      notifyListeners();
      return;
    }
    await api!.request(
      'POST',
      '/api/accounts',
      body: {
        'username': username.trim(),
        'password': password,
        'phoneNumber': phoneNumber.trim(),
        'role': accountRole == UserRole.assistant
            ? 'ASSISTANT'
            : 'FIELD_MANAGER',
        if (accountRole == UserRole.fieldManager)
          'fieldId': int.parse(assignedFieldId!),
      },
    );
    await refresh();
  }

  Future<void> setManagedAccountEnabled(String accountId, bool enabled) async {
    if (!RolePermissions.canManageAccounts(role)) return;
    if (api == null) {
      accounts = [
        for (final account in accounts)
          if (account.id == accountId)
            ManagedAccount(
              id: account.id,
              username: account.username,
              role: account.role,
              enabled: enabled,
              phoneNumber: account.phoneNumber,
              fieldId: account.fieldId,
              fieldName: account.fieldName,
            )
          else
            account,
      ];
      notifyListeners();
      return;
    }
    await api!.request(
      'PUT',
      '/api/accounts/$accountId/enabled',
      body: {'enabled': enabled},
    );
    await refresh();
  }

  Future<void> addTask(
    String title,
    List<String> assigneeIds, {
    FieldTaskType type = FieldTaskType.assignedWorkers,
  }) async {
    if (role != UserRole.fieldManager) return;
    if (type == FieldTaskType.assignedWorkers && assigneeIds.isEmpty) {
      throw const ApiException('Choisissez au moins un ouvrier.');
    }
    if (type == FieldTaskType.seasonalWorkers && assigneeIds.isNotEmpty) {
      throw const ApiException(
        'Les tâches saisonnières ne prennent pas d’ouvriers nominatifs.',
      );
    }
    if (api != null) {
      final (queued, localId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/tasks',
        entityType: 'task',
        body: {
          'title': title.trim(),
          'type': type == FieldTaskType.seasonalWorkers
              ? 'SEASONAL_WORKERS'
              : 'ASSIGNED_WORKERS',
          'assigneeIds': assigneeIds
              .map((id) => int.tryParse(id) ?? id)
              .toList(),
          if ((assignedFieldId ?? selectedFieldId) != null)
            'fieldId': int.parse(assignedFieldId ?? selectedFieldId!),
        },
      );
      if (queued) {
        final queuedId = localId!;
        _appliedOfflineOperationIds.add(queuedId);
        tasks = [
          FieldTask(
            id: queuedId,
            title: title.trim(),
            assigneeIds: List.unmodifiable(assigneeIds),
            status: FieldTaskStatus.aFaire,
            type: type,
            createdAt: DateTime.now(),
            fieldId: selectedFieldId ?? assignedFieldId,
            fieldName: fields
                .where(
                  (field) => field.id == (selectedFieldId ?? assignedFieldId),
                )
                .firstOrNull
                ?.name,
          ),
          ...tasks,
        ];
        notifyListeners();
        return;
      }
      await refresh();
      return;
    }
    tasks = [
      FieldTask(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        assigneeIds: List.unmodifiable(assigneeIds),
        status: FieldTaskStatus.aFaire,
        type: type,
        createdAt: DateTime.now(),
        fieldId: selectedFieldId ?? assignedFieldId,
        fieldName: fields
            .where((field) => field.id == (selectedFieldId ?? assignedFieldId))
            .firstOrNull
            ?.name,
      ),
      ...tasks,
    ];
    notifyListeners();
  }

  Future<void> updateTaskStatus(
    String taskId,
    FieldTaskStatus status, {
    int? actualCost,
    int? seasonalWorkerCount,
  }) async {
    if (!RolePermissions.canManageTasks(role)) return;
    if (status == FieldTaskStatus.termine &&
        (actualCost == null || seasonalWorkerCount == null)) {
      throw const ApiException(
        'Le coût réel et le nombre de saisonniers sont obligatoires.',
      );
    }
    if (api != null) {
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'PUT',
        path: '/api/tasks/$taskId/status',
        body: {
          'status': switch (status) {
            FieldTaskStatus.enCours => 'IN_PROGRESS',
            FieldTaskStatus.aFaire => 'TO_DO',
            FieldTaskStatus.termine => 'DONE',
          },
          if (status == FieldTaskStatus.termine) ...{
            'actualCost': actualCost,
            'seasonalWorkerCount': seasonalWorkerCount,
          },
        },
      );
      if (!queued) {
        await refresh();
        return;
      }
      _appliedOfflineOperationIds.add(operationId!);
    }
    tasks = [
      for (final task in tasks)
        if (task.id == taskId)
          FieldTask(
            id: task.id,
            title: task.title,
            assigneeIds: task.assigneeIds,
            status: status,
            type: task.type,
            createdAt: task.createdAt,
            completedAt: status == FieldTaskStatus.termine
                ? DateTime.now()
                : null,
            actualCost: status == FieldTaskStatus.termine ? actualCost : null,
            seasonalWorkerCount: status == FieldTaskStatus.termine
                ? seasonalWorkerCount
                : null,
            fieldId: task.fieldId,
            fieldName: task.fieldName,
          )
        else
          task,
    ];
    notifyListeners();
  }

  Future<void> addStockItem(String name, String unit, {String? fieldId}) async {
    if (role != UserRole.assistant && role != UserRole.fieldManager) return;
    final targetFieldId = fieldId ?? selectedFieldId;
    if (targetFieldId == null && api != null) {
      throw const ApiException('Sélectionnez le champ à approvisionner.');
    }
    if (api != null) {
      await api!.request(
        'POST',
        '/api/stock/items',
        body: {
          'name': name.trim(),
          'unit': unit.trim(),
          'fieldId': int.parse(targetFieldId!),
        },
      );
      await refresh();
      return;
    }
    stockItems = [
      ...stockItems,
      StockItem(
        id: 's${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        unit: unit.trim(),
        quantity: 0,
        fieldId: targetFieldId,
        fieldName: fields
            .where((field) => field.id == targetFieldId)
            .firstOrNull
            ?.name,
      ),
    ];
    notifyListeners();
  }

  Future<void> updateStockItemPrice(String itemId, int unitPrice) async {
    if (role != UserRole.assistant || unitPrice <= 0) return;
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/stock/items/$itemId/price',
        body: {'unitPrice': unitPrice},
      );
      await refresh();
      return;
    }
    stockItems = [
      for (final item in stockItems)
        if (item.id == itemId)
          StockItem(
            id: item.id,
            name: item.name,
            unit: item.unit,
            quantity: item.quantity,
            unitPrice: unitPrice,
            fieldId: item.fieldId,
            fieldName: item.fieldName,
          )
        else
          item,
    ];
    notifyListeners();
  }

  String _attendanceKey(DateTime date, String workerId) =>
      '${date.year}-${date.month}-${date.day}:$workerId';

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> addExpense(
    String description,
    int amount, {
    String? fieldId,
  }) async {
    if (role == UserRole.director) return;
    final targetFieldId = fieldId ?? selectedFieldId;
    if (targetFieldId == null && api != null) {
      throw const ApiException(
        'Sélectionnez le champ concerné par la dépense.',
      );
    }
    if (api != null) {
      final occurredAt = DateTime.now().toUtc();
      if (role == UserRole.fieldManager &&
          RolePermissions.canRecordBudgetExpense(role)) {
        final expenseKey =
            'fm-${occurredAt.microsecondsSinceEpoch}-${_fieldExpenseSequence++}';
        final (queued, operationId) = await _sendOrQueueFieldOperation(
          method: 'POST',
          path: '/api/expenses/field-budget',
          body: {
            'description': description.trim(),
            'amount': amount,
            'occurredAt': occurredAt.toIso8601String(),
            'idempotencyKey': expenseKey,
          },
        );
        if (queued) {
          _appliedOfflineOperationIds.add(operationId!);
          expenses = [
            Expense(
              description: description.trim(),
              amount: amount,
              recordedAt: occurredAt.toLocal(),
              recordedBy: role.label,
              budgeted: true,
              status: ExpenseStatus.queuedOffline,
              idempotencyKey: expenseKey,
              fieldId: targetFieldId,
              fieldName: fields
                  .where((field) => field.id == targetFieldId)
                  .firstOrNull
                  ?.name,
            ),
            ...expenses,
          ];
          notifyListeners();
          return;
        }
        await refresh();
        return;
      }
      if (RolePermissions.canRecordBudgetExpense(role)) {
        final account = accountId ?? api!.authenticatedUsername;
        if (account == null) {
          throw const ApiException('La session assistant est introuvable.');
        }
        final store = await _offlineStoreFactory();
        final entry = await store.enqueueExpense(
          accountId: account,
          payload: {
            'description': description.trim(),
            'amount': amount,
            'fieldId': int.parse(targetFieldId!),
            'occurredAt': occurredAt.toIso8601String(),
          },
        );
        accountId = account;
        dynamic response;
        try {
          response = await api!.recordAssistantExpense(entry.payload, entry.id);
        } on ApiException catch (error) {
          if (error.statusCode == null) {
            _insertLocalAssistantExpense(
              description,
              amount,
              occurredAt,
              targetFieldId,
              entry.id,
              ExpenseStatus.queuedOffline,
            );
            return;
          }
          if (error.statusCode! >= 400 && error.statusCode! < 500) {
            await store.discardExpense(entry.id);
          }
          rethrow;
        }
        final expenseResponse = _asObjectMap(response);
        if (expenseResponse['reconciliationStatus'] ==
            'PENDING_RECONCILIATION') {
          await store.markExpenseForReconciliation(entry.id, expenseResponse);
        } else {
          await store.markExpenseSynced(entry.id, expenseResponse);
        }
        await refresh();
        return;
      }
      await api!.request(
        'POST',
        '/api/expenses',
        body: {
          'description': description.trim(),
          'amount': amount,
          'fieldId': int.parse(targetFieldId!),
        },
      );
      await refresh();
      return;
    }
    expenses = [
      Expense(
        description: description.trim(),
        amount: amount,
        recordedAt: DateTime.now(),
        recordedBy: role.label,
        fieldId: targetFieldId,
        fieldName: fields
            .where((field) => field.id == targetFieldId)
            .firstOrNull
            ?.name,
      ),
      ...expenses,
    ];
    notifyListeners();
  }

  void _insertLocalAssistantExpense(
    String description,
    int amount,
    DateTime occurredAt,
    String fieldId,
    String idempotencyKey,
    ExpenseStatus status,
  ) {
    expenses = [
      Expense(
        description: description.trim(),
        amount: amount,
        recordedAt: occurredAt.toLocal(),
        recordedBy: accountId ?? UserRole.assistant.label,
        budgeted: true,
        status: status,
        idempotencyKey: idempotencyKey,
        fieldId: fieldId,
        fieldName: fields
            .where((field) => field.id == fieldId)
            .firstOrNull
            ?.name,
      ),
      ...expenses,
    ];
    notifyListeners();
  }

  Future<void> setBudgetLimit(int amount) async {
    if (!RolePermissions.canSetBudgetLimit(role) || amount < 0 || api == null) {
      return;
    }
    final response = await api!.setBudgetLimit(amount);
    budgetSummary = _budgetFromJson(response);
    notifyListeners();
  }

  Future<void> addBudgetFunding({required int amount, String? note}) async {
    if (!RolePermissions.canSetBudgetLimit(role) ||
        amount <= 0 ||
        api == null) {
      return;
    }
    final response = await api!.addBudgetFunding(amount: amount, note: note);
    budgetSummary = _budgetFromJson(response);
    notifyListeners();
  }

  Future<void> allocateFieldBudget({
    required String fieldId,
    required int amount,
    String? note,
  }) async {
    if (!RolePermissions.canAllocateBudget(role) ||
        amount <= 0 ||
        api == null) {
      return;
    }
    final response = await api!.allocateFieldBudget(
      fieldId: int.parse(fieldId),
      amount: amount,
      note: note,
    );
    budgetSummary = _budgetFromJson(response);
    notifyListeners();
  }

  Future<bool> addHarvestSale({
    required String product,
    required double quantity,
    required int totalPrice,
  }) async {
    if (!RolePermissions.canRecordHarvestSale(role) ||
        product.trim().isEmpty ||
        !quantity.isFinite ||
        quantity <= 0 ||
        totalPrice <= 0) {
      return false;
    }
    final targetFieldId = selectedFieldId ?? assignedFieldId;
    if (targetFieldId == null && api != null) {
      throw const ApiException('Sélectionnez le champ concerné par la vente.');
    }
    if (api != null) {
      final (queued, localId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/sales',
        entityType: 'sale',
        body: {
          'product': product.trim(),
          'quantity': quantity,
          'totalPrice': totalPrice,
          'fieldId': int.parse(targetFieldId!),
        },
      );
      if (queued) {
        _appliedOfflineOperationIds.add(localId!);
        sales = [
          HarvestSale(
            id: localId,
            product: product.trim(),
            quantity: quantity,
            totalPrice: totalPrice,
            recordedAt: DateTime.now(),
            recordedBy: role.label,
            fieldId: targetFieldId,
            fieldName: fields
                .where((field) => field.id == targetFieldId)
                .firstOrNull
                ?.name,
          ),
          ...sales,
        ];
        notifyListeners();
        return true;
      }
      await refresh();
      return true;
    }
    sales = [
      HarvestSale(
        id: 'sale-${DateTime.now().microsecondsSinceEpoch}',
        product: product.trim(),
        quantity: quantity,
        totalPrice: totalPrice,
        recordedAt: DateTime.now(),
        recordedBy: role.label,
        fieldId: targetFieldId,
        fieldName: fields
            .where((field) => field.id == targetFieldId)
            .firstOrNull
            ?.name,
      ),
      ...sales,
    ];
    notifyListeners();
    return true;
  }

  Future<bool> addStockMovement({
    required String itemId,
    required StockMovementKind kind,
    required double quantity,
    required String description,
    int? paidAmount,
  }) async {
    if (quantity <= 0) return false;
    final index = stockItems.indexWhere(
      (item) => item.id == itemId && _fieldMatches(item.fieldId),
    );
    if (index < 0) return false;
    if (kind == StockMovementKind.receipt) {
      return false;
    }
    if (kind == StockMovementKind.usage && role != UserRole.fieldManager) {
      return false;
    }
    final item = stockItems[index];
    if (kind == StockMovementKind.usage && quantity > item.quantity) {
      return false;
    }
    if (api != null) {
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/stock/movements',
        body: {
          'itemId': int.parse(itemId),
          'kind': kind == StockMovementKind.receipt ? 'RECEIPT' : 'USAGE',
          'quantity': quantity,
          'description': description.trim(),
          ...?paidAmount == null ? null : {'paidAmount': paidAmount},
        },
      );
      if (!queued) {
        await refresh();
        return true;
      }
      _appliedOfflineOperationIds.add(operationId!);
    }
    stockItems = [
      for (var i = 0; i < stockItems.length; i++)
        if (i == index)
          StockItem(
            id: item.id,
            name: item.name,
            unit: item.unit,
            quantity:
                item.quantity +
                (kind == StockMovementKind.receipt ? quantity : -quantity),
            unitPrice: item.unitPrice,
            fieldId: item.fieldId,
            fieldName: item.fieldName,
          )
        else
          stockItems[i],
    ];
    stockMovements = [
      StockMovement(
        itemId: itemId,
        kind: kind,
        quantity: quantity,
        description: description.trim(),
        recordedAt: DateTime.now(),
        recordedBy: role.label,
        fieldId: item.fieldId,
        fieldName: item.fieldName,
        paidAmount: paidAmount,
      ),
      ...stockMovements,
    ];
    notifyListeners();
    return true;
  }

  List<StockOrder> get stockOrdersForSelectedField =>
      stockOrders.where((order) => _fieldMatches(order.fieldId)).toList();

  Future<bool> createStockOrder({
    required String itemId,
    required double quantity,
    required String description,
  }) async {
    if (role != UserRole.fieldManager ||
        quantity <= 0 ||
        description.trim().isEmpty ||
        stockItemsForSelectedField.every((item) => item.id != itemId)) {
      return false;
    }
    if (api != null) {
      final (queued, localId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/stock/orders',
        entityType: 'stock_order',
        body: {
          'itemId': int.parse(itemId),
          'quantity': quantity,
          'description': description.trim(),
        },
      );
      if (queued) {
        _appliedOfflineOperationIds.add(localId!);
        final item = stockItemsForSelectedField.firstWhere(
          (stockItem) => stockItem.id == itemId,
        );
        stockOrders = [
          StockOrder(
            id: localId,
            itemId: item.id,
            itemName: item.name,
            unit: item.unit,
            orderedQuantity: quantity,
            receivedQuantity: 0,
            description: description.trim(),
            orderedAt: DateTime.now(),
            orderedBy: role.label,
            status: StockOrderStatus.ordered,
            fieldId: item.fieldId,
            fieldName: item.fieldName,
          ),
          ...stockOrders,
        ];
        notifyListeners();
        return true;
      }
      await refresh();
      return true;
    }
    final item = stockItemsForSelectedField.firstWhere(
      (stockItem) => stockItem.id == itemId,
    );
    stockOrders = [
      StockOrder(
        id: 'order-${DateTime.now().microsecondsSinceEpoch}',
        itemId: item.id,
        itemName: item.name,
        unit: item.unit,
        orderedQuantity: quantity,
        receivedQuantity: 0,
        description: description.trim(),
        orderedAt: DateTime.now(),
        orderedBy: role.label,
        status: StockOrderStatus.ordered,
        fieldId: item.fieldId,
        fieldName: item.fieldName,
      ),
      ...stockOrders,
    ];
    notifyListeners();
    return true;
  }

  Future<bool> dispatchStockOrder({
    required String orderId,
    required double sentQuantity,
  }) async {
    if (role != UserRole.assistant || sentQuantity <= 0) {
      return false;
    }
    final index = stockOrders.indexWhere(
      (order) =>
          order.id == orderId && order.status == StockOrderStatus.ordered,
    );
    if (index < 0) return false;
    final order = stockOrders[index];
    if (sentQuantity > order.orderedQuantity) return false;
    final item = stockItems
        .where((candidate) => candidate.id == order.itemId)
        .firstOrNull;
    if (item == null || (item.unitPrice ?? 0) <= 0) return false;
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/stock/orders/$orderId/send',
        body: {'sentQuantity': sentQuantity},
      );
      await refresh();
      return true;
    }
    final paidAmount = (sentQuantity * item.unitPrice!).round();
    stockOrders = [
      for (var i = 0; i < stockOrders.length; i++)
        if (i == index)
          StockOrder(
            id: order.id,
            itemId: order.itemId,
            itemName: order.itemName,
            unit: order.unit,
            orderedQuantity: order.orderedQuantity,
            receivedQuantity: sentQuantity,
            description: order.description,
            orderedAt: order.orderedAt,
            orderedBy: order.orderedBy,
            status: StockOrderStatus.sent,
            sentAt: DateTime.now(),
            sentBy: role.label,
            paidAmount: paidAmount,
            unitPriceAtDispatch: item.unitPrice,
            fieldId: order.fieldId,
            fieldName: order.fieldName,
          )
        else
          stockOrders[i],
    ];
    notifyListeners();
    return true;
  }

  Future<bool> confirmStockOrderReceived(String orderId) async {
    if (role != UserRole.fieldManager) return false;
    final index = stockOrders.indexWhere(
      (order) => order.id == orderId && order.status == StockOrderStatus.sent,
    );
    if (index < 0) return false;
    final order = stockOrders[index];
    if (api != null) {
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'PUT',
        path: '/api/stock/orders/$orderId/receive',
      );
      if (!queued) {
        await refresh();
        return true;
      }
      _appliedOfflineOperationIds.add(operationId!);
    }
    final itemIndex = stockItems.indexWhere(
      (item) => item.id == order.itemId && _fieldMatches(item.fieldId),
    );
    if (itemIndex < 0) return false;
    final item = stockItems[itemIndex];
    stockItems = [
      for (var i = 0; i < stockItems.length; i++)
        if (i == itemIndex)
          StockItem(
            id: item.id,
            name: item.name,
            unit: item.unit,
            quantity: item.quantity + order.receivedQuantity,
            unitPrice: item.unitPrice,
            fieldId: item.fieldId,
            fieldName: item.fieldName,
          )
        else
          stockItems[i],
    ];
    stockOrders = [
      for (var i = 0; i < stockOrders.length; i++)
        if (i == index)
          StockOrder(
            id: order.id,
            itemId: order.itemId,
            itemName: order.itemName,
            unit: order.unit,
            orderedQuantity: order.orderedQuantity,
            receivedQuantity: order.receivedQuantity,
            description: order.description,
            orderedAt: order.orderedAt,
            orderedBy: order.orderedBy,
            status: StockOrderStatus.received,
            sentAt: order.sentAt,
            sentBy: order.sentBy,
            receivedAt: DateTime.now(),
            receivedBy: role.label,
            paidAmount: order.paidAmount,
            unitPriceAtDispatch: order.unitPriceAtDispatch,
            fieldId: order.fieldId,
            fieldName: order.fieldName,
          )
        else
          stockOrders[i],
    ];
    stockMovements = [
      StockMovement(
        itemId: order.itemId,
        kind: StockMovementKind.receipt,
        quantity: order.receivedQuantity,
        description: order.description,
        recordedAt: DateTime.now(),
        recordedBy: role.label,
        paidAmount: order.paidAmount,
        fieldId: order.fieldId,
        fieldName: order.fieldName,
      ),
      ...stockMovements,
    ];
    notifyListeners();
    return true;
  }

  Future<void> reportMaterialAlert({
    required String itemId,
    required MaterialAlertKind kind,
    required double quantity,
    required String description,
  }) async {
    if (role != UserRole.fieldManager ||
        kind != MaterialAlertKind.missing ||
        quantity <= 0 ||
        description.trim().isEmpty) {
      return;
    }
    final item = stockItemsForSelectedField
        .where((candidate) => candidate.id == itemId)
        .firstOrNull;
    if (item == null) return;
    if (api != null) {
      final (queued, localId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/stock/alerts',
        entityType: 'alert',
        body: {
          'itemId': int.parse(itemId),
          'kind': kind == MaterialAlertKind.delivery ? 'DELIVERY' : 'MISSING',
          'quantity': quantity,
          'description': description.trim(),
        },
      );
      if (queued) {
        _appliedOfflineOperationIds.add(localId!);
        materialAlerts = [
          MaterialAlert(
            id: localId,
            itemId: itemId,
            kind: kind,
            quantity: quantity,
            description: description.trim(),
            recordedAt: DateTime.now(),
            recordedBy: role.label,
            fieldId: item.fieldId,
            fieldName: item.fieldName,
          ),
          ...materialAlerts,
        ];
        notifyListeners();
        return;
      }
      await refresh();
      return;
    }
    materialAlerts = [
      MaterialAlert(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemId: itemId,
        kind: kind,
        quantity: quantity,
        description: description.trim(),
        recordedAt: DateTime.now(),
        recordedBy: role.label,
        fieldId: item.fieldId,
        fieldName: item.fieldName,
      ),
      ...materialAlerts,
    ];
    notifyListeners();
  }

  Future<bool> resolveMaterialAlert(String alertId) async {
    if (role != UserRole.assistant) return false;
    final index = materialAlerts.indexWhere(
      (alert) => alert.id == alertId && !alert.resolved,
    );
    if (index < 0) return false;
    final alert = materialAlerts[index];
    if (alert.kind == MaterialAlertKind.delivery) return false;
    if (api != null) {
      await api!.request('PUT', '/api/stock/alerts/$alertId/resolve');
      await refresh();
      return true;
    }
    materialAlerts = [
      for (var i = 0; i < materialAlerts.length; i++)
        if (i == index)
          MaterialAlert(
            id: alert.id,
            itemId: alert.itemId,
            kind: alert.kind,
            quantity: alert.quantity,
            description: alert.description,
            recordedAt: alert.recordedAt,
            recordedBy: alert.recordedBy,
            resolved: true,
            fieldId: alert.fieldId,
            fieldName: alert.fieldName,
          )
        else
          materialAlerts[i],
    ];
    notifyListeners();
    return true;
  }

  Future<bool> requestPayroll(String workerId, DateTime scheduledDate) async {
    final worker = workersForSelectedField
        .where((value) => value.id == workerId)
        .firstOrNull;
    if (role != UserRole.assistant ||
        worker == null ||
        payrollDueFor(worker) <= 0 ||
        payrollRequestFor(workerId) != null ||
        _dateParam(scheduledDate).compareTo(_dateParam(DateTime.now())) < 0) {
      return false;
    }
    final amount = payrollDueFor(worker);
    if (api != null) {
      await api!.request(
        'POST',
        '/api/payroll/requests',
        body: {
          'workerId': int.parse(workerId),
          'through': _monthParam(payrollMonth),
          'scheduledPaymentDate': _dateParam(scheduledDate),
        },
      );
      await refresh();
      return true;
    }
    payrollRequests = [
      PayrollPaymentRequest(
        id: 'request-${DateTime.now().microsecondsSinceEpoch}',
        workerId: workerId,
        workerName: worker.name,
        amount: amount,
        throughDate: DateTime(payrollMonth.year, payrollMonth.month + 1, 0),
        scheduledPaymentDate: DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
        ),
        status: PayrollRequestStatus.pending,
        requestedAt: DateTime.now(),
        requestedBy: role.label,
      ),
      ...payrollRequests,
    ];
    notifyListeners();
    return true;
  }

  Future<bool> decidePayrollRequest(
    String requestId, {
    required bool approve,
  }) async {
    if (!RolePermissions.canApprovePayroll(role)) return false;
    final index = payrollRequests.indexWhere(
      (request) =>
          request.id == requestId &&
          request.status == PayrollRequestStatus.pending,
    );
    if (index < 0) return false;
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/payroll/requests/$requestId/decision',
        body: {'approved': approve},
      );
      await refresh();
      return true;
    }
    final request = payrollRequests[index];
    payrollRequests = [
      for (var i = 0; i < payrollRequests.length; i++)
        if (i == index)
          PayrollPaymentRequest(
            id: request.id,
            workerId: request.workerId,
            workerName: request.workerName,
            amount: request.amount,
            throughDate: request.throughDate,
            scheduledPaymentDate: request.scheduledPaymentDate,
            status: approve
                ? PayrollRequestStatus.approved
                : PayrollRequestStatus.rejected,
            requestedAt: request.requestedAt,
            requestedBy: request.requestedBy,
            decidedAt: DateTime.now(),
            decidedBy: role.label,
          )
        else
          payrollRequests[i],
    ];
    notifyListeners();
    return true;
  }

  Future<bool> confirmPayrollPaid(String requestId, DateTime paidDate) async {
    if (role != UserRole.assistant) return false;
    final index = payrollRequests.indexWhere(
      (request) =>
          request.id == requestId &&
          request.status == PayrollRequestStatus.approved,
    );
    if (index < 0) return false;
    final request = payrollRequests[index];
    final localPaidDate = DateTime(paidDate.year, paidDate.month, paidDate.day);
    if (localPaidDate.isBefore(request.scheduledPaymentDate) ||
        localPaidDate.isAfter(DateTime.now())) {
      return false;
    }
    if (api != null) {
      await api!.request(
        'PUT',
        '/api/payroll/requests/$requestId/paid',
        body: {'paidDate': _dateParam(localPaidDate)},
      );
      await refresh();
      return true;
    }
    payrollRequests = [
      for (var i = 0; i < payrollRequests.length; i++)
        if (i == index)
          PayrollPaymentRequest(
            id: request.id,
            workerId: request.workerId,
            workerName: request.workerName,
            amount: request.amount,
            throughDate: request.throughDate,
            scheduledPaymentDate: request.scheduledPaymentDate,
            status: PayrollRequestStatus.paid,
            requestedAt: request.requestedAt,
            requestedBy: request.requestedBy,
            decidedAt: request.decidedAt,
            decidedBy: request.decidedBy,
            paidAt: localPaidDate,
            paidBy: role.label,
          )
        else
          payrollRequests[i],
    ];
    payments = [
      Payment(
        workerId: request.workerId,
        amount: request.amount,
        recordedAt: localPaidDate,
        recordedBy: role.label,
        fieldId: workersForSelectedField
            .where((worker) => worker.id == request.workerId)
            .firstOrNull
            ?.fieldId,
        fieldName: workersForSelectedField
            .where((worker) => worker.id == request.workerId)
            .firstOrNull
            ?.fieldName,
      ),
      ...payments,
    ];
    payrollDueAmounts[request.workerId] = 0;
    notifyListeners();
    return true;
  }

  Future<bool> addOvertime(
    String workerId,
    double hours,
    String description,
  ) async {
    if (role != UserRole.fieldManager || hours <= 0) return false;
    if (workersForSelectedField.every((worker) => worker.id != workerId)) {
      return false;
    }
    if (api != null) {
      final (queued, operationId) = await _sendOrQueueFieldOperation(
        method: 'POST',
        path: '/api/overtime',
        body: {
          'workerId': int.tryParse(workerId) ?? workerId,
          'hours': hours,
          'description': description.trim(),
        },
      );
      if (queued) {
        _appliedOfflineOperationIds.add(operationId!);
        overtimeRecords = [
          OvertimeRecord(
            workerId: workerId,
            hours: hours,
            description: description.trim(),
            recordedAt: DateTime.now(),
            fieldId: workers
                .where((worker) => worker.id == workerId)
                .firstOrNull
                ?.fieldId,
            fieldName: workers
                .where((worker) => worker.id == workerId)
                .firstOrNull
                ?.fieldName,
          ),
          ...overtimeRecords,
        ];
        notifyListeners();
        return true;
      }
      await refresh();
      return true;
    }
    overtimeRecords = [
      OvertimeRecord(
        workerId: workerId,
        hours: hours,
        description: description.trim(),
        recordedAt: DateTime.now(),
        fieldId: workers
            .where((worker) => worker.id == workerId)
            .firstOrNull
            ?.fieldId,
        fieldName: workers
            .where((worker) => worker.id == workerId)
            .firstOrNull
            ?.fieldName,
      ),
      ...overtimeRecords,
    ];
    notifyListeners();
    return true;
  }
}
