// ignore_for_file: constant_identifier_names
// 用於紀錄庫存量的資料表

import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class Inventory {
  final int goodId;
  final double quantity;
  final String recodeMode;
  DateTime recordTime;

  static const String CREATE_MODE = 'create';
  static const String MANUAL_MODE = 'manual';
  static const String COMPUTE_MODE = 'compute';

  Inventory({
    required this.goodId,
    required this.quantity,
    required this.recodeMode,
    required this.recordTime,
  });
  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      goodId: json['good_id'],
      quantity: json['quantity'],
      recodeMode: json['recode_mode'],
      recordTime: DateTime.parse(json['record_time']),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'good_id': goodId,
      'quantity': quantity,
      'recode_mode': recodeMode,
      'record_time': DateTime.now().toString(),
    };
  }
}

class InventoryProvider extends DatabaseHandler {
  static const String tableName = 'inventory';

  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            good_id integer primary key,
            quantity real not null,
            recode_mode text not null,
            record_time text not null
          )
          ''');
    return db!;
  }

  Future<int> insert(Inventory inventory) async {
    db ??= await open();
    return await db!.insert(tableName, inventory.toMap());
  }

  Future<Inventory?> getInventoryByGoodId(int goodId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'good_id = ?', whereArgs: [goodId]);
    if (maps.isEmpty) return null;
    return Inventory.fromJson(maps.first);
  }

  Future<int?> delete(int id) async {
    db ??= await open();
    return await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future update(Inventory inventory) async {
    db ??= await open();
    return await db!.update(tableName, inventory.toMap(), where: 'good_id = ?', whereArgs: [inventory.goodId]);
  }
}
