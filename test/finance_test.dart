import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/finance.dart';

void main() {
  group('Peso amounts', () {
    test('reads centavos exactly and distinguishes empty from explicit zero', () {
      expect(Peso.parse('1,200.50'), 120050);
      expect(Peso.parse('0'), 0);
      expect(Peso.parse(''), isNull);
      expect(Peso.compact(-85750), '−₱857.50');
      expect(Peso.editable(75), '0.75');
    });
    test('never silently rounds money over two decimals', () {
      expect(() => Peso.parse('1.239'), throwsFormatException);
      expect(() => Peso.parse('-50'), throwsFormatException);
      expect(Peso.parse('-50.25', allowNegative: true), -5025);
      expect(() => Peso.parse('oops'), throwsFormatException);
    });
  });

  group('Fuel conversions', () {
    test('km/L converts to US vs UK MPG, L/100 km correctly', () {
      expect(FuelMath.fromKmPerLiter(40, FuelUnit.mpgUs), closeTo(94.0858, .001));
      expect(FuelMath.fromKmPerLiter(40, FuelUnit.mpgUk), closeTo(112.9924, .001));
      expect(FuelMath.fromKmPerLiter(40, FuelUnit.litersPer100Km), 2.5);
      for (final unit in FuelUnit.values) {
        final display = FuelMath.fromKmPerLiter(40, unit);
        expect(FuelMath.kmPerLiter(display, unit), closeTo(40, .0001));
      }
    });
    test('full-to-full fuel economy requires increasing odometer readings', () {
      expect(FuelMath.fromTwoFullRefills(firstOdometer: 12500,
        secondOdometer: 12760, secondRefillLiters: 6.5), 40);
      expect(() => FuelMath.fromTwoFullRefills(firstOdometer: 12760,
        secondOdometer: 12500, secondRefillLiters: 6.5), throwsFormatException);
      expect(() => FuelMath.fromTwoFullRefills(firstOdometer: 12500,
        secondOdometer: 12760, secondRefillLiters: 0), throwsFormatException);
    });
  });

  group('Rider estimates', () {
    test('approved ₱1,200 sample yields fuel ₱162.50 and remainder ₱857.50', () {
      const input = ShiftInput(quickEarningsCents: 120000,
        fuelMethod: FuelMethod.distance, distanceKm: 100,
        efficiencyKmL: 40, fuelPriceCents: 6500,
        otherCostCents: 8000, reservePerKmCents: 100);
      final result = FinancialEngine.evaluate(input);
      expect(result.status, EstimateStatus.supported);
      expect(result.fuelCents, 16250);
      expect(result.cashRemainderCents, 95750);
      expect(result.reserveCents, 10000);
      expect(result.afterReserveCents, 85750);
    });
    test('cash remainder and planned allowance stay separate', () {
      const input = ShiftInput(quickEarningsCents: 30000,
        fuelMethod: FuelMethod.manual, manualFuelCents: 5000,
        otherCostCents: 0, reservePerKmCents: 0);
      final result = FinancialEngine.evaluate(input);
      expect(result.cashRemainderCents, 25000);
      expect(result.afterReserveCents, 25000);
    });
    test('unknown fuel never produces a supported estimate', () {
      const input = ShiftInput(quickEarningsCents: 120000,
        fuelMethod: FuelMethod.unknown, otherCostCents: 0,
        reservePerKmCents: 0);
      final result = FinancialEngine.evaluate(input);
      expect(result.status, EstimateStatus.partial);
      expect(result.afterReserveCents, isNull);
      expect(result.fuelCents, isNull);
    });
    test('unknown other costs differ from explicit zero', () {
      const absent = ShiftInput(quickEarningsCents: 10000,
        fuelMethod: FuelMethod.manual, manualFuelCents: 2000,
        reservePerKmCents: 0);
      expect(FinancialEngine.evaluate(absent).cashRemainderCents, isNull);
      const explicitNone = ShiftInput(quickEarningsCents: 10000,
        fuelMethod: FuelMethod.manual, manualFuelCents: 2000,
        otherCostCents: 0, reservePerKmCents: 0);
      expect(FinancialEngine.evaluate(explicitNone).cashRemainderCents, 8000);
    });
    test('negative remainder is shown when work costs exceed earnings', () {
      const input = ShiftInput(quickEarningsCents: 0,
        fuelMethod: FuelMethod.manual, manualFuelCents: 5000,
        otherCostCents: 0, reservePerKmCents: 0);
      expect(FinancialEngine.evaluate(input).afterReserveCents, -5000);
    });
    test('itemized earnings replace rather than add to quick total', () {
      const input = ShiftInput(earningsMode: EarningsMode.itemized,
        quickEarningsCents: 999000,
        items: [
          IncomeItem(id: '1', source: 'Grab', kind: IncomeKind.jobs, amountCents: 80000),
          IncomeItem(id: '2', source: 'MOVE IT', kind: IncomeKind.jobs, amountCents: 30000),
          IncomeItem(id: '3', source: 'Grab', kind: IncomeKind.bonus, amountCents: 7000),
          IncomeItem(id: '4', source: 'Grab', kind: IncomeKind.tip, amountCents: 3000),
        ], fuelMethod: FuelMethod.manual, manualFuelCents: 0,
        otherCostCents: 0, reservePerKmCents: 0);
      expect(input.earningsCents, 120000);
      expect(FinancialEngine.evaluate(input).afterReserveCents, 120000);
    });
    test('negative corrections only and duplicate source/reference denied', () {
      const wrong = ShiftInput(earningsMode: EarningsMode.itemized, items: [
        IncomeItem(id: '1', source: 'Grab', kind: IncomeKind.jobs, amountCents: -300),
      ]);
      expect(FinancialEngine.evaluate(wrong).status, EstimateStatus.invalid);
      const dup = ShiftInput(earningsMode: EarningsMode.itemized, items: [
        IncomeItem(id: '1', source: 'Grab', kind: IncomeKind.jobs, amountCents: 300, reference: 'ABC'),
        IncomeItem(id: '2', source: 'Grab', kind: IncomeKind.jobs, amountCents: 400, reference: 'abc'),
      ]);
      expect(FinancialEngine.evaluate(dup).status, EstimateStatus.invalid);
    });
    test('unconfirmed platform earnings basis makes estimate incomplete', () {
      const input = ShiftInput(quickEarningsCents: 10000,
        afterPlatformFeesConfirmed: false,
        fuelMethod: FuelMethod.manual, manualFuelCents: 0,
        otherCostCents: 0, reservePerKmCents: 0);
      expect(FinancialEngine.evaluate(input).afterReserveCents, isNull);
    });
    test('invalid efficiency and distance rejected', () {
      const input = ShiftInput(quickEarningsCents: 10000,
        fuelMethod: FuelMethod.distance, distanceKm: 100,
        efficiencyKmL: 0, fuelPriceCents: 6500);
      expect(FinancialEngine.evaluate(input).status, EstimateStatus.invalid);
    });
  });
}
