import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/core/android_backup_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ph.kitabiyahe.kitabiyahe/backup');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('native save receives the exact JSON and suggested filename', () async {
    const json = '{"app":"KitaBiyahe","schema":1,"unknown":null,"zero":0}';
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'saveJsonBackup');
      expect(call.arguments, {
        'json': json,
        'name': 'kitabiyahe-backup-2026-11-14.json',
      });
      return true;
    });
    expect(
      await AndroidBackupFiles.save(json, 'kitabiyahe-backup-2026-11-14.json'),
      isTrue,
    );
  });
  test('cancelling the native picker does not report a saved file', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    expect(await AndroidBackupFiles.save('{}', 'backup.json'), isFalse);
  });
  test('a native write failure remains an error', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'SAVE_FAILED'),
    );
    await expectLater(
      AndroidBackupFiles.save('{}', 'backup.json'),
      throwsA(isA<PlatformException>()),
    );
  });
  test(
    'oversize exports are rejected before opening a native picker',
    () async {
      var invoked = false;
      messenger.setMockMethodCallHandler(channel, (_) async {
        invoked = true;
        return true;
      });
      await expectLater(
        AndroidBackupFiles.save('x' * (1024 * 1024 + 1), 'backup.json'),
        throwsFormatException,
      );
      expect(invoked, isFalse);
    },
  );
}
