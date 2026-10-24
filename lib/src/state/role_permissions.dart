import '../models/plantation_models.dart';

abstract final class RolePermissions {
  static bool canViewAttendance(UserRole role) =>
      role == UserRole.director ||
      role == UserRole.assistant ||
      role == UserRole.fieldManager;

  static bool canViewTasks(UserRole role) => true;

  static bool canViewStock(UserRole role) =>
      role == UserRole.director ||
      role == UserRole.assistant ||
      role == UserRole.fieldManager;

  static bool canViewExpenses(UserRole role) =>
      role == UserRole.director ||
      role == UserRole.assistant ||
      role == UserRole.fieldManager;

  static bool canViewBudget(UserRole role) =>
      role == UserRole.director ||
      role == UserRole.assistant ||
      role == UserRole.fieldManager;

  static bool canSetBudgetLimit(UserRole role) => role == UserRole.director;

  static bool canAllocateBudget(UserRole role) => role == UserRole.assistant;

  static bool canRecordBudgetExpense(UserRole role) =>
      role == UserRole.assistant || role == UserRole.fieldManager;

  static bool canViewPayments(UserRole role) =>
      role == UserRole.director || role == UserRole.assistant;

  static bool canViewDailyReport(UserRole role) =>
      role == UserRole.director || role == UserRole.assistant;

  static bool canViewOvertime(UserRole role) =>
      role == UserRole.director || role == UserRole.fieldManager;

  static bool canViewPayrollEstimate(UserRole role) =>
      role == UserRole.director || role == UserRole.assistant;

  static Set<AppSection> visibleSections(UserRole role) => switch (role) {
    UserRole.director => {
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
    },
    UserRole.assistant => {
      AppSection.dashboard,
      AppSection.attendance,
      AppSection.workers,
      AppSection.tasks,
      AppSection.report,
      AppSection.stock,
      AppSection.expenses,
      AppSection.payroll,
    },
    UserRole.fieldManager => {
      AppSection.dashboard,
      AppSection.attendance,
      AppSection.workers,
      AppSection.tasks,
      AppSection.stock,
      AppSection.expenses,
    },
  };

  static bool canMarkAttendance(UserRole role) => role == UserRole.fieldManager;

  static bool canManageWorkers(UserRole role) => role == UserRole.fieldManager;

  static bool canManageWorkerRecords(UserRole role) =>
      role == UserRole.fieldManager || role == UserRole.assistant;

  static bool canManageWorkerContacts(UserRole role) =>
      role == UserRole.assistant;

  static bool canManageWorkerSalary(UserRole role) =>
      role == UserRole.assistant || role == UserRole.director;

  static bool canManageAccounts(UserRole role) => role == UserRole.director;

  static bool canManageFields(UserRole role) => role == UserRole.director;

  static bool canManageTasks(UserRole role) => role == UserRole.fieldManager;

  static bool canReceiveStock(UserRole role) => role == UserRole.fieldManager;

  static bool canOrderStock(UserRole role) => role == UserRole.fieldManager;

  static bool canDispatchStock(UserRole role) => role == UserRole.assistant;

  static bool canUseStock(UserRole role) => role == UserRole.fieldManager;

  static bool canRecordExpense(UserRole role) =>
      role == UserRole.assistant || role == UserRole.fieldManager;

  static bool canRecordPayment(UserRole role) => role == UserRole.assistant;

  static bool canRecordHarvestSale(UserRole role) =>
      role == UserRole.assistant || role == UserRole.fieldManager;

  static bool canApprovePayroll(UserRole role) => role == UserRole.director;

  static bool canRecordOvertime(UserRole role) => role == UserRole.fieldManager;
}
