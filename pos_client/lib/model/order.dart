import 'package:sqflite/sqflite.dart';

class OrderItem {
  late double totalPrice;
  int? id;
  DateTime? createAt;

  OrderItem fromMap(Map<String, dynamic> map) {
    totalPrice = map['totalPrice'];
    return this;
  }

  static OrderItem fromMapStatic(Map<String, dynamic> map) {
    return OrderItem(
      map['totalPrice'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPrice': totalPrice,
    };
  }

  OrderItem(this.totalPrice, {this.id, this.createAt});
}

class OrderProvider {
  late Database? db = null;
  String tableName = 'orders';
  String dbName = 'pos.db';
  Future open() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + dbName;
    db = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
          create table $tableName ( 
            id integer primary key autoincrement, 
            totalPrice real not null,
            createAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
          ''');
    });
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            totalPrice real not null,
            createAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    return OrderItem(
      map['totalPrice'],
      id: map['id'],
      createAt: DateTime.parse(map['createAt']),
    );
  }

  Future<List<OrderItem>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<OrderItem> items = [];
    for (var map in maps) {
      items.add(OrderItem(
        map['totalPrice'],
        id: map['id'],
        createAt: DateTime.parse(map['createAt']),
      ));
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
