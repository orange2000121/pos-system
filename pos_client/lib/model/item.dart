import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class Item {
  int length = 0;
  Uint8List? image;
  Map<String, dynamic> toMap() {
    return {};
  }

  static Item fromMapStatic(Map<String, dynamic> map) {
    return Item();
  }

  Item fromMap(Map<String, dynamic> map) {
    return Item();
  }

  Widget toWidget() {
    return const FlutterLogo(
      size: 50,
    );
  }

  Item();
}

class ItemProvider {
  late Database? db = null;
  String tableName = '';
  String dbName = '';
  Future open() async {}

  Future<Item> insert(Item item) async {
    db ??= await open();
    await db!.insert(tableName, item.toMap());
    return item;
  }

  Future update(int id, Item item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future<Item> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return Item.fromMapStatic(maps.first);
  }

  Future<List<Item>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<Item> items = [];
    for (var map in maps) {
      items.add(Item.fromMapStatic(map));
    }
    return items;
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future deleteAll() async {
    db ??= await open();
    await db!.delete(tableName);
  }

  Future close() async => db!.close();
}
