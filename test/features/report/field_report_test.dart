import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/features/report/field_report_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  testWidgets('director and assistant can open the full monthly report', (
    tester,
  ) async {
    final state = PlantationState(seedDemoData: false)
      ..setRole(UserRole.assistant)
      ..workers = [
        const Worker(
          id: '8',
          name: 'Ouvrier test',
          group: 'Équipe',
          salary: 80000,
          active: true,
          fieldId: '3',
          fieldName: 'Champ test',
        ),
      ]
      ..payments = [
        Payment(
          workerId: '8',
          amount: 42000,
          recordedAt: DateTime.now(),
          recordedBy: 'assistant',
          fieldId: '3',
          fieldName: 'Champ test',
          paidThroughEnd: DateTime(
            DateTime.now().year,
            DateTime.now().month + 1,
            0,
          ),
        ),
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FieldReportScreen(state: state)),
      ),
    );

    expect(find.text('Consulter les rapports du mois'), findsOneWidget);
    await tester.tap(find.text('Consulter les rapports du mois'));
    await tester.pumpAndSettle();

    expect(find.text('Récapitulatif mensuel des rapports'), findsOneWidget);
    expect(find.textContaining('Présences :'), findsOneWidget);
    expect(find.textContaining('Tâches :'), findsOneWidget);
    expect(find.textContaining('Paiements :'), findsOneWidget);
    final reportList = find.byType(ListView).last;
    final reportScrollable = find
        .descendant(of: reportList, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('Ouvrier test'),
      250,
      scrollable: reportScrollable,
    );
    expect(find.text('Ouvrier test'), findsOneWidget);
    expect(find.text('Champ test'), findsOneWidget);
    expect(find.text('Enregistré par'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Heures supplémentaires'),
      250,
      scrollable: reportScrollable,
    );
    expect(find.text('Heures supplémentaires'), findsOneWidget);
  });

  testWidgets('field manager cannot access the monthly report', (tester) async {
    final state = PlantationState(seedDemoData: false)
      ..setRole(UserRole.fieldManager);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FieldReportScreen(state: state)),
      ),
    );

    expect(find.text('Consulter les rapports du mois'), findsNothing);
  });
}
