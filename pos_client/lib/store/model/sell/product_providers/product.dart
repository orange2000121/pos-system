/// 販賣的商品，包含商品名稱、價格、單位、圖片
library;

import 'package:pos/store/model/database_handler.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:sqflite/sqflite.dart';

class Product {
  int groupId;
  int goodId;
  double price;
  bool autoCreate;
  int status;

  Map<String, dynamic> toMap() {
    var map = <String, Object>{};
    map['group_id'] = groupId;
    map['good_id'] = goodId;
    map['price'] = price;
    map['auto_create'] = autoCreate ? 1 : 0;
    map['status'] = status;
    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      groupId: map['group_id'] as int,
      goodId: map['good_id'] as int,
      price: map['price'] as double,
      autoCreate: map['auto_create'] == 1,
      status: map['status'] as int,
    );
  }

  Product({
    required this.groupId,
    required this.goodId,
    required this.price,
    this.autoCreate = false,
    this.status = 1,
  });
}

class ProductProvider extends DatabaseHandler {
  String tableName = 'product';
  String dbName = 'pos.db';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName (
            group_id integer not null,
            good_id integer not null,
            price real not null,
            auto_create INTEGER NOT NULL DEFAULT 0,
            status INTEGER NOT NULL DEFAULT 1,
            foreign key (group_id) references product_group(id) on delete cascade on update cascade)
          ''');
    return db!;
  }

  Future<int> insert(Product item) async {
    db ??= await open();
    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future<Product?> getItem(int goodId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'good_id = ?', whereArgs: [goodId]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product?> getItemByName(String name) async {
    db ??= await open();
    Good? good = await GoodProvider().getItemByName(name);
    if (good == null) return null;

    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'good_id = ?', whereArgs: [good.id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> getItemsByGroupId(int groupId, {bool isActive = true}) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(
      tableName,
      where: 'group_id = ? AND status = ?',
      whereArgs: [groupId, isActive ? 1 : 0],
    );
    List<Product> items = [];
    for (var map in maps) {
      items.add(Product.fromMap(map));
    }
    return items;
  }

  Future<List<Product>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<Product> items = [];
    for (var map in maps) {
      items.add(Product.fromMap(map));
    }
    return items;
  }

  Future<List<Product>> getAllByStatus(bool isActive) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'status = ?', whereArgs: [isActive ? 1 : 0]);
    List<Product> items = [];
    for (var map in maps) {
      items.add(Product.fromMap(map));
    }
    return items;
  }

  Future update(Product item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'good_id = ?', whereArgs: [item.goodId]);
  }

  Future delete(int goodId) async {
    db ??= await open();
    await db!.delete(tableName, where: 'good_id = ?', whereArgs: [goodId]);
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
