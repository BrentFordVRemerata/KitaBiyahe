import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/finance.dart';

void main() {
  group('financial integrity regressions', () {
    test('accepts valid grouping and rejects malformed grouped pesos', () {
      expect(Peso.parse('1,234,567.89'), 123456789);
      expect(Peso.parse('1234567.89'), 123456789);
      for (final value in [
        '1,2',
        '12,34',
        '1,,000',
        ',100',
        '100,',
        '1,0000',
      ]) {
        expect(() => Peso.parse(value), throwsFormatException, reason: value);
      }
    });

    test('duplicate item IDs are rejected even when references are empty', () {
      const input = ShiftInput(
        earningsMode: EarningsMode.itemized,
        items: [
          IncomeItem(
            id: 'same',
            source: 'Grab',
            kind: IncomeKind.jobs,
            amountCents: 100,
          ),
          IncomeItem(
            id: 'same',
            source: 'Grab',
            kind: IncomeKind.tip,
            amountCents: 200,
          ),
        ],
      );
      expect(FinancialEngine.evaluate(input).status, EstimateStatus.invalid);
    });

    test('itemized totals cannot wrap native integers', () {
      const input = ShiftInput(
        earningsMode: EarningsMode.itemized,
        items: [
          IncomeItem(
            id: 'first',
            source: 'Grab',
            kind: IncomeKind.jobs,
            amountCents: 0x7fffffffffffffff,
          ),
          IncomeItem(
            id: 'second',
            source: 'Grab',
            kind: IncomeKind.jobs,
            amountCents: 0x7fffffffffffffff,
          ),
        ],
      );
      expect(input.earningsCents, 1000000001);
      expect(FinancialEngine.evaluate(input).status, EstimateStatus.invalid);
    });

    test(
      'native JSON requires integral centavo fields and correctly typed fields',
      () {
        expect(
          () => ShiftInput.fromJson({'quickEarningsCents': 1.5}),
          throwsFormatException,
        );
        expect(
          () => ShiftInput.fromJson({'quickEarningsCents': '100'}),
          throwsFormatException,
        );
        expect(
          () => ShiftInput.fromJson({'distanceKm': '10'}),
          throwsFormatException,
        );
        expect(
          () => ShiftInput.fromJson({
            'items': [
              {'id': 1, 'source': 'Grab', 'kind': 'jobs', 'amountCents': 100},
            ],
          }),
          throwsFormatException,
        );
        expect(
          () => RiderSettings.fromJson({'fuelPriceCents': 1.25}),
          throwsFormatException,
        );
        expect(
          () => RiderSettings.fromJson({'reduceMotion': 'false'}),
          throwsFormatException,
        );
        for (final efficiency in [0, -1, 1001]) {
          expect(
            () => RiderSettings.fromJson({'efficiencyKmL': efficiency}),
            throwsFormatException,
          );
        }
        for (final cents in [-1, 1000000001]) {
          expect(
            () => RiderSettings.fromJson({'fuelPriceCents': cents}),
            throwsFormatException,
          );
          expect(
            () => RiderSettings.fromJson({'reservePerKmCents': cents}),
            throwsFormatException,
          );
        }
        expect(
          () => IncomeItem.fromJson({
            'id': 'a',
            'source': 'Grab',
            'kind': 'jobs',
            'amountCents': 100.2,
          }),
          throwsFormatException,
        );
      },
    );

    test(
      'distance fuel and reserve results outside supported range are invalid',
      () {
        final fuelOverflow = FinancialEngine.evaluate(
          const ShiftInput(
            quickEarningsCents: 10000,
            fuelMethod: FuelMethod.distance,
            distanceKm: 5000,
            efficiencyKmL: 0.001,
            fuelPriceCents: 1000000000,
            otherCostCents: 0,
            reservePerKmCents: 0,
          ),
        );
        expect(fuelOverflow.status, EstimateStatus.invalid);

        final reserveOverflow = FinancialEngine.evaluate(
          const ShiftInput(
            quickEarningsCents: 10000,
            fuelMethod: FuelMethod.manual,
            manualFuelCents: 0,
            distanceKm: 5000,
            otherCostCents: 0,
            reservePerKmCents: 1000000000,
          ),
        );
        expect(reserveOverflow.status, EstimateStatus.invalid);
      },
    );
  });
}
