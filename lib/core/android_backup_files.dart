import 'dart:convert';
import 'package:flutter/services.dart';
import 'repository.dart';

abstract final class AndroidBackupFiles {
  static const _channel = MethodChannel('ph.kitabiyahe.kitabiyahe/backup');

  static Future<bool> save(String json, String name) async {
    if (utf8.encode(json).length > BackupCodec.maxBackupBytes) {
      throw const FormatException('Backup exceeds the 1 MB file limit.');
    }
    return await _channel.invokeMethod<bool>('saveJsonBackup', {
          'json': json,
          'name': name,
        }) ??
        false;
  }
}
