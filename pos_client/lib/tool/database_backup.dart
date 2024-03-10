import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DataBaseBackup {
  String dbName = 'pos.db';
  Future<bool> backup() async {
    String dbPath = await getDatabasesPath();
    Database db = await openDatabase('$dbPath$dbName');
    String? downloadPath = (await getDownloadsDirectory())?.path;
    if (downloadPath == null) return false;
    downloadPath += '/backup.db';
    try {
      if (File(downloadPath).existsSync()) {
        await File(downloadPath).delete();
      }
      File(db.path).copy(downloadPath);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> restore() async {
    String dbPath = await getDatabasesPath() + dbName;
    FilePickerResult? backupFile = await FilePicker.platform.pickFiles();
    if (backupFile == null) return false;
    if (backupFile.files.length != 1) return false;
    if (backupFile.files.single.name.split('.')[1] != 'db') return false;
    String? backupPath = backupFile.files.single.path;
    if (backupPath == null) return false;
    try {
      File(backupPath).copy(dbPath);
    } catch (e) {
      return false;
    }
    return true;
  }
}
