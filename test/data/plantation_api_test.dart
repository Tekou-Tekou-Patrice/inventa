import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventa/main.dart';
import 'package:inventa/src/data/offline_operation_store.dart';
import 'package:inventa/src/data/plantation_api.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';
import 'package:sembast/sembast_memory.dart';

class _MemorySessionCredentialStore implements SessionCredentialStore {
  String? username;
  String? password;
  String? identity;

  @override
  Future<void> clear() async {
    username = null;
    password = null;
    identity = null;
  }

  @override
  Future<String?> readPassword() async => password;

  @override
  Future<String?> readIdentity() async => identity;

  @override
  Future<String?> readUsername() async => username;

  @override
  Future<void> save(String username, String password) async {
    this.username = username;
    this.password = password;
  }

  @override
  Future<void> saveIdentity(String identity) async {
    this.identity = identity;
  }
}

void main() {
  test(
    'checks first-director registration and submits without credentials',
    () async {
      final requests = <http.Request>[];
      final api = PlantationApi(
        baseUrl: 'https://inventa.test',
        sessionCredentialStore: _MemorySessionCredentialStore(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/auth/director-registration') {
            return http.Response('{"available":true}', 200);
          }
          return http.Response(
            '{"id":1,"username":"patron","role":"DIRECTOR"}',
            201,
          );
        }),
      );

      expect(await api.canRegisterDirector(), isTrue);
      await api.registerDirector(
        username: ' patron ',
        password: 'Directeur42!',
        phoneNumber: ' +2250700000000 ',
      );

      expect(requests.map((request) => request.method), ['GET', 'POST']);
      expect(requests.last.url.path, '/api/auth/register-director');
      expect(requests.last.headers.containsKey('authorization'), isFalse);
      expect(jsonDecode(requests.last.body), {
        'username': 'patron',
        'password': 'Directeur42!',
        'phoneNumber': '+2250700000000',
      });
      expect(api.isAuthenticated, isFalse);
      await api.close();
    },
  );

  test(
    'authenticates and sends Basic credentials to protected requests',
    () async {
      final requests = <http.Request>[];
      final api = PlantationApi(
        baseUrl: 'https://inventa.test',
        sessionCredentialStore: _MemorySessionCredentialStore(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/auth/me') {
            return http.Response(
              jsonEncode({
                'id': 7,
                'username': 'terrain',
                'role': 'FIELD_MANAGER',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/payroll/settings') {
            return http.Response(
              jsonEncode({'monthlySalary': 90000, 'monthlyRequiredHours': 208}),
              200,
            );
          }
          if (request.url.path == '/api/budgets/field') {
            return http.Response(
              '{"fundingLimit":0,"confirmedExpenses":0,"pendingExpenses":0,"remainingAmount":0,"unallocatedAmount":0,"fields":[]}',
              200,
            );
          }
          return http.Response('[]', 200);
        }),
      );

      final identity = await api.login('terrain', 'temporary-password');
      expect(identity['role'], 'FIELD_MANAGER');
      expect(api.isAuthenticated, isTrue);

      await api.request('GET', '/api/workers');
      expect(requests.last.url.path, '/api/workers');
      expect(
        requests.last.headers['authorization'],
        'Basic ${base64Encode(utf8.encode('terrain:temporary-password'))}',
      );

      final state = PlantationState(api: api, seedDemoData: false);
      state.setRole(UserRole.fromApi(identity['role']));
      await state.refresh();
      expect(state.workers, isEmpty);
      expect(
        requests.map((request) => request.url.path),
        isNot(contains('/api/payments')),
      );
      expect(
        requests.map((request) => request.url.path),
        isNot(contains('/api/payroll/due')),
      );
      state.dispose();

      await api.clearSession();
      expect(api.isAuthenticated, isFalse);
      await api.close();
    },
  );

  test('sends arrival and departure timestamps as ISO instants', () async {
    final writes = <Map<String, dynamic>>[];
    Map<String, dynamic>? attendanceRecord;
    final api = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: _MemorySessionCredentialStore(),
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'role': 'FIELD_MANAGER', 'fieldId': 1}),
            200,
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/api/attendance/')) {
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          writes.add(payload);
          attendanceRecord = {
            'workerId': 1,
            'date': request.url.queryParameters['date'],
            'status': 'PRESENT',
            'checkIn': payload['checkIn'] ?? attendanceRecord?['checkIn'],
            'checkOut': payload['checkOut'] ?? attendanceRecord?['checkOut'],
            'fieldId': 1,
            'fieldName': 'Field test',
          };
          return http.Response(jsonEncode(attendanceRecord), 200);
        }
        if (request.url.path == '/api/workers') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'name': 'Worker test',
                'group': 'Team',
                'salary': 3500,
                'active': true,
                'fieldId': 1,
                'fieldName': 'Field test',
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/fields') {
          return http.Response(
            '[{"id":1,"name":"Field test","location":"","description":""}]',
            200,
          );
        }
        if (request.url.path == '/api/payroll/settings') {
          return http.Response(
            '{"monthlySalary":90000,"monthlyRequiredHours":208}',
            200,
          );
        }
        if (request.url.path == '/api/budgets/field') {
          return http.Response(
            '{"fundingLimit":0,"confirmedExpenses":0,"pendingExpenses":0,"remainingAmount":0,"unallocatedAmount":0,"fields":[]}',
            200,
          );
        }
        if (request.url.path == '/api/attendance' ||
            request.url.path == '/api/attendance/month') {
          return http.Response(
            jsonEncode(attendanceRecord == null ? [] : [attendanceRecord]),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
    final identity = await api.login('terrain', 'password');
    final state =
        PlantationState(
            api: api,
            seedDemoData: false,
            networkAvailable: () async => true,
          )
          ..setRole(UserRole.fromApi(identity['role']))
          ..setAssignedFieldId('${identity['fieldId']}');
    await state.refresh();

    await state.markAttendance('1', AttendanceStatus.present);
    expect(await state.checkOutWorker('1'), isTrue);

    expect(writes, hasLength(2));
    for (final write in writes) {
      final timestamp = write['checkIn'] ?? write['checkOut'];
      expect(timestamp, isA<String>());
      expect(DateTime.parse(timestamp as String).isUtc, isTrue);
      expect(timestamp.endsWith('Z'), isTrue);
    }

    state.dispose();
    await api.close();
  });

  test('rejects invalid credentials without retaining them', () async {
    final api = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: _MemorySessionCredentialStore(),
      client: MockClient((_) async => http.Response('Unauthorized', 401)),
    );

    await expectLater(
      api.login('wrong', 'password'),
      throwsA(isA<ApiException>()),
    );
    expect(api.isAuthenticated, isFalse);
    await api.close();
  });

  test('restores saved credentials and removes them on logout', () async {
    final credentials = _MemorySessionCredentialStore();
    final firstApi = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: credentials,
      client: MockClient(
        (_) async => http.Response('{"role":"ASSISTANT"}', 200),
      ),
    );
    await firstApi.login('assistant', 'password');
    await firstApi.close();

    final requests = <http.Request>[];
    final secondApi = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: credentials,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{"role":"ASSISTANT"}', 200);
      }),
    );
    final identity = await secondApi.restoreSession();

    expect(identity?['role'], 'ASSISTANT');
    expect(secondApi.authenticatedUsername, 'assistant');
    expect(requests.single.url.path, '/api/auth/me');
    await secondApi.clearSession();
    expect(secondApi.isAuthenticated, isFalse);
    expect(await credentials.readUsername(), isNull);
    expect(await credentials.readPassword(), isNull);
    await secondApi.close();
  });

  test('restores the last identity when the server is unavailable', () async {
    final credentials = _MemorySessionCredentialStore();
    final onlineApi = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: credentials,
      client: MockClient(
        (_) async => http.Response(
          '{"id":3,"username":"terrain","role":"FIELD_MANAGER","fieldId":8}',
          200,
        ),
      ),
    );
    await onlineApi.login('terrain', 'password');
    await onlineApi.close();

    final offlineApi = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: credentials,
      client: MockClient((_) async => throw Exception('network unavailable')),
    );
    final identity = await offlineApi.restoreSession();

    expect(identity?['role'], 'FIELD_MANAGER');
    expect(identity?['fieldId'], 8);
    expect(offlineApi.authenticatedUsername, 'terrain');
    await offlineApi.clearSession();
    expect(await credentials.readIdentity(), isNull);
    await offlineApi.close();
  });

  test('loads the last authorized workspace when refresh is offline', () async {
    var online = true;
    var requestCount = 0;
    final database = await databaseFactoryMemory.openDatabase(
      'workspace-cache-${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final offlineStore = OfflineOperationStore(database);
    final api = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: _MemorySessionCredentialStore(),
      client: MockClient((request) async {
        requestCount++;
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            '{"id":1,"username":"assistant","role":"ASSISTANT"}',
            200,
          );
        }
        if (!online) throw Exception('network unavailable');
        if (request.url.path == '/api/workers') {
          return http.Response(
            '[{"id":4,"name":"Worker cache","group":"Team","salary":5000,"active":true}]',
            200,
          );
        }
        if (request.url.path == '/api/payroll/settings') {
          return http.Response(
            '{"monthlySalary":90000,"monthlyRequiredHours":208}',
            200,
          );
        }
        if (request.url.path == '/api/budgets') {
          return http.Response(
            '{"fundingLimit":0,"confirmedExpenses":0,"pendingExpenses":0,"remainingAmount":0,"unallocatedAmount":0,"fields":[]}',
            200,
          );
        }
        if (request.url.path == '/api/reports/daily') {
          return http.Response(
            '{"attendance":[],"tasks":[],"movements":[],"alerts":[],"expenses":[],"payments":[],"validated":false}',
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
    await api.login('assistant', 'password');
    final state = PlantationState(
      api: api,
      seedDemoData: false,
      offlineStoreFactory: () async => offlineStore,
      networkAvailable: () async => online,
    )..setRole(UserRole.assistant);
    state.setAccountId('assistant');

    await state.refresh();
    expect(state.workers.single.name, 'Worker cache');
    final requestsBeforeOfflineRefresh = requestCount;

    online = false;
    await state.refresh();
    expect(state.workers.single.name, 'Worker cache');
    expect(requestCount, requestsBeforeOfflineRefresh);

    state.dispose();
    await api.close();
    await offlineStore.close();
  });

  test('loads the full monthly report for the selected month', () async {
    final requests = <http.Request>[];
    final api = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: _MemorySessionCredentialStore(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'role': 'ASSISTANT'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/reports/monthly') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'validatedDates': ['2026-10-20'],
                'attendance': [],
                'tasks': [],
                'movements': [],
                'alerts': [],
                'expenses': [],
                'payments': [
                  {
                    'workerId': 8,
                    'workerName': 'Ouvrier test',
                    'amount': 42000,
                    'recordedAt': '2026-10-20T00:00:00Z',
                    'recordedBy': 'assistant',
                    'fieldId': 3,
                    'fieldName': 'Champ test',
                    'paidThroughEnd': '2026-10-31',
                  },
                ],
                'sales': [],
                'overtime': [
                  {
                    'workerId': 8,
                    'workerName': 'Ouvrier test',
                    'hours': 2.5,
                    'description': 'Récolte',
                    'recordedAt': '2026-10-20T00:00:00Z',
                    'fieldId': 3,
                    'fieldName': 'Champ test',
                  },
                ],
              }),
            ),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
    final identity = await api.login('assistant', 'password');
    final state = PlantationState(api: api, seedDemoData: false)
      ..setRole(UserRole.fromApi(identity['role']));

    await state.loadMonthlyReport(DateTime(2026, 10));

    expect(requests.last.url.queryParameters, {'month': '2026-10'});
    expect(state.monthlyReportSnapshot.payments, hasLength(1));
    expect(state.monthlyReportSnapshot.payments.single.amount, 42000);
    expect(
      state.monthlyReportSnapshot.payments.single.paidThroughEnd,
      DateTime(2026, 10, 31),
    );
    expect(state.monthlyReportSnapshot.payments.single.fieldName, 'Champ test');
    expect(state.monthlyReportSnapshot.validated, isFalse);
    expect(state.monthlyReportValidatedDates, [DateTime(2026, 10, 20)]);
    expect(state.monthlyOvertimeReport.single.hours, 2.5);

    state.setRole(UserRole.fieldManager);
    expect(state.monthlyPaymentReport, isEmpty);
    final requestCount = requests.length;
    await state.loadMonthlyReport(DateTime(2026, 11));
    expect(requests, hasLength(requestCount));

    state.dispose();
    await api.close();
  });

  test(
    'refresh requests only data allowed for the authenticated role',
    () async {
      const roles = {
        'director': 'DIRECTOR',
        'assistant': 'ASSISTANT',
        'terrain': 'FIELD_MANAGER',
      };
      const expectedPaths = {
        'DIRECTOR': {
          '/api/workers',
          '/api/accounts',
          '/api/fields',
          '/api/attendance',
          '/api/attendance/month',
          '/api/payroll/settings',
          '/api/payroll/due',
          '/api/tasks',
          '/api/stock/items',
          '/api/stock/movements',
          '/api/stock/alerts',
          '/api/expenses',
          '/api/payments',
          '/api/reports/daily',
          '/api/payroll/requests',
          '/api/overtime',
          '/api/stock/orders',
          '/api/sales',
          '/api/budgets',
        },
        'ASSISTANT': {
          '/api/workers',
          '/api/attendance',
          '/api/attendance/month',
          '/api/payroll/settings',
          '/api/tasks',
          '/api/stock/items',
          '/api/stock/movements',
          '/api/stock/alerts',
          '/api/expenses',
          '/api/payments',
          '/api/payroll/due',
          '/api/reports/daily',
          '/api/payroll/requests',
          '/api/fields',
          '/api/stock/orders',
          '/api/sales',
          '/api/budgets',
        },
        'FIELD_MANAGER': {
          '/api/workers',
          '/api/attendance',
          '/api/tasks',
          '/api/stock/items',
          '/api/stock/movements',
          '/api/stock/alerts',
          '/api/expenses',
          '/api/overtime',
          '/api/fields',
          '/api/stock/orders',
          '/api/sales',
          '/api/budgets/field',
        },
      };

      for (final entry in roles.entries) {
        final paths = <String>{};
        final api = PlantationApi(
          baseUrl: 'https://inventa.test',
          sessionCredentialStore: _MemorySessionCredentialStore(),
          client: MockClient((request) async {
            if (request.url.path == '/api/auth/me') {
              return http.Response(
                jsonEncode({'role': entry.value}),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            paths.add(request.url.path);
            if (request.url.path == '/api/budgets' ||
                request.url.path == '/api/budgets/field') {
              return http.Response(
                jsonEncode({
                  'fundingLimit': 0,
                  'confirmedExpenses': 0,
                  'pendingExpenses': 0,
                  'remainingAmount': 0,
                  'unallocatedAmount': 0,
                  'fields': [],
                }),
                200,
              );
            }
            if (request.url.path == '/api/payroll/settings') {
              return http.Response(
                jsonEncode({
                  'monthlySalary': 90000,
                  'monthlyRequiredHours': 208,
                }),
                200,
              );
            }
            if (request.url.path == '/api/reports/daily') {
              return http.Response(
                jsonEncode({
                  'attendance': [],
                  'tasks': [],
                  'movements': [],
                  'alerts': [],
                  'expenses': [],
                  'payments': [],
                }),
                200,
              );
            }
            return http.Response('[]', 200);
          }),
        );
        final identity = await api.login(entry.key, 'password');
        final state = PlantationState(api: api, seedDemoData: false)
          ..setRole(UserRole.fromApi(identity['role']));
        await state.refresh();

        expect(paths, expectedPaths[entry.value]);
        await api.close();
        state.dispose();
      }
    },
  );

  test(
    'queues field task updates immediately when the device is offline',
    () async {
      final database = await databaseFactoryMemory.openDatabase(
        'offline-task-${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final offlineStore = OfflineOperationStore(database);
      final api = PlantationApi(
        baseUrl: 'https://inventa.test',
        sessionCredentialStore: _MemorySessionCredentialStore(),
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/me') {
            return http.Response('{"role":"FIELD_MANAGER","fieldId":7}', 200);
          }
          fail('An offline action should not issue an HTTP request.');
        }),
      );
      final identity = await api.login('terrain', 'password');
      final state =
          PlantationState(
              api: api,
              seedDemoData: false,
              offlineStoreFactory: () async => offlineStore,
              networkAvailable: () async => false,
            )
            ..setRole(UserRole.fromApi(identity['role']))
            ..setAssignedFieldId('${identity['fieldId']}')
            ..setAccountId('terrain')
            ..tasks = [
              FieldTask(
                id: '19',
                title: 'Travail saisonnier',
                assigneeIds: const [],
                status: FieldTaskStatus.aFaire,
                type: FieldTaskType.seasonalWorkers,
                createdAt: DateTime(2026),
              ),
            ];
      addTearDown(state.dispose);
      addTearDown(api.close);
      addTearDown(offlineStore.close);

      await state.updateTaskStatus('19', FieldTaskStatus.enCours);

      expect(state.pendingOfflineOperations, 1);
      expect(state.tasks.single.status, FieldTaskStatus.enCours);
      final queued = await offlineStore.queuedOperations('terrain');
      expect(queued.single.body, {'status': 'IN_PROGRESS'});
    },
  );

  test('records a field-scoped harvest sale through the sales API', () async {
    final requests = <http.Request>[];
    final api = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: _MemorySessionCredentialStore(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'role': 'FIELD_MANAGER', 'fieldId': 7}),
            200,
          );
        }
        if (request.url.path == '/api/sales' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 31,
                'product': 'Fèves séchées',
                'quantity': 12.5,
                'totalPrice': 48000,
                'recordedAt': '2026-10-12T08:00:00Z',
                'recordedBy': 'Responsable de champ',
                'fieldId': 7,
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path == '/api/budgets/field') {
          return http.Response(
            '{"fundingLimit":0,"confirmedExpenses":0,"pendingExpenses":0,"remainingAmount":0,"unallocatedAmount":0,"fields":[]}',
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
    final identity = await api.login('terrain', 'password');
    final state =
        PlantationState(
            api: api,
            seedDemoData: false,
            networkAvailable: () async => true,
          )
          ..setRole(UserRole.fromApi(identity['role']))
          ..setAssignedFieldId('${identity['fieldId']}');

    await state.refresh();
    expect(state.sales.single.product, 'Fèves séchées');
    expect(
      await state.addHarvestSale(
        product: 'Cabosses',
        quantity: 4,
        totalPrice: 18000,
      ),
      isTrue,
    );

    final saleRequest = requests.firstWhere(
      (request) => request.method == 'POST' && request.url.path == '/api/sales',
    );
    expect(jsonDecode(saleRequest.body), {
      'product': 'Cabosses',
      'quantity': 4,
      'totalPrice': 18000,
      'fieldId': 7,
    });

    state.dispose();
    await api.close();
  });

  test(
    'persists the shared salary and marks individual salary changes',
    () async {
      final requests = <http.Request>[];
      final api = PlantationApi(
        baseUrl: 'https://inventa.test',
        sessionCredentialStore: _MemorySessionCredentialStore(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/auth/me') {
            return http.Response(
              jsonEncode({'role': 'ASSISTANT'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 200);
        }),
      );
      await api.login('assistant', 'password');
      final state = PlantationState(api: api, seedDemoData: false)
        ..workers = [
          const Worker(
            id: '12',
            name: 'Worker test',
            group: 'Team',
            salary: 90000,
            active: true,
          ),
        ]
        ..setRole(UserRole.assistant);

      await state.updateWorkerSalary('12', 125000);
      final individualSalaryRequest = requests.firstWhere(
        (request) => request.url.path == '/api/workers/12/salary',
      );
      expect(jsonDecode(individualSalaryRequest.body), {
        'salary': 125000,
        'salaryIsIndividual': true,
      });

      state.setRole(UserRole.director);
      await state.savePayrollSettings(salary: 110000, requiredHours: 200);
      expect(jsonDecode(requests.last.body), {
        'monthlySalary': 110000,
        'monthlyRequiredHours': 200,
      });
      expect(state.workers.single.salary, 125000);

      state.dispose();
      await api.close();
    },
  );

  testWidgets('reopening a section reloads data from the server', (
    tester,
  ) async {
    final database = await databaseFactoryMemory.openDatabase(
      'section-refresh-${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final offlineStore = OfflineOperationStore(database);
    addTearDown(offlineStore.close);
    final requests = <String>[];
    final api = PlantationApi(
      baseUrl: 'https://inventa.test',
      sessionCredentialStore: _MemorySessionCredentialStore(),
      client: MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path == '/api/auth/director-registration') {
          return http.Response('{"available":false}', 200);
        }
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'username': 'assistant-api-test',
              'role': 'ASSISTANT',
            }),
            200,
          );
        }
        if (request.url.path == '/api/payroll/settings') {
          return http.Response(
            '{"monthlySalary":90000,"monthlyRequiredHours":208}',
            200,
          );
        }
        if (request.url.path == '/api/budgets' ||
            request.url.path == '/api/budgets/field') {
          return http.Response(
            '{"fundingLimit":0,"confirmedExpenses":0,"pendingExpenses":0,"remainingAmount":0,"unallocatedAmount":0,"fields":[]}',
            200,
          );
        }
        if (request.url.path == '/api/reports/daily') {
          return http.Response(
            jsonEncode({
              'attendance': [],
              'tasks': [],
              'movements': [],
              'alerts': [],
              'expenses': [],
              'payments': [],
              'validated': false,
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
    await tester.pumpWidget(
      InventaApp(
        api: api,
        offlineStoreFactory: () async => offlineStore,
        networkAvailable: () async => true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'assistant');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    final requestsBeforeOpen = requests.length;
    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stocks & achats').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(requests.length, greaterThan(requestsBeforeOpen));
    expect(requests.where((path) => path == '/api/stock/items').length, 2);
    expect(requests.where((path) => path == '/api/stock/orders').length, 2);
  });
}
