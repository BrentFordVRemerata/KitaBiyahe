import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'finance.dart';
import 'repository.dart';

class RiderAppState extends ChangeNotifier {
  final DataRepository repository;
  AppData _data;
  RiderAppState(this.repository, this._data);

  Future<void> _mutationTail = Future<void>.value();

  Future<void> _serializeMutation(Future<void> Function() operation) {
    final result = Completer<void>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        await operation();
        result.complete();
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  static Future<RiderAppState> initialize() async {
    final repo = DataRepository();
    return RiderAppState(repo, await repo.load());
  }

  RiderSettings get settings => _data.settings;
  List<ShiftRecord> get records => List.unmodifiable(_data.records);
  String exportJson() => BackupCodec.encode(_data);

  Future<void> saveSettings(RiderSettings newSettings) => _serializeMutation(() async {
    final next = AppData(settings: newSettings, records: _data.records);
    await repository.save(next);
    _data = next;
    notifyListeners();
  });

  Future<void> upsert(ShiftInput input, {String? id, DateTime? date}) => _serializeMutation(() async {
    final result = FinancialEngine.evaluate(input);
    if (result.status == EstimateStatus.invalid || input.earningsCents == null) {
      throw const FormatException('Enter valid recorded earnings before saving this shift.');
    }
    final now = DateTime.now();
    final original = id == null ? null : _data.records.where((r) => r.id == id).firstOrNull;
    if (id != null && original == null) {
      throw const FormatException('This shift no longer exists.');
    }
    final assignedId = id ?? 'kb-${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 24)}';
    final record = ShiftRecord(
      id: assignedId, workDate: date ?? original?.workDate ?? now,
      createdAt: original?.createdAt ?? now, updatedAt: now, input: input,
    );
    final updated = <ShiftRecord>[for (final r in _data.records) if (r.id != assignedId) r, record];
    if (updated.length > BackupCodec.maxRecords) throw const FormatException('Maximum 100 saved shifts.');
    final next = AppData(settings: _data.settings, records: updated);
    await repository.save(next);
    _data = next;
    notifyListeners();
  });

  Future<void> remove(String id) => _serializeMutation(() async {
    final next = AppData(settings: _data.settings,
      records: [for (final r in _data.records) if (r.id != id) r]);
    await repository.save(next);
    _data = next;
    notifyListeners();
  });

  /// Merge keeps existing records/settings, even when the import has same IDs.
  /// Replace discards current records/settings only after caller confirmed.
  Future<void> importJson(String json, {required bool replace}) => _serializeMutation(() async {
    final imported = BackupCodec.decode(json);
    final next = replace ? imported : BackupCodec.merge(_data, imported);
    await repository.save(next);
    _data = next;
    notifyListeners();
  });
}
