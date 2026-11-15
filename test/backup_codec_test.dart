import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/finance.dart';
import 'package:kitabiyahe/core/repository.dart';

void main() {
  test('native backup round trip preserves incomplete zero-vs-null values', () {
    final now = DateTime(2026, 11, 13);
    final input = const ShiftInput(quickEarningsCents: 120000,
      fuelMethod: FuelMethod.unknown, otherCostCents: 0);
    final state = AppData(records: [ShiftRecord(id: 'abc', workDate: now,
      createdAt: now, updatedAt: now, input: input)]);
    final decoded = BackupCodec.decode(BackupCodec.encode(state));
    expect(decoded.records.single.input.otherCostCents, 0);
    expect(decoded.records.single.input.manualFuelCents, isNull);
    expect(decoded.records.single.input.earningsCents, 120000);
  });

  test('legacy V2.3 web backup maps old fields explicitly, not browser storage', () {
    final legacy = jsonEncode({
      'version': 22,
      'settings': {'efficiency': 40, 'fuelPrice': 65, 'reservePerKm': 1},
      'records': [
        {'id': '1', 'date': '2026-11-13',
          'createdAt': '2026-11-13T02:00:00Z',
          'updatedAt': '2026-11-13T02:00:00Z',
          'input': {
            'earningsMode': 'quick', 'earnings': 1200,
            'earningsBasis': 'net-after-fees', 'fuelMethod': 'distance',
            'distanceKm': 100, 'fuelPrice': 65, 'efficiency': 40,
            'otherCost': 80, 'reservePerKm': 1,
          }}
      ]
    });
    final result = BackupCodec.decode(legacy);
    expect(result.records.single.id, 'web-v23:1');
    expect(FinancialEngine.evaluate(result.records.single.input).afterReserveCents, 85750);
    expect(result.settings.efficiencyKmL, 40);
  });

  test('merging twice keeps stable record IDs without duplicates', () {
    final now = DateTime(2026, 11, 13);
    final incoming = AppData(records: [ShiftRecord(id: '1', workDate: now,
      createdAt: now, updatedAt: now,
      input: const ShiftInput(quickEarningsCents: 20000))]);
    final once = BackupCodec.merge(const AppData(), incoming);
    final twice = BackupCodec.merge(once, incoming);
    expect(twice.records.length, 1);
  });

  test('rejects unknown backup schema and duplicate record IDs', () {
    expect(() => BackupCodec.decode('{"app":"KitaBiyahe","schema":27,"records":[]}'),
      throwsFormatException);
    final now = DateTime(2026, 11, 13);
    final record = ShiftRecord(id: 'x', workDate: now,
      createdAt: now, updatedAt: now,
      input: const ShiftInput(quickEarningsCents: 100));
    final text = jsonEncode({'app':'KitaBiyahe', 'schema':1,
      'settings': <String,dynamic>{},
      'records':[record.toJson(), record.toJson()]});
    expect(() => BackupCodec.decode(text), throwsFormatException);
  });
}
