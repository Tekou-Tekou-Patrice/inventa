import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';
import 'package:inventa/src/features/tasks/tasks_screen.dart';
import 'package:inventa/src/features/workers/workers_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  testWidgets('field manager searches workers in the assigned field', (
    tester,
  ) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Koffi');
    await tester.pumpAndSettle();

    expect(find.text('Koffi Yao'), findsOneWidget);
    expect(find.text('Ama Kouassi'), findsNothing);
  });

  testWidgets('field manager can create and assign a task', (tester) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tâches').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle tâche'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Nettoyage parcelle est',
    );
    await tester.tap(find.text('Koffi Yao'));
    await tester.tap(find.text('Adjoua Brou'));
    await tester.tap(find.text('Créer la tâche'));
    await tester.pumpAndSettle();

    expect(find.text('Nettoyage parcelle est'), findsOneWidget);
    expect(find.text('Koffi Yao, Adjoua Brou'), findsWidgets);

    final taskStatus = find.byTooltip(
      'Modifier le statut de Désherbage parcelle nord',
    );
    await tester.ensureVisible(taskStatus);
    await tester.tap(taskStatus);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminée').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Coût réel (F CFA)'),
      '125000',
    );
    expect(
      find.widgetWithText(TextFormField, 'Nombre d’ouvriers saisonniers'),
      findsNothing,
    );
    await tester.tap(find.text('Enregistrer et terminer'));
    await tester.pumpAndSettle();
    expect(find.text('Terminée'), findsOneWidget);
  });

  testWidgets('field manager creates and closes a seasonal task', (
    tester,
  ) async {
    final state = PlantationState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (context, _) =>
                SingleChildScrollView(child: TasksScreen(state: state)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Nouvelle tâche'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Récolte avec équipe saisonnière',
    );
    await tester.tap(find.text('Saisonniers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer la tâche'));
    await tester.pumpAndSettle();

    expect(find.text('Équipe saisonnière'), findsOneWidget);
    final taskStatus = find.byTooltip(
      'Modifier le statut de Récolte avec équipe saisonnière',
    );
    await tester.ensureVisible(taskStatus);
    await tester.tap(taskStatus);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminée').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '80000');
    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await tester.tap(find.text('Enregistrer et terminer'));
    await tester.pumpAndSettle();

    final task = state.tasks.firstWhere(
      (value) => value.title == 'Récolte avec équipe saisonnière',
    );
    expect(task.type, FieldTaskType.seasonalWorkers);
    expect(task.assigneeIds, isEmpty);
    expect(task.actualCost, 80000);
    expect(task.seasonalWorkerCount, 5);
  });

  testWidgets('director sees the completed task tracking table', (
    tester,
  ) async {
    final state = PlantationState()..setRole(UserRole.director);
    addTearDown(state.dispose);
    state.tasks = [
      FieldTask(
        id: 'report-task',
        title: 'Récolte du champ est',
        assigneeIds: const ['w1', 'w2'],
        status: FieldTaskStatus.termine,
        createdAt: DateTime(2026, 3, 2, 8),
        completedAt: DateTime(2026, 3, 4, 10),
        actualCost: 125000,
        seasonalWorkerCount: 0,
        fieldName: 'Champ Est',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (context, _) => TasksScreen(state: state),
          ),
        ),
      ),
    );

    expect(find.text('Suivi des tâches par champ'), findsOneWidget);
    expect(find.text('Champ Est'), findsOneWidget);
    expect(find.text('Récolte du champ est'), findsOneWidget);
    expect(find.text('2 j 2 h'), findsOneWidget);
    expect(find.text('125 000 F'), findsNWidgets(2));
    expect(find.text('Saisonniers'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('field manager adds a worker with a phone number', (
    tester,
  ) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mariam Traoré');
    await tester.enterText(find.byType(TextFormField).at(1), 'Parcelle Est');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '+225 07 00 00 00',
    );
    await tester.tap(find.text('Ajouter à l’équipe'));
    await tester.pumpAndSettle();
    expect(find.text('Mariam Traoré'), findsOneWidget);

    expect(find.text('+225 07 00 00 00'), findsOneWidget);
    expect(find.text('90 000 F / mois'), findsWidgets);

    final deactivate = find.byTooltip('Désactiver Mariam Traoré');
    await tester.ensureVisible(deactivate);
    await tester.tap(deactivate);
    await tester.pumpAndSettle();
    expect(
      find.text('Parcelle Est · Champ de Yaoundé · Inactif'),
      findsOneWidget,
    );
    expect(find.text('2 actifs · 3 au total'), findsOneWidget);

    final reactivate = find.byTooltip('Réactiver Mariam Traoré');
    await tester.ensureVisible(reactivate);
    await tester.tap(reactivate);
    await tester.pumpAndSettle();
    expect(
      find.text('Parcelle Est · Champ de Yaoundé · Actif'),
      findsOneWidget,
    );
    expect(find.text('3 actifs · 3 au total'), findsOneWidget);
  });

  testWidgets('assistant edits worker phone and archives the worker profile', (
    tester,
  ) async {
    final state = PlantationState()..setRole(UserRole.assistant);
    addTearDown(state.dispose);
    final worker = state.workers.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => WorkersScreen(state: state),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Téléphone non renseigné'), findsWidgets);
    final editPhone = find.byTooltip('Modifier le téléphone de ${worker.name}');
    await tester.ensureVisible(editPhone);
    await tester.tap(editPhone);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '+225 01 02 03 04');
    await tester.tap(find.text('Enregistrer le téléphone'));
    await tester.pumpAndSettle();
    expect(find.text('+225 01 02 03 04'), findsOneWidget);

    final archive = find.byTooltip('Supprimer la fiche de ${worker.name}');
    await tester.ensureVisible(archive);
    await tester.tap(archive);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archiver'));
    await tester.pumpAndSettle();
    expect(
      state.workers.firstWhere((value) => value.id == worker.id).active,
      isFalse,
    );
  });

  testWidgets('assistant can set an individual worker base salary', (
    tester,
  ) async {
    final state = PlantationState()..setRole(UserRole.assistant);
    addTearDown(state.dispose);
    final worker = state.workers.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => WorkersScreen(state: state),
            ),
          ),
        ),
      ),
    );

    final editSalary = find.byTooltip(
      'Modifier le salaire de base de ${worker.name}',
    );
    await tester.ensureVisible(editSalary);
    await tester.tap(editSalary);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '120000');
    await tester.tap(find.text('Enregistrer le salaire de base'));
    await tester.pumpAndSettle();
    expect(
      state.workers.firstWhere((value) => value.id == worker.id).salary,
      120000,
    );
    expect(
      find.textContaining(
        'Salaire individuel : 120 000 F / mois · Taux : 576,92 F / h',
      ),
      findsOneWidget,
    );
  });
}
