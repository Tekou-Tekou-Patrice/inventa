enum UserRole {
  director,

  assistant,
  fieldManager;

  static UserRole fromApi(Object? role) => switch (role) {
    'DIRECTOR' => UserRole.director,
    'ASSISTANT' => UserRole.assistant,
    'FIELD_MANAGER' => UserRole.fieldManager,
    _ => throw FormatException('Rôle Inventa inconnu : $role'),
  };
}

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.director => 'Directeur',
    UserRole.assistant => 'Assistant achats',
    UserRole.fieldManager => 'Responsable de champ',
  };

  String get shortLabel => switch (this) {
    UserRole.director => 'Directeur',
    UserRole.assistant => 'Assistant',
    UserRole.fieldManager => 'Terrain',
  };
}

enum AppSection {
  dashboard,
  fields,
  attendance,
  workers,
  accounts,
  tasks,
  report,
  stock,
  expenses,
  payroll,
}

extension AppSectionDetails on AppSection {
  String get label => switch (this) {
    AppSection.dashboard => 'Vue d’ensemble',
    AppSection.fields => 'Champs',
    AppSection.attendance => 'Présences',
    AppSection.workers => 'Ouvriers',
    AppSection.accounts => 'Comptes',
    AppSection.tasks => 'Tâches',
    AppSection.report => 'Rapport',
    AppSection.stock => 'Stocks & achats',
    AppSection.expenses => 'Dépenses',
    AppSection.payroll => 'Paie',
  };

  String get shortLabel => switch (this) {
    AppSection.dashboard => 'Accueil',
    AppSection.fields => 'Champs',
    AppSection.attendance => 'Présences',
    AppSection.workers => 'Équipe',
    AppSection.accounts => 'Comptes',
    AppSection.tasks => 'Tâches',
    AppSection.report => 'Rapport',
    AppSection.stock => 'Stocks',
    AppSection.expenses => 'Dépenses',
    AppSection.payroll => 'Paie',
  };

  String get subtitle => switch (this) {
    AppSection.dashboard => 'Le point sur votre plantation',
    AppSection.fields => 'Vos sites et équipes',
    AppSection.attendance => 'Le pointage de votre équipe',
    AppSection.workers => 'Votre équipe au quotidien',
    AppSection.accounts => 'Accès des assistants et responsables de terrain',
    AppSection.tasks => 'Le travail dans les parcelles',
    AppSection.report => 'Le rapport des opérations au directeur',
    AppSection.stock => 'Vos intrants et fournitures',
    AppSection.expenses => 'Les sorties du jour',
    AppSection.payroll => 'Salaires et paiements',
  };
}

class PlantationField {
  const PlantationField({
    required this.id,
    required this.name,
    required this.location,
    this.description = '',
  });

  final String id;
  final String name;
  final String location;
  final String description;
}

