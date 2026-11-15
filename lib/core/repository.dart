import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';

import 'finance.dart';

class AppData {
  final RiderSettings settings;
  final List<ShiftRecord> records;
  const AppData({
    this.settings = const RiderSettings(),
    this.records = const [],
  });

  Map<String, Object?> toJson() => {
    'app': 'KitaBiyahe',
    'schema': 1,
    'settings': settings.toJson(),
    'records': records.map((r) => r.toJson()).toList(),
  };
}

class BackupCodec {
  static const maxRecords = 100;

  /// Bound the amount of untrusted data parsed from a hand-selected backup.
  static const maxBackupBytes = 1024 * 1024;

  static String encode(AppData state) =>
      const JsonEncoder.withIndent('  ').convert(state.toJson());

  static AppData decode(String text) {
    if (utf8.encode(text).length > maxBackupBytes) {
      throw const FormatException('Backup file is too large (maximum 1 MB).');
    }
    final raw = jsonDecode(text);
    if (raw is! Map) {
      throw const FormatException('Expected a JSON backup object.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['app'] == 'KitaBiyahe' && map['schema'] == 1) {
      final rawRecords = map['records'];
      if (rawRecords is! List || rawRecords.length > maxRecords) {
        throw const FormatException('Backup must contain 0–100 records.');
      }
      final settings = RiderSettings.fromJson(
        Map<String, dynamic>.from(map['settings'] as Map? ?? {}),
      );
      final records = <ShiftRecord>[];
      final ids = <String>{};
      for (final value in rawRecords) {
        final record = ShiftRecord.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
        if (record.id.isEmpty ||
            !ids.add(record.id) ||
            FinancialEngine.evaluate(record.input).status ==
                EstimateStatus.invalid ||
            record.input.earningsCents == null) {
          throw const FormatException(
            'A record is invalid or has a duplicate ID.',
          );
        }
        records.add(record);
      }
      return AppData(settings: settings, records: records);
    }
    if (map['version'] == 22 && map['records'] is List) {
      return _fromLegacyV23(map);
    }
    throw const FormatException(
      'Not a supported KitaBiyahe native or V2.3 JSON backup.',
    );
  }

  static AppData _fromLegacyV23(Map<String, dynamic> map) {
    final list = map['records'] as List;
    if (list.length > maxRecords) {
      throw const FormatException('Too many records in legacy backup.');
    }
    int? money(dynamic value, {bool allowNegative = false}) {
      if (value == null) return null;
      if (value is! num ||
          !value.isFinite ||
          value.abs() > 10000000 ||
          (!allowNegative && value < 0)) {
        throw const FormatException(
          'Invalid or out-of-range legacy money entry.',
        );
      }
      final rounded = (value * 100).round();
      if ((rounded - value * 100).abs() > 0.000001) {
        throw const FormatException(
          'Legacy money must have at most two decimals.',
        );
      }
      return rounded;
    }

    final records = <ShiftRecord>[];
    final ids = <String>{};
    for (final raw in list) {
      if (raw is! Map) throw const FormatException('Malformed legacy record.');
      final r = Map<String, dynamic>.from(raw);
      if (r['id'] is! String || (r['id'] as String).isEmpty) {
        throw const FormatException('Legacy record has no valid ID.');
      }
      final id = 'web-v23:${r['id']}';
      if (id.length > 120 || !ids.add(id)) {
        throw const FormatException('Duplicate legacy record ID.');
      }
      final input = Map<String, dynamic>.from(r['input'] as Map);
      final items = <IncomeItem>[];
      if (input['earningsMode'] == 'itemized') {
        for (final e in input['earningEntries'] as List? ?? []) {
          final entry = Map<String, dynamic>.from(e as Map);
          final kind = IncomeKind.values.firstWhere(
            (k) => k.name == entry['kind'],
            orElse: () => IncomeKind.jobs,
          );
          items.add(
            IncomeItem(
              id: entry['id']?.toString() ?? '${items.length}',
              source: entry['source']?.toString() ?? 'Other app',
              kind: kind,
              amountCents:
                  money(
                    entry['amount'],
                    allowNegative: kind == IncomeKind.adjustment,
                  ) ??
                  (throw const FormatException(
                    'Legacy income entry has no amount.',
                  )),
              reference: entry['reference']?.toString() ?? '',
            ),
          );
        }
      }
      final fuelMethod = switch (input['fuelMethod']) {
        'manual' => FuelMethod.manual,
        'distance' => FuelMethod.distance,
        _ => FuelMethod.unknown,
      };
      final efficiencySource = switch (input['efficiencySource']) {
        'measured' => EfficiencySource.measured,
        'estimated' => EfficiencySource.estimate,
        _ => EfficiencySource.unknown,
      };
      final rawInput = ShiftInput(
        earningsMode: input['earningsMode'] == 'itemized'
            ? EarningsMode.itemized
            : EarningsMode.quick,
        quickEarningsCents: input['earningsMode'] == 'itemized'
            ? null
            : (money(input['earnings']) ??
                  (throw const FormatException(
                    'Legacy record has no earnings amount.',
                  ))),
        items: items,
        afterPlatformFeesConfirmed: input['earningsBasis'] != 'unsure',
        fuelMethod: fuelMethod,
        manualFuelCents: money(input['manualFuelCost']),
        distanceKm: (input['distanceKm'] as num?)?.toDouble(),
        efficiencyKmL: (input['efficiency'] as num?)?.toDouble(),
        efficiencySource: efficiencySource,
        fuelPriceCents: money(input['fuelPrice']),
        otherCostCents: money(input['otherCost']),
        reservePerKmCents: money(input['reservePerKm']),
        hours: (input['hours'] as num?)?.toDouble(),
        targetCents: money(input['target']),
        notes: input['notes']?.toString() ?? '',
      );
      if (rawInput.earningsCents == null ||
          FinancialEngine.evaluate(rawInput).status == EstimateStatus.invalid) {
        throw const FormatException(
          'Legacy record has invalid financial inputs.',
        );
      }
      final date = DateTime.parse(r['date'] as String);
      final created =
          DateTime.tryParse(r['createdAt']?.toString() ?? '') ?? date;
      final updated =
          DateTime.tryParse(r['updatedAt']?.toString() ?? '') ?? created;
      records.add(
        ShiftRecord(
          id: id,
          workDate: date,
          createdAt: created,
          updatedAt: updated,
          input: rawInput,
        ),
      );
    }
    final rawSettings = Map<String, dynamic>.from(
      map['settings'] as Map? ?? {},
    );
    final settings = RiderSettings.fromJson({
      'efficiencyKmL': rawSettings['efficiency'],
      'efficiencySource': switch (rawSettings['efficiencySource']) {
        'measured' => EfficiencySource.measured.name,
        'estimated' => EfficiencySource.estimate.name,
        _ => EfficiencySource.unknown.name,
      },
      'fuelPriceCents': money(rawSettings['fuelPrice']),
      'reservePerKmCents': money(rawSettings['reservePerKm']),
    });
    return AppData(settings: settings, records: records);
  }

  static AppData merge(AppData current, AppData imported) {
    final byId = <String, ShiftRecord>{
      for (final r in current.records) r.id: r,
    };
    for (final r in imported.records) {
      byId.putIfAbsent(r.id, () => r);
    }
    if (byId.length > maxRecords) {
      throw const FormatException('Import would exceed the 100-record limit.');
    }
    return AppData(settings: current.settings, records: byId.values.toList());
  }
}

/// Uses a JSON file and a recovery copy instead of browser localStorage.
/// A temporary file is flushed before replacing the previous file.
class DataRepository {
  /// An optional app-data directory for controlled environments and tests.
  /// Production callers should omit it so the OS support directory is used.
  final Directory? storageDirectory;
  DataRepository({this.storageDirectory});

