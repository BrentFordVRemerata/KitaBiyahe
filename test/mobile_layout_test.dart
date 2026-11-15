import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/app_state.dart';
import 'package:kitabiyahe/core/finance.dart';
import 'package:kitabiyahe/core/repository.dart';
import 'package:kitabiyahe/main.dart';
import 'package:kitabiyahe/ui/quickcheck.dart';
import 'package:kitabiyahe/ui/theme.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Settings fits 320 logical pixels with ${scale}x text and long values',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = RiderAppState(
          DataRepository(),
          const AppData(
            settings: RiderSettings(
              efficiencySource: EfficiencySource.manufacturer,
            ),
          ),
        );
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
        await tester.tap(find.text('Settings').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('itemized amounts fit 320 logical pixels with ${scale}x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final time = DateTime(2026, 11, 14);
      final record = ShiftRecord(
        id: 'layout-fixture',
        workDate: time,
        createdAt: time,
        updatedAt: time,
        input: const ShiftInput(
          earningsMode: EarningsMode.itemized,
          items: [
            IncomeItem(
              id: 'item1',
              source: 'Direct / cash booking',
              kind: IncomeKind.jobs,
              amountCents: 999999900,
              reference: 'FICTIONAL-LAYOUT-REFERENCE',
            ),
          ],
        ),
      );
      final state = RiderAppState(DataRepository(), AppData(records: [record]));
      await tester.pumpWidget(
        MaterialApp(
          theme: kitaTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
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
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'add-entry sheet fits 320 logical pixels with ${scale}x text and keyboard',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final state = RiderAppState(DataRepository(), const AppData());
        await tester.pumpWidget(
          MaterialApp(
            theme: kitaTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: QuickCheckPage(state: state, onFinished: () {}),
            ),
          ),
        );
        final mode = find.text('One by one');
        await tester.ensureVisible(mode);
        await tester.tap(mode);
        await tester.pumpAndSettle();
        final add = find.text('Add entry');
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'History and guide fit 320 logical pixels with ${scale}x text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final time = DateTime(2026, 11, 14);
        final record = ShiftRecord(
          id: 'history-layout',
          workDate: time,
          createdAt: time,
          updatedAt: time,
          input: const ShiftInput(
            quickEarningsCents: 999999900,
            fuelMethod: FuelMethod.manual,
            manualFuelCents: 0,
            otherCostCents: 0,
            distanceKm: 0,
            reservePerKmCents: 0,
          ),
        );
        final state = RiderAppState(
          DataRepository(),
          AppData(
            records: [record],
            settings: const RiderSettings(reduceMotion: true),
          ),
        );
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
        await tester.tap(find.text('History').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('How it works'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var step = 0; step < 3; step++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.text('Start QuickCheck'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
