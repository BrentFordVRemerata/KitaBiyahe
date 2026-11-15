import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/app_state.dart';
import 'package:kitabiyahe/core/finance.dart';
import 'package:kitabiyahe/core/repository.dart';

void main() {
  late Directory directory;
  late DataRepository repository;
  late File mainFile;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kitabiyahe-repository-');
    repository = DataRepository(storageDirectory: directory);
    mainFile = File('${directory.path}${Platform.pathSeparator}kitabiyahe_data_v1.json');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  AppData data(String id, int earnings) {
    final now = DateTime.utc(2026, 11, 14);
    return AppData(records: [ShiftRecord(id: id, workDate: now,
      createdAt: now, updatedAt: now,
      input: ShiftInput(quickEarningsCents: earnings))]);
  }

  test('loads valid recovery after corrupt main without replacing recovery', () async {
    final good = BackupCodec.encode(data('recovered', 12345));
    await mainFile.writeAsString('{broken');
    final recovery = File('${mainFile.path}.recovery');
    await recovery.writeAsString(good);

    final loaded = await repository.load();

    expect(loaded.records.single.id, 'recovered');
    expect(await recovery.readAsString(), good);
    expect(await mainFile.readAsString(), '{broken');
  });

  test('saving after recovery does not copy a corrupt primary over good recovery', () async {
    final good = BackupCodec.encode(data('recovered', 12345));
    final recovery = File('${mainFile.path}.recovery');
    await mainFile.writeAsString('{broken');
    await recovery.writeAsString(good);

    await repository.save(data('new', 222));

    expect(await recovery.readAsString(), good);
    expect((await repository.load()).records.single.id, 'new');
  });

  test('loads a valid pending write when main is missing', () async {
    final pending = File('${mainFile.path}.pending');
    await pending.writeAsString(BackupCodec.encode(data('pending', 200)));

    expect((await repository.load()).records.single.id, 'pending');
  });

  test('a missing primary loads the only valid recovery shift', () async {
    final recovery = File('${mainFile.path}.recovery');
    await recovery.writeAsString(BackupCodec.encode(data('original', 15000)));
    expect((await repository.load()).records.single.id, 'original');
  });

  test('throws when only invalid remnants exist instead of returning blank data', () async {
    await mainFile.writeAsString('{broken');
    await File('${mainFile.path}.pending').writeAsString('not json');

    await expectLater(repository.load(), throwsFormatException);
  });

  test('invalid import preserves current memory and disk data', () async {
    final existing = data('keep', 5000);
    await repository.save(existing);
    final state = RiderAppState(repository, existing);
    final before = await mainFile.readAsString();

    await expectLater(state.importJson('{"version":22,"records":[{"id":"old","input":{}}]}', replace: true),
      throwsFormatException);

    expect(state.records.single.id, 'keep');
    expect(await mainFile.readAsString(), before);
    expect((await repository.load()).records.single.id, 'keep');
  });

  test('legacy record with missing earnings is rejected rather than imported as zero', () {
    final legacy = jsonEncode({'version':22,'records':[{'id':'old','date':'2026-11-14',
      'input': {'earningsMode':'quick'}}]});
    expect(() => BackupCodec.decode(legacy), throwsFormatException);
  });

  test('oversized backup is rejected before decoding', () {
    expect(() => BackupCodec.decode(' ' * (BackupCodec.maxBackupBytes + 1)), throwsFormatException);
  });

  test('concurrent state writes preserve both newly saved shifts', () async {
    final state = RiderAppState(repository, const AppData());
    await Future.wait([
      state.upsert(const ShiftInput(quickEarningsCents: 100)),
      state.upsert(const ShiftInput(quickEarningsCents: 200)),
    ]);
    expect(state.records, hasLength(2));
    expect((await repository.load()).records, hasLength(2));
  });
}
