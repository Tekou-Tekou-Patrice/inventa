import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/features/expenses/expenses_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  testWidgets('director budget card stays readable on a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = PlantationState()..setRole(UserRole.director);
    addTearDown(state.dispose);
    state.budgetSummary = const BudgetSummary(
      fundingLimit: 100000,
      confirmedExpenses: 0,
      pendingExpenses: 0,
      remainingAmount: 100000,
      unallocatedAmount: 100000,
      fields: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (context, _) =>
                SingleChildScrollView(child: ExpensesScreen(state: state)),
          ),
        ),
      ),
    );

    final title = find.text('Enveloppe de fonctionnement');
    expect(title, findsOneWidget);
    expect(tester.getSize(title).width, greaterThan(180));

    await tester.tap(find.text('Ajouter des fonds'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '25000');
    await tester.tap(find.text('Ajouter').last);
    await tester.pumpAndSettle();

    expect(find.text('Ajouter des fonds à l’enveloppe'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
