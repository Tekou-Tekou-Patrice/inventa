import 'dart:math';

import 'package:sembast/sembast.dart';

import 'offline_database.dart';

class OfflineExpenseEntry {
  const OfflineExpenseEntry({
    required this.id,
    required this.accountId,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.serverResult,
  });

  final String id;
  final String accountId;
  final Map<String, Object?> payload;
  final String status;
  final DateTime createdAt;
  final Map<String, Object?>? serverResult;

  bool get needsSync => status == 'queued';

  static OfflineExpenseEntry fromRecord(
    String id,
    Map<String, Object?> record,
  ) {
    final payload = record['payload'];
    final serverResult = record['serverResult'];
    return OfflineExpenseEntry(
      id: id,
      accountId: record['accountId']! as String,
      payload: Map<String, Object?>.from(payload! as Map),
      status: record['status']! as String,
      createdAt: DateTime.parse(record['createdAt']! as String),
      serverResult: serverResult == null
          ? null
          : Map<String, Object?>.from(serverResult as Map),
    );
  }
}

class OfflineOperationEntry {
  const OfflineOperationEntry({
    required this.id,
    required this.accountId,
    required this.method,
    required this.path,
    required this.body,
    required this.createdAt,
    this.localEntityId,
  });

  final String id;
  final String accountId;
  final String method;
  final String path;
  final Map<String, Object?> body;
  final DateTime createdAt;
  final String? localEntityId;

  static OfflineOperationEntry fromRecord(
    String id,
    Map<String, Object?> record,
  ) => OfflineOperationEntry(
    id: id,
    accountId: record['accountId']! as String,
    method: record['method']! as String,
    path: record['path']! as String,
    body: Map<String, Object?>.from(record['body']! as Map),
    createdAt: DateTime.parse(record['createdAt']! as String),
    localEntityId: record['localEntityId'] as String?,
  );
}

class OfflineOperationStore {
  OfflineOperationStore(this._database)
    : _expenses = stringMapStoreFactory.store('offline_expenses'),
      _operations = stringMapStoreFactory.store('offline_operations'),
      _idMappings = stringMapStoreFactory.store('offline_id_mappings'),
      _budgets = stringMapStoreFactory.store('budget_snapshots'),
      _workspaces = stringMapStoreFactory.store('workspace_snapshots');

  static Future<OfflineOperationStore>? _defaultStore;

  final Database _database;
  final StoreRef<String, Map<String, Object?>> _expenses;
  final StoreRef<String, Map<String, Object?>> _operations;
  final StoreRef<String, Map<String, Object?>> _idMappings;
  final StoreRef<String, Map<String, Object?>> _budgets;
  final StoreRef<String, Map<String, Object?>> _workspaces;

  static Future<OfflineOperationStore> openDefault() => _defaultStore ??=
      openOfflineDatabase('inventa-offline.db').then(OfflineOperationStore.new);

  Future<void> saveBudgetSnapshot(
    String accountId,
    Map<String, Object?> snapshot,
  ) => _budgets.record(accountId).put(_database, snapshot);

  Future<Map<String, Object?>?> readBudgetSnapshot(String accountId) async {
    final value = await _budgets.record(accountId).get(_database);
    return value == null ? null : Map<String, Object?>.from(value);
  }

  Future<void> saveWorkspaceSnapshot(String scope, List<dynamic> snapshot) =>
      _workspaces.record(scope).put(_database, {
        'snapshot': snapshot,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      });

  Future<List<dynamic>?> readWorkspaceSnapshot(String scope) async {
    final value = await _workspaces.record(scope).get(_database);
    if (value == null) return null;
    final snapshot = value['snapshot'];
    if (snapshot is! List) {
      throw FormatException('Cached workspace for $scope is invalid.');
    }
    return List<dynamic>.from(snapshot);
  }

  Future<OfflineExpenseEntry> enqueueExpense({
    required String accountId,
    required Map<String, Object?> payload,
  }) async {
    final id = _newUuid();
    final createdAt = DateTime.now().toUtc();
    final record = <String, Object?>{
      'accountId': accountId,
      'payload': payload,
      'status': 'queued',
      'createdAt': createdAt.toIso8601String(),
    };
    await _expenses.record(id).put(_database, record);
    return OfflineExpenseEntry.fromRecord(id, record);
  }