class ManagedAccount {
  const ManagedAccount({
    required this.id,
    required this.username,
    required this.role,
    required this.enabled,
    this.phoneNumber = '',
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String username;
  final UserRole role;
  final bool enabled;
  final String phoneNumber;
  final String? fieldId;
  final String? fieldName;
}

class Worker {
  const Worker({
    required this.id,
    required this.name,
    required this.group,
    required this.salary,
    required this.active,
    this.salaryIsIndividual = false,
    this.phoneNumber = '',
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String name;
  final String group;
  final int salary;
  final bool active;
  final bool salaryIsIndividual;
  final String phoneNumber;
  final String? fieldId;
  final String? fieldName;
}

enum AttendanceStatus { unmarked, present, absent }

class AttendanceRecord {
  const AttendanceRecord({
    required this.workerId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.fieldId,
    this.fieldName,
  });

  final String workerId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? fieldId;
  final String? fieldName;
}

enum FieldTaskStatus { enCours, aFaire, termine }

enum FieldTaskType { assignedWorkers, seasonalWorkers }

class FieldTask {
  const FieldTask({
    required this.id,
    required this.title,
    required this.assigneeIds,
    required this.status,
    required this.createdAt,
    this.type = FieldTaskType.assignedWorkers,
    this.completedAt,
    this.actualCost,
    this.seasonalWorkerCount,
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String title;
  final List<String> assigneeIds;
  final FieldTaskStatus status;
  final FieldTaskType type;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? actualCost;
  final int? seasonalWorkerCount;
  final String? fieldId;
  final String? fieldName;
}

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.unitPrice,
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String name;
  final String unit;
  final double quantity;
  final int? unitPrice;
  final String? fieldId;
  final String? fieldName;
}

enum StockMovementKind { receipt, usage }

enum MaterialAlertKind { missing, delivery }

class MaterialAlert {
  const MaterialAlert({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.quantity,
    required this.description,
    required this.recordedAt,
    required this.recordedBy,
    this.resolved = false,
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String itemId;
  final MaterialAlertKind kind;
  final double quantity;
  final String description;
  final DateTime recordedAt;
  final String recordedBy;
  final bool resolved;
  final String? fieldId;
  final String? fieldName;
}

class StockMovement {
  const StockMovement({
    required this.itemId,
    required this.kind,
    required this.quantity,
    required this.description,
    required this.recordedAt,
    required this.recordedBy,
    this.fieldId,
    this.fieldName,
    this.paidAmount,
  });

  final String itemId;
  final StockMovementKind kind;
  final double quantity;
  final String description;
  final DateTime recordedAt;
  final String recordedBy;
  final String? fieldId;
  final String? fieldName;
  final int? paidAmount;
}

enum StockOrderStatus { ordered, sent, received }

class StockOrder {
  const StockOrder({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.description,
    required this.orderedAt,
    required this.orderedBy,
    required this.status,
    this.sentAt,
    this.sentBy,
    this.receivedAt,
    this.receivedBy,
    this.paidAmount,
    this.unitPriceAtDispatch,
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String unit;
  final double orderedQuantity;
  final double receivedQuantity;
  final String description;
  final DateTime orderedAt;
  final String orderedBy;
  final StockOrderStatus status;
  final DateTime? sentAt;
  final String? sentBy;
  final DateTime? receivedAt;
  final String? receivedBy;
  final int? paidAmount;
  final int? unitPriceAtDispatch;
  final String? fieldId;
  final String? fieldName;
}

class Expense {
  const Expense({
    required this.description,
    required this.amount,
    required this.recordedAt,
    required this.recordedBy,
    this.budgeted = false,
    this.status = ExpenseStatus.confirmed,
    this.idempotencyKey,
    this.fieldId,
    this.fieldName,
  });

  final String description;
  final int amount;
  final DateTime recordedAt;
  final String recordedBy;
  final bool budgeted;
  final ExpenseStatus status;
  final String? idempotencyKey;
  final String? fieldId;
  final String? fieldName;
}

enum ExpenseStatus { confirmed, pendingReconciliation, queuedOffline }

class FieldBudget {
  const FieldBudget({
    required this.fieldId,
    required this.fieldName,
    required this.allocatedAmount,
    required this.remainingAmount,
    required this.pendingExpenses,
    required this.blocked,
  });

  final String fieldId;
  final String fieldName;
  final int allocatedAmount;
  final int remainingAmount;
  final int pendingExpenses;
  final bool blocked;
}

class BudgetSummary {
  const BudgetSummary({
    required this.fundingLimit,
    required this.confirmedExpenses,
    required this.pendingExpenses,
    required this.remainingAmount,
    required this.unallocatedAmount,
    required this.fields,
  });

  final int fundingLimit;
  final int confirmedExpenses;
  final int pendingExpenses;
  final int remainingAmount;
  final int unallocatedAmount;
  final List<FieldBudget> fields;
}

class Payment {
  const Payment({
    required this.workerId,
    required this.amount,
    required this.recordedAt,
    required this.recordedBy,
    this.fieldId,
    this.fieldName,
    this.paidThroughEnd,
  });

  final String workerId;
  final int amount;
  final DateTime recordedAt;
  final String recordedBy;
  final String? fieldId;
  final String? fieldName;
  final DateTime? paidThroughEnd;
}

class HarvestSale {
  const HarvestSale({
    required this.id,
    required this.product,
    required this.quantity,
    required this.totalPrice,
    required this.recordedAt,
    required this.recordedBy,
    this.fieldId,
    this.fieldName,
  });

  final String id;
  final String product;
  final double quantity;
  final int totalPrice;
  final DateTime recordedAt;
  final String recordedBy;
  final String? fieldId;
  final String? fieldName;
}

enum PayrollRequestStatus { pending, approved, rejected, paid }

class PayrollPaymentRequest {
  const PayrollPaymentRequest({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.throughDate,
    required this.scheduledPaymentDate,
    required this.status,
    required this.requestedAt,
    required this.requestedBy,
    this.decidedAt,
    this.decidedBy,
    this.paidAt,
    this.paidBy,
  });

  final String id;
  final String workerId;
  final String workerName;
  final int amount;
  final DateTime throughDate;
  final DateTime scheduledPaymentDate;
  final PayrollRequestStatus status;
  final DateTime requestedAt;
  final String requestedBy;
  final DateTime? decidedAt;
  final String? decidedBy;
  final DateTime? paidAt;
  final String? paidBy;
}

class DailyReportSnapshot {
  const DailyReportSnapshot({
    this.attendance = const [],
    this.tasks = const [],
    this.movements = const [],
    this.alerts = const [],
    this.expenses = const [],
    this.payments = const [],
    this.sales = const [],
    this.validated = false,
    this.validatedAt,
    this.validatedBy,
  });

  final List<AttendanceRecord> attendance;
  final List<FieldTask> tasks;
  final List<StockMovement> movements;
  final List<MaterialAlert> alerts;
  final List<Expense> expenses;
  final List<Payment> payments;
  final List<HarvestSale> sales;
  final bool validated;
  final DateTime? validatedAt;
  final String? validatedBy;
}

class OvertimeRecord {
  const OvertimeRecord({
    required this.workerId,
    required this.hours,
    required this.description,
    required this.recordedAt,
    this.fieldId,
    this.fieldName,
  });

  final String workerId;
  final double hours;
  final String description;
  final DateTime recordedAt;
  final String? fieldId;
  final String? fieldName;
}
