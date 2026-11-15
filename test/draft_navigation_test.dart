import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/app_state.dart';
import 'package:kitabiyahe/core/finance.dart';
import 'package:kitabiyahe/core/repository.dart';
import 'package:kitabiyahe/main.dart';
import 'package:kitabiyahe/ui/quickcheck.dart';
import 'package:kitabiyahe/ui/theme.dart';

class DraftRepository extends DataRepository {
  AppData? saved;
  @override
  Future<void> save(AppData state) async => saved = state;
}

class FailingDraftRepository extends DataRepository {
  @override
  Future<void> save(AppData state) async =>
      throw StateError('Fictional storage failure');
}

class DelayedDraftRepository extends DataRepository {
  final completion = Completer<void>();
  @override
  Future<void> save(AppData state) => completion.future;
}

void main() {
  Future<void> openHome(WidgetTester tester, RiderAppState state) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kitaTheme(),
        home: HomeShell(state: state),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('background shift save preserves the active Settings draft', (
    tester,
  ) async {
    final repository = DelayedDraftRepository();
    final state = RiderAppState(repository, const AppData());
    await openHome(tester, state);
    final earnings = find.byType(TextField).first;
    await tester.ensureVisible(earnings);
    await tester.enterText(earnings, '500');
    final save = find.text('Save this shift (even if incomplete)');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final efficiency = find.byType(TextField).first;
    await tester.ensureVisible(efficiency);
    await tester.enterText(efficiency, '42');
    repository.completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('Motorcycle & settings'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '42',
    );
    expect(state.records.single.input.quickEarningsCents, 50000);
    await tester.tap(find.text('QuickCheck').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });

  testWidgets(
    'unsaved earnings survive switching tabs and starting a new shift can be cancelled',
    (tester) async {
      await openHome(tester, RiderAppState(DraftRepository(), const AppData()));
      final earnings = find.byType(TextField).first;
      await tester.ensureVisible(earnings);
      await tester.enterText(earnings, '432.10');
      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('QuickCheck').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '432.10',
      );
      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      final newShift = find.text('New shift');
      await tester.ensureVisible(newShift);
      await tester.tap(newShift);
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved entries?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QuickCheck').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '432.10',
      );
    },
  );

  testWidgets(
    'sample replacement protects an existing draft until explicitly discarded',
    (tester) async {
      await openHome(tester, RiderAppState(DraftRepository(), const AppData()));
      final earnings = find.byType(TextField).first;
      await tester.ensureVisible(earnings);
      await tester.enterText(earnings, '432.10');
      final sample = find.byTooltip('Try example figures');
      await tester.ensureVisible(sample);
      await tester.tap(sample);
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved entries?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '432.10',
      );
      await tester.ensureVisible(sample);
      await tester.tap(sample);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '1200.00',
      );
    },
  );

  testWidgets(
    'unfinished controls are hidden and historical values survive a financial edit',
    (tester) async {
      final repo = DraftRepository();
      final time = DateTime(2026, 11, 14);
      final record = ShiftRecord(
        id: 'historical',
        workDate: time,
        createdAt: time,
        updatedAt: time,
        input: const ShiftInput(
          quickEarningsCents: 120000,
          hours: 8.5,
          targetCents: 90000,
        ),
      );
      final state = RiderAppState(repo, AppData(records: [record]));
      await tester.pumpWidget(
        MaterialApp(
          theme: kitaTheme(),
          home: Scaffold(
            body: QuickCheckPage(
              state: state,
              editing: record,
              onFinished: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1300');
      final costs = find.textContaining('GASOLINE & COSTS');
      await tester.ensureVisible(costs);
      await tester.tap(costs);
      await tester.pumpAndSettle();
      expect(find.text('Optional hours worked'), findsNothing);
      expect(find.text('Optional personal target'), findsNothing);
      final save = find.text('Update this shift').first;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final saved = repo.saved!.records.single.input;
      expect(saved.quickEarningsCents, 130000);
      expect(saved.hours, 8.5);
      expect(saved.targetCents, 90000);
    },
  );

  testWidgets(
    'a retained draft keeps its displayed efficiency unit when defaults change',
    (tester) async {
      final state = RiderAppState(DraftRepository(), const AppData());
      await openHome(tester, state);
      await tester.tap(find.byTooltip('Try example figures'));
      await tester.pumpAndSettle();
      await state.saveSettings(const RiderSettings(fuelUnit: FuelUnit.mpgUs));
      await tester.pumpAndSettle();
      expect(find.text('km/L'), findsWidgets);
      expect(find.text('MPG (US)'), findsNothing);
    },
  );

  testWidgets('returning to an untouched new form picks up saved defaults', (
    tester,
  ) async {
    final state = RiderAppState(DraftRepository(), const AppData());
    await openHome(tester, state);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await state.saveSettings(const RiderSettings(fuelPriceCents: 7200));
    await tester.tap(find.text('QuickCheck').last);
    await tester.pumpAndSettle();
    final form = tester.state<QuickCheckPageState>(find.byType(QuickCheckPage));
    expect(form.readInput().fuelPriceCents, 7200);
  });

  testWidgets(
    'a failed save leaves the draft available and does not add a record',
    (tester) async {
      final state = RiderAppState(FailingDraftRepository(), const AppData());
      await openHome(tester, state);
      final earnings = find.byType(TextField).first;
      await tester.ensureVisible(earnings);
      await tester.enterText(earnings, '200');
      final save = find.text('Save this shift (even if incomplete)');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save:'), findsOneWidget);
      expect(state.records, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '200',
      );
      final sample = find.byTooltip('Try example figures');
      await tester.ensureVisible(sample);
      await tester.tap(sample);
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved entries?'), findsOneWidget);
    },
  );

  testWidgets(
    'Android Back returns from History then protects a dirty QuickCheck draft',
    (tester) async {
      await openHome(tester, RiderAppState(DraftRepository(), const AppData()));
      final earnings = find.byType(TextField).first;
      await tester.ensureVisible(earnings);
      await tester.enterText(earnings, '200');
      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Shift history'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved entries?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '200',
      );
    },
  );
}
