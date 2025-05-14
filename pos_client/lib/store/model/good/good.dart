// ignore_for_file: constant_identifier_names
// 所有的物品資料表，包括商品、進貨等，以物品存在的東西。
import 'dart:typed_data';

import 'package:pos/store/model/database_handler.dart';
import 'package:pos/store/model/good/inventory.dart';
import 'package:sqflite/sqflite.dart';

class Good {
  final int id;
  final String name;
  final String unit;
  final Uint8List? image;
  int status;

  static const int ENABLE = 1;
  static const int DISABLE = 0;
  static const int DELETE = -1;

  Good({
    required this.id,
    required this.name,
    required this.unit,
    this.image,
    this.status = ENABLE,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      image: json['image'],
      status: json['status'] ?? ENABLE,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'image': image ?? Uint8List(0),
      'status': status,
    };
  }
}

class GoodProvider extends DatabaseHandler {
  String tableName = 'good';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            unit text not null,
            image blob,
            status integer not null
          )
          ''');
    return db!;
  }

  Future<int> insert(Good good) async {
    db ??= await open();
    int goodId = await db!.insert(tableName, good.toMap());
    // 建立good時，一併建立inventory
    InventoryProvider inventoryProvider = InventoryProvider();
    Inventory inventory = Inventory(
      goodId: goodId,
      quantity: 0,
      recodeMode: Inventory.CREATE_MODE,
      recordTime: DateTime.now(),
    );
    await inventoryProvider.insert(inventory);
    return goodId;
  }

  Future<List<Good>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    return List.generate(maps.length, (i) {
      return Good.fromJson(maps[i]);
    });
  }

  Future<Good?> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Good.fromJson(maps.first);
  }

  Future<Good?> getItemByName(String name) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'name = ?', whereArgs: [name]);
    if (maps.isEmpty) {
      return null;
    }
    return Good.fromJson(maps.first);
  }

  Future<Good?> update(Good good) async {
    db ??= await open();
    int result = await db!.update(tableName, good.toMap(), where: 'id = ?', whereArgs: [good.id]);
    if (result == 0) {
      return null;
    }
    return good;
  }

  Future<int> delete(int id) async {
    db ??= await open();
    int result = await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
    return result;
  }
}
