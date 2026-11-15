import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/app_state.dart';
import 'package:kitabiyahe/core/finance.dart';
import 'package:kitabiyahe/core/repository.dart';
import 'package:kitabiyahe/main.dart';
import 'package:kitabiyahe/ui/quickcheck.dart';
import 'package:kitabiyahe/ui/theme.dart';
import 'package:kitabiyahe/ui/widgets.dart';

class MemoryRepository extends DataRepository {
  AppData? saved;
  @override
  Future<void> save(AppData state) async {
    saved = state;
  }
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('QuickCheck fits 320 logical pixels with ${scale}x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = RiderAppState(MemoryRepository(), const AppData());
      await tester.pumpWidget(
        MaterialApp(
          theme: kitaTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: HomeShell(state: state),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final efficiency in <double?>[null, 38.123456789]) {
    testWidgets(
      'editing a note preserves historical assumptions ($efficiency)',
      (tester) async {
        final repo = MemoryRepository();
        final time = DateTime(2026, 11, 1);
        final original = ShiftInput(
          quickEarningsCents: 120000,
          distanceKm: 100,
          fuelMethod: FuelMethod.distance,
          efficiencyKmL: efficiency,
          otherCostCents: 8000,
          hours: 8.5,
          targetCents: 90000,
        );
        final record = ShiftRecord(
          id: 'test-shift',
          workDate: time,
          createdAt: time,
          updatedAt: time,
          input: original,
        );
        final state = RiderAppState(
          repo,
          AppData(
            settings: const RiderSettings(
              fuelUnit: FuelUnit.mpgUs,
              efficiencyKmL: 40,
              fuelPriceCents: 6500,
              reservePerKmCents: 100,
            ),
            records: [record],
          ),
        );
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
        final notes = find.widgetWithText(TextField, 'Optional notes');
        await tester.ensureVisible(notes);
        await tester.enterText(notes, 'Test note');
        final button = find.text('Update this shift').first;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(repo.saved!.records.single.input.toJson(), {
          ...original.toJson(),
          'notes': 'Test note',
        });
      },
    );
  }
  testWidgets(
    'the earnings input has an accessible name and Tab can reach Save',
    (tester) async {
      final repo = MemoryRepository();
      final state = RiderAppState(repo, const AppData());
      await tester.pumpWidget(
        MaterialApp(
          theme: kitaTheme(),
          home: Scaffold(
            body: QuickCheckPage(state: state, onFinished: () {}),
          ),
        ),
      );
      final field = find.descendant(
        of: find.byType(TextEntry).first,
        matching: find.byType(TextField),
      );
      expect(
        tester.getSemantics(field).label,
        contains('Earnings AFTER platform fees'),
      );
      await tester.enterText(field, '200');
      final button = find.widgetWithText(
        OutlinedButton,
        'Save this shift (even if incomplete)',
      );
      final control = tester.element(button);
      bool saveFocused() {
        final focus = FocusManager.instance.primaryFocus?.context;
        if (focus == null) return false;
        bool found = focus == control;
        focus.visitAncestorElements((node) {
          if (node == control) found = true;
          return !found;
        });
        return found;
      }

      for (var i = 0; i < 30 && !saveFocused(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(saveFocused(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(repo.saved!.records.single.input.quickEarningsCents, 20000);
    },
  );
}