  Future<void> _writeTail = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _writeTail = _writeTail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<File> _stateFile() async {
    final dir = storageDirectory ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}kitabiyahe_data_v1.json');
  }

  Future<AppData> load() => _serialize(() async {
    final file = await _stateFile();
    final candidates = [
      file,
      File('${file.path}.pending'),
      File('${file.path}.recovery'),
      File('${file.path}.previous'),
    ];
    var sawRemnant = false;
    for (final candidate in candidates) {
      if (!await candidate.exists()) continue;
      sawRemnant = true;
      try {
        if (await candidate.length() > BackupCodec.maxBackupBytes) continue;
        return BackupCodec.decode(await candidate.readAsString());
      } on Object {
        // Continue to the next independently validated copy. Never copy an
        // unreadable primary over a potentially good recovery file.
      }
    }
    if (sawRemnant) {
      throw const FormatException(
        'Saved data and recovery copies are unreadable. Do not overwrite them; restore a JSON backup.',
      );
    }
    return const AppData();
  });

  Future<void> save(AppData state) => _serialize(() async {
    if (state.records.length > BackupCodec.maxRecords) {
      throw const FormatException(
        'Maximum 100 records. Export a backup before deleting old shifts.',
      );
    }
    final file = await _stateFile();
    final temp = File('${file.path}.pending');
    final recovery = File('${file.path}.recovery');
    final previous = File('${file.path}.previous');
    final encoded = BackupCodec.encode(state);
    BackupCodec.decode(encoded); // validate before writing
    await temp.writeAsString(encoded, flush: true);
    if (await file.exists()) {
      // Only refresh recovery from a validated main file. A corrupt main must
      // never destroy a good recovery copy.
      try {
        BackupCodec.decode(await file.readAsString());
        final recoveryTemp = File('${recovery.path}.pending');
        await file.copy(recoveryTemp.path);
        if (await recovery.exists()) await recovery.delete();
        await recoveryTemp.rename(recovery.path);
      } on Object {
        // Retain any existing recovery copy.
      }
    }
    try {
      // Windows does not replace an existing destination on rename. Preserve
      // it under a recoverable name until the flushed pending file is in place.
      if (await file.exists()) {
        if (await previous.exists()) await previous.delete();
        await file.rename(previous.path);
      }
      await temp.rename(file.path);
      if (await previous.exists()) await previous.delete();
    } catch (_) {
      if (await previous.exists() && !await file.exists()) {
        await previous.rename(file.path);
      }
      rethrow;
    }
  });
}
