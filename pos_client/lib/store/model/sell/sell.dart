/// 記錄單向商品訂單記錄，包含訂單編號、商品名稱、價格、數量、建立時間
library;

import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class SellItem {
  late int? id;
  late int orderId;
  late String name;
  late double price;
  late DateTime? createAt;
  int quantity = 1;
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'createAt': createAt == null ? DateTime.now().toString() : createAt.toString(),
    };
  }

  static SellItem fromMapStatic(Map<String, dynamic> map) {
    SellItem item = SellItem(
      map['orderId'],
      map['name'],
      map['price'],
      map['quantity'],
      id: map['id'],
      createAt: DateTime.parse(map['createAt']),
    );
    return item;
  }

  SellItem fromMap(Map<String, dynamic> map) {
    orderId = map['orderId'];
    name = map['name'];
    price = map['price'];
    quantity = map['quantity'];
    id = map['id'];
    createAt = DateTime.parse(map['createAt']);
    return this;
  }

  SellItem(this.orderId, this.name, this.price, this.quantity, {this.id, this.createAt});
}

class SellProvider extends DatabaseHandler {
  String tableName = 'sell';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            orderId integer not null,
            name text not null,
            price real not null,
            quantity integer not null,
            createAt TIMESTAMP not null,
            foreign key (orderId) references orders(id) on delete cascade on update cascade)
          ''');
    return db!;
  }

  Future<SellItem> insert(SellItem item) async {
    db ??= await open();
    await db!.insert(tableName, item.toMap());
    return item;
  }

  Future update(int id, SellItem item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future<SellItem> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return SellItem.fromMapStatic(maps.first);
  }

  Future<List<SellItem>> getItemByOrderId(int orderId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'orderId = ?', whereArgs: [orderId]);
    List<SellItem> items = [];
    for (var map in maps) {
      items.add(SellItem.fromMapStatic(map));
    }
    return items;
  }

  Future<List<SellItem>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<SellItem> items = [];
    for (var map in maps) {
      items.add(SellItem.fromMapStatic(map));
    }
    return items;
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future deleteByOrderId(int orderId) async {
    db ??= await open();
    await db!.delete(tableName, where: 'orderId = ?', whereArgs: [orderId]);
  }

  Future deleteAll() async {
    db ??= await open();
    await db!.delete(tableName);
  }
}
