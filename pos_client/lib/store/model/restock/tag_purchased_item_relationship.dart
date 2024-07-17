import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class TagPurchasedItemRelationship {
  int? id;
  int tagId;
  int purchasedItemId;

  TagPurchasedItemRelationship({
    required this.tagId,
    required this.purchasedItemId,
    this.id,
  });

  factory TagPurchasedItemRelationship.fromMap(Map<String, dynamic> map) {
    return TagPurchasedItemRelationship(
      tagId: map['tag_id'] as int,
      purchasedItemId: map['purchased_item_id'] as int,
      id: map['id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tag_id': tagId,
      'purchased_item_id': purchasedItemId,
    };
  }
}

class TagPurchasedItemRelationshipProvider extends DatabaseHandler {
  String tableName = 'tag_purchased_item_relationship';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement,
            tag_id integer not null,
            purchased_item_id integer not null
          )
          ''');
    return db!;
  }

  Future<int> insert(TagPurchasedItemRelationship item) async {
    db ??= await open();
    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future<TagPurchasedItemRelationship> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return TagPurchasedItemRelationship.fromMap(maps.first);
  }

  Future<List<TagPurchasedItemRelationship>> getItemsByTagId(int tagId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'tag_id = ?', whereArgs: [tagId]);
    List<TagPurchasedItemRelationship> items = [];
    for (var map in maps) {
      items.add(TagPurchasedItemRelationship.fromMap(map));
    }
    return items;
  }

  Future<List<TagPurchasedItemRelationship>> getItemsByPurchasedItemId(int purchasedItemId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'purchased_item_id = ?', whereArgs: [purchasedItemId]);
    List<TagPurchasedItemRelationship> items = [];
    for (var map in maps) {
      items.add(TagPurchasedItemRelationship.fromMap(map));
    }
    return items;
  }

  Future<List<TagPurchasedItemRelationship>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<TagPurchasedItemRelationship> items = [];
    for (var map in maps) {
      items.add(TagPurchasedItemRelationship.fromMap(map));
    }
    return items;
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
