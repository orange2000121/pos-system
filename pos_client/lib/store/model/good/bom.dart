import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class Bom {
  int? id;
  int productId;
  int materialId;
  double quantity;
  String? note;
  DateTime createdAt;

  Bom({
    this.id,
    required this.productId,
    required this.materialId,
    required this.quantity,
    this.note,
    required this.createdAt,
  });
  factory Bom.fromJson(Map<String, dynamic> json) {
    return Bom(
      id: json['id'],
      productId: json['productId'],
      materialId: json['materialId'],
      quantity: json['quantity'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null && id != 0) 'id': id,
      'productId': productId,
      'materialId': materialId,
      'quantity': quantity,
      'note': note ?? '',
      'createdAt': createdAt.toString(),
    };
  }
}

class BomProvider extends DatabaseHandler {
  String tableName = 'bom';

  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            productId integer not null,
            materialId integer not null,
            quantity real not null,
            note text,
            createdAt text not null
          )
          ''');
    return db!;
  }

  Future<int> insert(Bom bom) async {
    db ??= await open();
    return await db!.insert(tableName, bom.toMap());
  }

  Future<List<Bom>?> getItemsByProductId(int productId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'productId = ?', whereArgs: [productId]);
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) {
      return Bom.fromJson(maps[i]);
    });
  }

  Future update(Bom bom) async {
    db ??= await open();
    return db!.update(tableName, bom.toMap(), where: 'id = ?', whereArgs: [bom.id!]);
  }

  Future delete(int id) async {
    db ??= await open();
    return db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future deleteByProductId(int productId) async {
    db ??= await open();
    return db!.delete(tableName, where: 'productId = ?', whereArgs: [productId]);
  }
}
