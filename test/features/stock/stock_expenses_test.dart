import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';
import 'package:inventa/src/features/report/field_report_screen.dart';
import 'package:inventa/src/features/stock/stock_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  test('assistant can create a stock item before its first receipt', () async {
    final state = PlantationState(seedDemoData: false);
    state.setRole(UserRole.assistant);

    await state.addStockItem('Engrais', 'sacs');

    expect(state.stockItems, hasLength(1));
    expect(state.stockItems.single.name, 'Engrais');
    expect(state.stockItems.single.quantity, 0);
    state.dispose();
  });

  test(
    'field request is sent by assistant and received by field manager',
    () async {
      final state = PlantationState();
      state.setRole(UserRole.fieldManager);
      final before = state.stockItems.first.quantity;

      expect(
        await state.createStockOrder(
          itemId: 's1',
          quantity: 3,
          description: 'Commande test',
        ),
        isTrue,
      );
      final order = state.stockOrders.single;
      expect(order.status, StockOrderStatus.ordered);
      expect(state.stockItems.first.quantity, before);
      state.setRole(UserRole.assistant);
      expect(
        await state.dispatchStockOrder(orderId: order.id, sentQuantity: 2),
        isTrue,
      );
      expect(state.stockItems.first.quantity, before);
      expect(state.stockOrders.single.status, StockOrderStatus.sent);
      state.setRole(UserRole.fieldManager);
      expect(await state.confirmStockOrderReceived(order.id), isTrue);
      await state.addExpense('Transport', 5000);

      expect(state.stockItems.first.quantity, before + 2);
      expect(state.stockMovements.first.paidAmount, 12000);
      expect(state.stockOrders.single.status, StockOrderStatus.received);
      expect(state.stockOrders.single.receivedQuantity, 2);
      expect(state.expenses.first.amount, 5000);
      state.dispose();
    },
  );

  testWidgets(
    'field manager requests material, assistant sends it, manager confirms',
    (tester) async {
      await tester.pumpWidget(const InventaApp(demoMode: true));
      await tester.tap(find.byTooltip('Toutes les rubriques'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks & achats').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Demander du matériel'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '6');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Besoin pour la parcelle',
      );
      await tester.tap(find.text('Envoyer la demande à l’assistant'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Changer de profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assistant achats').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Toutes les rubriques'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks & achats').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('En attente de préparation'), findsOneWidget);
      await tester.ensureVisible(
        find.byTooltip('Modifier le prix unitaire').first,
      );
      await tester.tap(find.byTooltip('Modifier le prix unitaire').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2500');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Préparer l’envoi'));
      await tester.tap(find.text('Préparer l’envoi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '6');
      await tester.tap(find.text('Envoyer au responsable'));
      await tester.pumpAndSettle();

      expect(find.textContaining('à confirmer à la réception'), findsOneWidget);
      await tester.tap(find.byTooltip('Changer de profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Responsable de champ').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Toutes les rubriques'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks & achats').last);
      await tester.pumpAndSettle();
      final receiptCheck = find.byType(Checkbox).first;
      await tester.ensureVisible(receiptCheck);
      await tester.tap(receiptCheck);
      await tester.pumpAndSettle();
      expect(find.textContaining('Reçu le'), findsOneWidget);
      expect(find.textContaining('total 15 000 F'), findsOneWidget);
    },
  );

  test('assistant can see stock usage recorded by the field manager', () async {
    final state = PlantationState(seedDemoData: false);
    state.stockItems = [
      const StockItem(id: 's1', name: 'Engrais', unit: 'sacs', quantity: 5),
    ];
    state.setRole(UserRole.fieldManager);
    expect(
      await state.addStockMovement(
        itemId: 's1',
        kind: StockMovementKind.usage,
        quantity: 2,
        description: 'Utilisé au champ',
      ),
      isTrue,
    );
    state.setRole(UserRole.assistant);
    expect(
      state.stockMovementsForSelectedField.any(
        (movement) => movement.description == 'Utilisé au champ',
      ),
      isTrue,
    );
    state.dispose();
  });

  test('dashboard expense total includes only expenses from today', () {
    final state = PlantationState(seedDemoData: false);
    final today = DateTime.now();
    state.expenses = [
      Expense(
        description: 'Aujourd’hui',
        amount: 1000,
        recordedAt: today,
        recordedBy: 'assistant',
      ),
      Expense(
        description: 'Hier',
        amount: 2000,
        recordedAt: today.subtract(const Duration(days: 1)),
        recordedBy: 'assistant',
      ),
    ];

    expect(state.dailyExpenseTotal, 1000);
    expect(state.expenseTotal, 3000);
    state.dispose();
  });

  testWidgets('field manager records stock use and a daily expense', (
    tester,
  ) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));

    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stocks & achats').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mouvement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déclarer une utilisation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Travaux du matin',
    );
    await tester.tap(find.text('Enregistrer le mouvement'));
    await tester.pumpAndSettle();
    expect(find.text('Travaux du matin'), findsOneWidget);

    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dépenses').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Transport local');
    await tester.enterText(find.byType(TextFormField).at(1), '2500');
    await tester.tap(find.text('Enregistrer la dépense'));
    await tester.pumpAndSettle();

    expect(find.text('Transport local'), findsOneWidget);
    expect(find.text('2 500 F'), findsOneWidget);
  });

  testWidgets('field manager reports a sale included in the assistant report', (
    tester,
  ) async {
    final state = PlantationState()..setRole(UserRole.fieldManager);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StockScreen(state: state)),
        ),
      ),
    );
    await tester.tap(find.text('Signaler une vente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Fèves séchées');
    await tester.enterText(find.byType(TextFormField).at(1), '12.5');
    await tester.enterText(find.byType(TextFormField).at(2), '48000');
    await tester.tap(find.text('Enregistrer la vente'));
    await tester.pumpAndSettle();

    expect(state.sales.single.product, 'Fèves séchées');
    expect(state.sales.single.quantity, 12.5);
    expect(state.sales.single.totalPrice, 48000);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StockScreen(state: state)),
        ),
      ),
    );
    expect(find.text('Fèves séchées'), findsOneWidget);

    state.setRole(UserRole.assistant);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: FieldReportScreen(state: state)),
        ),
      ),
    );
    expect(find.textContaining('VENTES DE PRODUITS RÉCOLTÉS'), findsOneWidget);
    expect(find.textContaining('12,50 vendus'), findsOneWidget);
    expect(find.textContaining('prix total 48 000 F'), findsOneWidget);
  });
}
