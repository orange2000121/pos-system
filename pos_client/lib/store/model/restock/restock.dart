import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

/// 進貨明細，包含明細編號、進貨單邊號、品項編號、進貨數量、進貨單價、進貨金額、進貨日期、備註
class Restock {
  int? id;
  int? restockOrderId;
  int purchasedItemId;
  double quantity;
  double price;
  double amount;
  DateTime restockDate;
  String? note;

  /// 進貨明細，包含明細編號、進貨單邊號、品項編號、進貨數量、進貨單價、進貨金額、進貨日期、備註
  Restock({
    this.id,
    this.restockOrderId,
    required this.purchasedItemId,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.restockDate,
    this.note,
  });

  factory Restock.fromJson(Map<String, dynamic> json) {
    return Restock(
      id: json['id'],
      restockOrderId: json['restockOrderId'],
      purchasedItemId: json['purchasedItemId'],
      quantity: json['quantity'],
      price: json['price'],
      amount: json['amount'],
      restockDate: DateTime.parse(json['restockDate']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'restockOrderId': restockOrderId,
      'purchasedItemId': purchasedItemId,
      'quantity': quantity,
      'price': price,
      'amount': amount,
      'restockDate': restockDate.toString(),
      if (note != null) 'note': note,
    };
  }
}

class RestockProvider extends DatabaseHandler {
  String tableName = 'restock';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            restockOrderId integer not null,
            purchasedItemId integer not null,
            quantity real not null,
            price real not null,
            amount real not null,
            restockDate TIMESTAMP not null,
            note text
          )
          ''');
    return db!;
  }

  Future<int> insert(Restock restock) async {
    db ??= await open();
    int result = await db!.insert(tableName, restock.toMap());
    return result;
  }

  Future<Restock?> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return Restock.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Restock>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<Restock> result = [];
    for (var map in maps) {
      result.add(Restock.fromJson(map));
    }
    return result;
  }

  Future<List<Restock>> getAllByRestockOrderId(int restockOrderId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'restockOrderId = ?', whereArgs: [restockOrderId]);
    List<Restock> result = [];
    for (var map in maps) {
      result.add(Restock.fromJson(map));
    }
    return result;
  }

  Future update(int id, Restock restock) async {
    db ??= await open();
    await db!.update(tableName, restock.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
