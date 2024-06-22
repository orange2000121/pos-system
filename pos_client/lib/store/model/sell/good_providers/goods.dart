/// 販賣的商品，包含商品名稱、價格、單位、圖片

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class Good {
  int? id;
  late int groupId;
  late String name;
  late double price;
  late String unit;
  late Uint8List? image;
  double? amount;
  int length = 0;
  Map<String, dynamic> toMap() {
    var map = <String, Object>{};
    map['group_id'] = groupId;
    map['name'] = name;
    map['price'] = price;
    map['unit'] = unit;
    map['image'] = image ?? Uint8List(0);
    map['amount'] = amount ?? 0;
    return map;
  }

  static Good fromMapStatic(Map<String, dynamic> map) {
    return Good(
      map['group_id'] as int,
      map['name'] as String,
      map['price'] as double,
      map['unit'] as String,
      image: map['image'] as Uint8List?,
      id: map['id'] as int?,
      amount: map['amount'] ?? 0,
    );
  }

  Good fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    groupId = map['group_id'] as int;
    name = map['name'] as String;
    price = double.parse(map['price'].toString());
    unit = map['unit'] as String;
    image = map['image'] as Uint8List?;
    amount = (map['amount'] ?? 0) as double;
    return this;
  }

  // Widget toWidget({Function()? onTap}) {
  //   return ListTile(
  //     leading: Image.memory(
  //       image!,
  //       errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
  //     ),
  //     title: Text(name),
  //     subtitle: Text('單價: $price'),
  //     trailing: IconButton(
  //       icon: const Icon(Icons.edit),
  //       onPressed: onTap,
  //     ),
  //   );
  // }

  Good(
    this.groupId,
    this.name,
    this.price,
    this.unit, {
    this.image,
    this.id,
    this.amount = 0,
  }) {
    length = toMap().length;
  }
}

class GoodsProvider extends DatabaseHandler {
  // ignore: avoid_init_to_null
  // late Database? db = null;
  String tableName = 'goods';
  String dbName = 'pos.db';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName (
            id integer primary key autoincrement,
            group_id integer not null,
            name text not null,
            price real not null,
            unit text not null,
            image blob,
            amount real not null,
            foreign key (group_id) references goods_group(id) on delete cascade on update cascade)
          ''');
    return db!;
  }

  Future<int> insert(Good item) async {
    db ??= await open();
    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future<Good> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return Good.fromMapStatic(maps.first);
  }

  Future<Good?> getItemByName(String name) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'name = ?', whereArgs: [name]);
    if (maps.isEmpty) {
      return null;
    }
    return Good.fromMapStatic(maps.first);
  }

  Future<List<Good>> getItemsByGroupId(int groupId) async {
    db ??= await open();
    print('db version: ${await db!.getVersion()}');
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'group_id = ?', whereArgs: [groupId]);
    List<Good> items = [];
    for (var map in maps) {
      items.add(Good.fromMapStatic(map));
    }
    return items;
  }

  Future<List<Good>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<Good> items = [];
    for (var map in maps) {
      items.add(Good.fromMapStatic(map));
    }
    return items;
  }

  Future update(Good item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future deleteAll() async {
    db ??= await open();
    await db!.delete(tableName);
  }

  void close() async => db != null ? await db!.close() : null;

  void deleteByGroupId(int groupId) async {
    db ??= await open();
    db!.delete(tableName, where: 'group_id = ?', whereArgs: [groupId]);
  }
}
