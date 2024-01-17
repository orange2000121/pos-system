import 'package:sqflite/sqflite.dart';

/// 進貨品項，包含品項編號、進貨廠商編號、品項名稱、品項單位

class PurchasedItem {
  final int? id;
  final int vendorId;
  final String name;
  final String unit;

  PurchasedItem({
    this.id,
    required this.vendorId,
    required this.name,
    required this.unit,
  });

  factory PurchasedItem.fromJson(Map<String, dynamic> json) {
    return PurchasedItem(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'unit': unit,
    };
  }
}

class PurchasedItemProvider {
  // ignore: avoid_init_to_null
  late Database? db = null;
  String tableName = 'purchased_item';
  String dbName = 'pos.db';
  Future open() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + dbName;
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          create table $tableName ( 
            id integer primary key autoincrement, 
            vendorId integer not null,
            name text not null,
            unit text not null
          )
          ''');
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            vendorId integer not null,
            name text not null,
            unit text not null
          )
          ''');
    return db;
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
