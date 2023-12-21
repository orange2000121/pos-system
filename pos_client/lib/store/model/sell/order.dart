/// 訂單紀錄，包含訂單編號、顧客編號、總金額、建立時間

import 'package:pos/store/model/sell/sell.dart';
import 'package:sqflite/sqflite.dart';

class OrderItem {
  late double totalPrice;
  late int? customerId;
  int? id;
  DateTime? createAt;

  OrderItem fromMap(Map<String, dynamic> map) {
    id = map['id'];
    totalPrice = map['totalPrice'];
    customerId = map['customerId'];
    createAt = DateTime.parse(map['createAt']);
    return this;
  }

  static OrderItem fromMapStatic(Map<String, dynamic> map) {
    return OrderItem(
      map['totalPrice'],
      customerId: map['customerId'],
      id: map['id'],
      createAt: DateTime.parse(map['createAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPrice': totalPrice,
      'customerId': customerId,
      'createAt': createAt == null ? DateTime.now().toString() : createAt.toString(),
    };
  }

  OrderItem(this.totalPrice, {this.id, this.createAt, this.customerId});
}

class OrderProvider {
  // ignore: avoid_init_to_null
  late Database? db = null;
  String tableName = 'orders';
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
            customerId integer,
            totalPrice real not null,
            createAt TIMESTAMP not null
          )
          ''');
      },
    );
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            customerId integer,
            totalPrice real not null,
            createAt TIMESTAMP not null
          )
          ''');
    return db;
  }

  Future<int> insert(OrderItem item) async {
    db ??= await open();

    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future update(int id, OrderItem item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future<OrderItem> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    Map<String, dynamic> map = maps.first;
    return OrderItem.fromMapStatic(map);
  }

  Future<List<OrderItem>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<OrderItem> items = [];
    for (var map in maps) {
      items.add(OrderItem.fromMapStatic(map));
    }
    return items;
  }

  Future<List<OrderItem>> getAllFromDateRange(DateTime start, DateTime end) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'createAt BETWEEN ? AND ?', whereArgs: [start.toString(), end.toString()]);
    List<OrderItem> items = [];
    for (var map in maps) {
      items.add(OrderItem.fromMapStatic(map));
    }
    return items;
  }

  Future<List<OrderItem>> getAllFromCustomerIdAndDateRange(int customerId, DateTime start, DateTime end) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'customerId = ? AND createAt BETWEEN ? AND ?', whereArgs: [customerId, start.toString(), end.toString()]);
    List<OrderItem> items = [];
    for (var map in maps) {
      items.add(OrderItem.fromMapStatic(map));
    }
    return items;
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
    await db!.delete(SellProvider().tableName, where: 'orderId = ?', whereArgs: [id]);
  }

  Future deleteAll() async {
    db ??= await open();
    await db!.delete(tableName);
  }

  Future close() async => db!.close();
}
