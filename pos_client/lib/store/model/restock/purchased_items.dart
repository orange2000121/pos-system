import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

/// 進貨品項，包含品項編號、進貨廠商編號、品項名稱、品項單位

class PurchasedItem {
  final int? id;
  final int vendorId;
  final String name;
  final String unit;
  double? amount;

  PurchasedItem({
    this.id,
    required this.vendorId,
    required this.name,
    required this.unit,
    this.amount = 0,
  });

  factory PurchasedItem.fromJson(Map<String, dynamic> json) {
    return PurchasedItem(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      unit: json['unit'],
      amount: json['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'unit': unit,
      'amount': amount ?? 0,
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
            id integer primary key autoincrement, 
            vendorId integer not null,
            name text not null,
            unit text not null,
            amount real not null
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

  Future<PurchasedItem?> queryById(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return PurchasedItem.fromJson(maps.first);
  }

  Future update(int id, PurchasedItem item) async {
    db ??= await open();
    await db!.update(tableName, item.toInsertMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
