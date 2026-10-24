import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';
import 'package:inventa/src/data/plantation_api.dart';
import 'package:inventa/src/features/attendance/attendance_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  testWidgets('field manager can mark a worker absent', (tester) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.text('Faire le pointage'));
    await tester.pumpAndSettle();

    final worker = find.text('Koffi Yao');
    await tester.ensureVisible(worker);
    final markMenu = find.byTooltip('Autres actions pour Koffi Yao');
    await tester.ensureVisible(markMenu);
    await tester.tap(markMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer absent'));
    await tester.pumpAndSettle();

    expect(find.text('Absent'), findsWidgets);
  });

  testWidgets('field manager records arrival and departure times', (
    tester,
  ) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.text('Faire le pointage'));
    await tester.pumpAndSettle();

    final arrival = find.byTooltip('Enregistrer l’arrivée de Adjoua Brou');
    await tester.ensureVisible(arrival);
    await tester.tap(arrival);
    await tester.pumpAndSettle();
    expect(find.textContaining('Arrivée '), findsWidgets);

    final departure = find.byTooltip('Enregistrer le départ de Adjoua Brou');
    await tester.tap(departure);
    await tester.pumpAndSettle();
    expect(find.textContaining('Départ '), findsOneWidget);
  });

  testWidgets('past attendance is read-only for the field manager', (
    tester,
  ) async {
    final state = PlantationState()
      ..setRole(UserRole.fieldManager)
      ..selectedDate = DateTime.now().subtract(const Duration(days: 1));
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AttendanceScreen(state: state)),
      ),
    );

    expect(
      find.textContaining('Les pointages sont consultables'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Enregistrer l’arrivée de Adjoua Brou'),
      findsNothing,
    );
    expect(find.byTooltip('Autres actions pour Adjoua Brou'), findsNothing);
    await expectLater(
      state.markAttendance('w1', AttendanceStatus.absent),
      throwsA(isA<ApiException>()),
    );
  });
}
