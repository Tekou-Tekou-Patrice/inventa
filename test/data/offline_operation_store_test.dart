import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/data/offline_operation_store.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late Database database;
  late OfflineOperationStore store;

  setUp(() async {
    database = await databaseFactoryMemory.openDatabase('offline-test.db');
    store = OfflineOperationStore(database);
  });

  tearDown(() async {
    await store.close();
  });

  test('stores a budget snapshot for the signed-in account', () async {
    await store.saveBudgetSnapshot('assistant-1', {
      'remaining': 12000,
      'fields': [
        {'fieldId': 1, 'remaining': 9000},
      ],
    });

    final snapshot = await store.readBudgetSnapshot('assistant-1');

    expect(snapshot?['remaining'], 12000);
    expect(await store.readBudgetSnapshot('assistant-2'), isNull);
  });

  test(
    'stores workspace snapshots separately for each account and scope',
    () async {
      await store.saveWorkspaceSnapshot('terrain|fieldManager|8', [
        [
          {'id': 1, 'name': 'Worker A'},
        ],
        [],
      ]);

      final snapshot = await store.readWorkspaceSnapshot(
        'terrain|fieldManager|8',
      );

      expect(snapshot, [
        [
          {'id': 1, 'name': 'Worker A'},
        ],
        [],
      ]);
      expect(
        await store.readWorkspaceSnapshot('terrain|fieldManager|9'),
        isNull,
      );
    },
  );

  test(
    'keeps queued expenses until they are explicitly synchronized',
    () async {
      final entry = await store.enqueueExpense(
        accountId: 'assistant-1',
        payload: const {'fieldId': 1, 'amount': 2500},
      );

      expect(entry.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(entry.needsSync, isTrue);
      expect(await store.queuedExpenses('assistant-1'), hasLength(1));
      expect(await store.queuedExpenses('assistant-2'), isEmpty);

      await store.markExpenseForReconciliation(entry.id, const {
        'status': 'PENDING_RECONCILIATION',
      });

      expect(await store.queuedExpenses('assistant-1'), isEmpty);
      expect(
        (await store.expensesForAccount('assistant-1')).single.status,
        'pending_reconciliation',
      );
    },
  );

  test(
    'preserves concurrent expense enqueues as distinct durable operations',
    () async {
      await Future.wait([
        for (var index = 0; index < 8; index++)
          store.enqueueExpense(
            accountId: 'assistant-1',
            payload: {'fieldId': 1, 'amount': 1000 + index},
          ),
      ]);

      final entries = await store.queuedExpenses('assistant-1');
      expect(entries, hasLength(8));
      expect(entries.map((entry) => entry.id).toSet(), hasLength(8));
    },
  );

  test(
    'resolves local entity ids after queued creates are synchronized',
    () async {
      final worker = await store.enqueueOperation(
        accountId: 'terrain-1',
        method: 'POST',
        path: '/api/workers',
        entityType: 'worker',
        body: const {'name': 'Worker offline'},
      );
      expect(worker.localEntityId, worker.id);
      await store.markOperationSynced(worker, const {'id': 42});

      final task = await store.enqueueOperation(
        accountId: 'terrain-1',
        method: 'POST',
        path: '/api/tasks',
        entityType: 'task',
        body: {
          'title': 'Offline task',
          'assigneeIds': [worker.id],
        },
      );
      final (path, body) = await store.resolveOperationReferences(task);

      expect(path, '/api/tasks');
      expect(body['assigneeIds'], [42]);
      expect(
        (await store.queuedOperations('terrain-1')).map((entry) => entry.id),
        [task.id],
      );
    },
  );
}
