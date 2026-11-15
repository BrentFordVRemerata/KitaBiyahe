import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/app_state.dart';
import 'package:kitabiyahe/core/finance.dart';
import 'package:kitabiyahe/core/repository.dart';

void main() {
  final fixture = File(
    'test/fixtures/legacy_v22_export.json',
  ).readAsStringSync();

  test(
    'archived exporter fixture preserves itemized amounts, sources and identity',
    () {
      final imported = BackupCodec.decode(fixture);
      final record = imported.records.first;
      final input = record.input;
      expect(record.id, 'web-v23:fixture-itemized');
      expect(input.earningsMode, EarningsMode.itemized);
      expect(input.quickEarningsCents, isNull);
      expect(input.earningsCents, 113000);
      expect(input.items.map((item) => item.id), [
        'job-1',
        'tip-1',
        'bonus-1',
        'adjustment-1',
      ]);
      expect(input.items.map((item) => item.source), [
        'Grab',
        'Direct / cash booking',
        'MOVE IT',
        'Grab',
      ]);
      expect(input.items.map((item) => item.kind), [
        IncomeKind.jobs,
        IncomeKind.tip,
        IncomeKind.bonus,
        IncomeKind.adjustment,
      ]);
      expect(input.items.map((item) => item.amountCents), [
        100000,
        5000,
        10000,
        -2000,
      ]);
      expect(input.items.last.reference, 'FICTIONAL-ADJUSTMENT');
      expect(input.efficiencySource, EfficiencySource.measured);
      expect(input.hours, 8.5);
      expect(input.targetCents, 90000);
      final result = FinancialEngine.evaluate(input);
      expect(result.fuelCents, 16250);
      expect(result.cashRemainderCents, 88750);
      expect(result.afterReserveCents, 78750);
      expect(imported.settings.efficiencySource, EfficiencySource.measured);
      final merged = BackupCodec.merge(imported, BackupCodec.decode(fixture));
      expect(BackupCodec.encode(merged), BackupCodec.encode(imported));
      expect(
        BackupCodec.decode(BackupCodec.encode(imported)).toJson(),
        imported.toJson(),
      );
    },
  );

  test(
    'archived unknown and explicit zero stay different through native round trip',
    () {
      final imported = BackupCodec.decode(fixture);
      final unknown = imported.records[1].input;
      final zero = imported.records[2].input;
      expect(unknown.otherCostCents, isNull);
      expect(unknown.manualFuelCents, isNull);
      expect(FinancialEngine.evaluate(unknown).afterReserveCents, isNull);
      expect(zero.earningsCents, 0);
      expect(zero.otherCostCents, 0);
      expect(zero.manualFuelCents, 0);
      expect(zero.hours, 0);
      expect(zero.targetCents, 0);
      expect(FinancialEngine.evaluate(zero).afterReserveCents, 0);
      expect(
        BackupCodec.decode(BackupCodec.encode(imported)).toJson(),
        imported.toJson(),
      );
    },
  );

  test(
    'invalid legacy settings are rejected before records or persisted bytes change',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kitabiyahe-legacy-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repo = DataRepository(storageDirectory: directory);
      final initial = BackupCodec.decode(fixture);
      await repo.save(initial);
      final app = RiderAppState(repo, initial);
      final main = File(
        '${directory.path}${Platform.pathSeparator}kitabiyahe_data_v1.json',
      );
      final bytes = await main.readAsBytes();
      final before = app.exportJson();
      for (final entry in <MapEntry<String, Object>>[
        const MapEntry('fuelPrice', 65.001),
        const MapEntry('reservePerKm', 1.001),
        const MapEntry('fuelPrice', -1),
        const MapEntry('fuelPrice', 1e300),
        const MapEntry('efficiency', 0),
        const MapEntry('efficiency', 1001),
      ]) {
        final invalid = jsonDecode(fixture) as Map<String, dynamic>;
        (invalid['settings'] as Map)[entry.key] = entry.value;
        await expectLater(
          app.importJson(jsonEncode(invalid), replace: true),
          throwsFormatException,
          reason: '${entry.key}=${entry.value} must not become a saved default',
        );
        expect(app.exportJson(), before);
        expect(await main.readAsBytes(), bytes);
      }
    },
  );
}
