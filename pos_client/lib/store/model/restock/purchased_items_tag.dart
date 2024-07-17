import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

/// 進貨品項標籤，包含標籤編號、標籤名稱、標籤顏色

class PurchasedItemsTag {
  final int? id;
  final String name;
  final int color;

  PurchasedItemsTag({
    this.id,
    required this.name,
    required this.color,
  });

  factory PurchasedItemsTag.fromJson(Map<String, dynamic> json) {
    return PurchasedItemsTag(
      id: json['id'],
      name: json['name'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }
}

class PurchasedItemsTagProvider extends DatabaseHandler {
  String tableName = 'purchased_items_tag';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            color integer
          )
          ''');
    return db!;
  }

  Future<int> insert(PurchasedItemsTag item) async {
    db ??= await open();
    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future<PurchasedItemsTag> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return PurchasedItemsTag.fromJson(maps.first);
  }

  Future<PurchasedItemsTag?> getItemByName(String name) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'name = ?', whereArgs: [name]);
    if (maps.isEmpty) {
      return null;
    }
    return PurchasedItemsTag.fromJson(maps.first);
  }

  Future<List<PurchasedItemsTag>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<PurchasedItemsTag> items = [];
    for (var map in maps) {
      items.add(PurchasedItemsTag.fromJson(map));
    }
    return items;
  }

  Future update(PurchasedItemsTag item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
