// ignore_for_file: annotate_overrides, overridden_fields

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pos/model/item.dart';
import 'package:sqflite/sqflite.dart';

class InventoryItem extends Item {
  late String name;
  late double price;
  late int quantity;
  late Uint8List? image;
  @override
  Map<String, dynamic> toMap() {
    var map = <String, Object>{};
    map['name'] = name;
    map['price'] = price;
    map['image'] = image ?? Uint8List(0);
    map['quantity'] = quantity;
    return map;
  }

  static InventoryItem fromMapStatic(Map<String, dynamic> map) {
    return InventoryItem(
      map['name'] as String,
      map['price'] as double,
      image: map['image'] as Uint8List?,
      quantity: map['quantity'] as int,
    );
  }

  @override
  InventoryItem fromMap(Map<String, dynamic> map) {
    name = map['name'] as String;
    price = double.parse(map['price'].toString());
    image = map['image'] as Uint8List?;
    quantity = map['quantity'] as int;
    return this;
  }

  @override
  Widget toWidget() {
    return ListTile(
      leading: Image.memory(
        image!,
        errorBuilder: (context, error, stackTrace) => const FlutterLogo(
          size: 50,
        ),
      ),
      title: Text(name),
      subtitle: Text('Price: $price'),
      trailing: Text('Quantity: $quantity'),
    );
  }

  InventoryItem(this.name, this.price, {this.image, this.quantity = 0}) {
    length = toMap().length;
  }
}

class InventoryProvider extends ItemProvider {
  // ignore: avoid_init_to_null
  @override
  // ignore: avoid_init_to_null
  late Database? db = null;
  @override
  String tableName = 'inventory';
  @override
  String dbName = 'pos.db';

  @override
  Future open() async {
    var path = await getDatabasesPath() + dbName;
    db = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
          create table $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            price real not null,
            image blob,
            quantity integer not null)
          ''');
    });
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            price real not null,
            image blob,
            quantity integer not null)
          ''');
    return db;
  }

  @override
  Future<InventoryItem> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return InventoryItem.fromMapStatic(maps.first);
  }

  @override
  Future<List<InventoryItem>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<InventoryItem> items = [];
    for (var map in maps) {
      items.add(InventoryItem.fromMapStatic(map));
    }
    return items;
  }
}
