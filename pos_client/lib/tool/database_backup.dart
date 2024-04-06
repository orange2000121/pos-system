import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos/tool/csv_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';

class DataBaseBackup {
  String dbName = 'pos.db';
  Future<bool> backup({String? exportPath}) async {
    String dbPath = await getDatabasesPath();
    Database db = await openDatabase('$dbPath$dbName');
    String? downloadPath = exportPath ?? (await getDownloadsDirectory())?.path;
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
    FilePickerResult? backupFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
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

  Future<bool> exportCSV() async {
    String dbPath = await getDatabasesPath();
    String exportFolderName = 'export';
    Database db = await openDatabase('$dbPath$dbName');
    String exportPath = await FilePicker.platform.getDirectoryPath() ?? '';
    if (exportPath.isEmpty) return false;
    try {
      Directory directory = Directory('$exportPath/$exportFolderName');
      if (!directory.existsSync()) {
        directory.createSync();
      }
    } catch (e) {
      return false;
    }
    try {
      List<Map<String, dynamic>> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      for (Map<String, dynamic> table in tables) {
        String tableName = table['name'];
        List<Map<String, dynamic>> tableData = await db.query(tableName);
        String? csv = mapListToCsv(tableData);
        if (csv == null) continue;
        File file = File('$exportPath/$exportFolderName/$tableName.csv');
        file.writeAsString(csv);
      }
    } catch (e) {
      return false;
    }
    return true;
  }
}
