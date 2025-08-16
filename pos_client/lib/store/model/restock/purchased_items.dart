import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

/// 進貨品項，包含品項編號、進貨廠商編號、品項名稱、品項單位

class PurchasedItem {
  final int goodId;
  final int vendorId;
  int status;

  PurchasedItem({
    required this.goodId,
    required this.vendorId,
    this.status = 1,
  });

  factory PurchasedItem.fromJson(Map<String, dynamic> json) {
    return PurchasedItem(
      goodId: json['goodId'],
      vendorId: json['vendorId'],
      status: json['status'] ?? 1,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'vendorId': vendorId,
      'goodId': goodId,
      'status': status,
    };
  }
}

class PurchasedItemProvider extends DatabaseHandler {
  String tableName = 'purchased_item';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            goodId integer not null,
            vendorId integer not null,
            status integer not null default 1
          )
          ''');
    return db!;
  }

  Future<int> insert(PurchasedItem item) async {
    db ??= await open();
    int result = await db!.insert(tableName, item.toInsertMap());
    return result;
  }

  Future<List<PurchasedItem>> queryAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<PurchasedItem> result = [];
    for (var map in maps) {
      result.add(PurchasedItem.fromJson(map));
    }
    return result;
  }

  Future<List<PurchasedItem>> queryByStatus(bool status) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'status = ?', whereArgs: [status ? 1 : 0]);
    List<PurchasedItem> result = [];
    for (var map in maps) {
      result.add(PurchasedItem.fromJson(map));
    }
    return result;
  }

  Future<PurchasedItem?> queryById(int goodId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'goodId = ?', whereArgs: [goodId], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return PurchasedItem.fromJson(maps.first);
  }

  Future update(PurchasedItem item) async {
    db ??= await open();
    await db!.update(tableName, item.toInsertMap(), where: 'goodId = ?', whereArgs: [item.goodId]);
  }

  Future delete(int goodId) async {
    db ??= await open();
    await db!.delete(tableName, where: 'goodId = ?', whereArgs: [goodId]);
  }
}