  Future<OfflineOperationEntry> enqueueOperation({
    required String accountId,
    required String method,
    required String path,
    required Map<String, Object?> body,
    String? entityType,
  }) async {
    final id = _newUuid();
    final record = <String, Object?>{
      'accountId': accountId,
      'method': method,
      'path': path,
      'body': body,
      'localEntityId': entityType == null ? null : id,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    await _operations.record(id).put(_database, record);
    return OfflineOperationEntry.fromRecord(id, record);
  }

  Future<List<OfflineOperationEntry>> queuedOperations(String accountId) async {
    final records = await _operations.find(
      _database,
      finder: Finder(
        filter: Filter.equals('accountId', accountId),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return [
      for (final record in records)
        OfflineOperationEntry.fromRecord(record.key, record.value),
    ];
  }

  Future<void> markOperationSynced(
    OfflineOperationEntry entry,
    Map<String, Object?>? serverResult,
  ) async {
    final localId = entry.localEntityId;
    final serverId = serverResult?['id'];
    if (localId != null && serverId != null) {
      await _idMappings.record('${entry.accountId}|$localId').put(_database, {
        'accountId': entry.accountId,
        'localId': localId,
        'serverId': serverId.toString(),
      });
    }
    await _operations.record(entry.id).delete(_database);
  }

  Future<(String, Map<String, Object?>)> resolveOperationReferences(
    OfflineOperationEntry entry,
  ) async {
    final records = await _idMappings.find(
      _database,
      finder: Finder(filter: Filter.equals('accountId', entry.accountId)),
    );
    final mappings = {
      for (final record in records)
        record.value['localId']! as String: record.value['serverId']! as String,
    };
    String resolvePath(String path) {
      final uri = Uri.parse(path);
      final segments = uri.pathSegments
          .map((segment) => mappings[segment] ?? segment)
          .join('/');
      final query = uri.queryParameters.map(
        (key, value) => MapEntry(key, mappings[value] ?? value),
      );
      return '/$segments${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}';
    }

    Object? resolveValue(Object? value) {
      if (value is String && mappings.containsKey(value)) {
        final serverId = mappings[value]!;
        return int.tryParse(serverId) ?? serverId;
      }
      if (value is List) return value.map(resolveValue).toList();
      if (value is Map) {
        return value.map(
          (key, value) => MapEntry(key.toString(), resolveValue(value)),
        );
      }
      return value;
    }

    return (
      resolvePath(entry.path),
      Map<String, Object?>.from(resolveValue(entry.body)! as Map),
    );
  }

  Future<List<OfflineExpenseEntry>> expensesForAccount(String accountId) async {
    final records = await _expenses.find(
      _database,
      finder: Finder(
        filter: Filter.equals('accountId', accountId),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return [
      for (final record in records)
        OfflineExpenseEntry.fromRecord(record.key, record.value),
    ];
  }

  Future<List<OfflineExpenseEntry>> queuedExpenses(String accountId) async =>
      (await expensesForAccount(
        accountId,
      )).where((entry) => entry.needsSync).toList();

  Future<void> markExpenseSynced(
    String id,
    Map<String, Object?> serverResult,
  ) async {
    final existing = await _expenses.record(id).get(_database);
    if (existing == null) {
      throw StateError('Offline expense $id does not exist.');
    }
    await _expenses.record(id).put(_database, {
      ...existing,
      'status': 'synced',
      'serverResult': serverResult,
    });
  }

  Future<void> markExpenseForReconciliation(
    String id,
    Map<String, Object?> serverResult,
  ) async {
    final existing = await _expenses.record(id).get(_database);
    if (existing == null) {
      throw StateError('Offline expense $id does not exist.');
    }
    await _expenses.record(id).put(_database, {
      ...existing,
      'status': 'pending_reconciliation',
      'serverResult': serverResult,
    });
  }

  Future<void> discardExpense(String id) async {
    await _expenses.record(id).delete(_database);
  }

  Future<void> close() => _database.close();

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
