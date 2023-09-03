import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

class GoodsGroupItem {
  int? id;
  late String name;
  Uint8List? image;

  GoodsGroupItem fromMap(Map<String, dynamic> map) {
    name = map['name'];
    image = map['image'];
    return this;
  }

  static GoodsGroupItem fromMapStatic(Map<String, dynamic> map) {
    return GoodsGroupItem(
      map['name'] as String,
      image: map['image'] as Uint8List?,
      id: map['id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
    };
  }

  GoodsGroupItem(this.name, {this.image, this.id});
}

class GoodsGroupProvider {
  late Database? db = null;
  String tableName = 'goods_group';
  String dbName = 'pos.db';
  Future open() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + dbName;
    db = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
          create table $tableName ( 
            id integer primary key autoincrement,
            name text not null, 
            image blob
          )
          ''');
    });
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement,
            name text not null, 
            image blob
          )
          ''');
    return db;
  }

  Future<int> insert(GoodsGroupItem item) async {
    db ??= await open();
    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future update(int id, GoodsGroupItem item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GoodsGroupItem>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    return List.generate(maps.length, (i) {
      return GoodsGroupItem.fromMapStatic(maps[i]);
    });
  }

  Future close() async => db!.close();
}
