import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/features/expenses/expenses_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  testWidgets('budget controls are visible only to director and assistant', (
    tester,
  ) async {
    final state = PlantationState(seedDemoData: false)
      ..budgetSummary = const BudgetSummary(
        fundingLimit: 100000,
        confirmedExpenses: 12500,
        pendingExpenses: 0,
        remainingAmount: 87500,
        unallocatedAmount: 87500,
        fields: [],
      )
      ..expenses = [
        Expense(
          description: 'Achat en attente',
          amount: 12000,
          recordedAt: DateTime.now(),
          recordedBy: 'assistant',
          budgeted: true,
          status: ExpenseStatus.pendingReconciliation,
        ),
      ];
    addTearDown(state.dispose);

    for (final role in [UserRole.director, UserRole.assistant]) {
      state.setRole(role);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ExpensesScreen(state: state)),
          ),
        ),
      );
      expect(find.text('Enveloppe de fonctionnement'), findsOneWidget);
      expect(
        find.text('Modifier'),
        findsNWidgets(role == UserRole.director ? 1 : 0),
      );
      expect(
        find.text('Ajouter des fonds'),
        findsNWidgets(role == UserRole.director ? 1 : 0),
      );
      expect(
        find.text('Attribuer'),
        findsNWidgets(role == UserRole.assistant ? 1 : 0),
      );
      expect(
        find.textContaining('À rapprocher avec le directeur'),
        findsOneWidget,
      );
    }

    state.setRole(UserRole.fieldManager);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ExpensesScreen(state: state)),
        ),
      ),
    );
    expect(find.text('Budget de mon champ'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Ajouter des fonds'), findsNothing);
    expect(find.text('Attribuer'), findsNothing);
    expect(find.text('Achat en attente'), findsOneWidget);
  });
}
