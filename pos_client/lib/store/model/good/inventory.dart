// ignore_for_file: constant_identifier_names
// 用於紀錄庫存量的資料表

import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class Inventory {
  final int goodId;
  double quantity;
  String recodeMode;
  DateTime recordTime;

  static const String CREATE_MODE = 'create';
  static const String MANUAL_MODE = 'manual';
  static const String COMPUTE_MODE = 'compute';

  Inventory({
    required this.goodId,
    required this.quantity,
    required this.recodeMode,
    required this.recordTime,
  });
  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      goodId: json['good_id'],
      quantity: json['quantity'],
      recodeMode: json['recode_mode'],
      recordTime: DateTime.parse(json['record_time']),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'good_id': goodId,
      'quantity': quantity,
      'recode_mode': recodeMode,
      'record_time': recordTime.toString(),
    };
  }
}

class InventoryProvider extends DatabaseHandler {
  static const String tableName = 'inventory';

  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            good_id integer primary key,
            quantity real not null,
            recode_mode text not null,
            record_time text not null
          )
          ''');
    return db!;
  }

  Future<List<Inventory>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    return maps.map((e) => Inventory.fromJson(e)).toList();
  }

  Future<int> insert(Inventory inventory) async {
    db ??= await open();
    inventory.recodeMode = Inventory.CREATE_MODE;
    inventory.recordTime = DateTime.now();
    return await db!.insert(tableName, inventory.toMap());
  }

  Future<Inventory?> getInventoryByGoodId(int goodId) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'good_id = ?', whereArgs: [goodId]);
    if (maps.isEmpty) return null;
    return Inventory.fromJson(maps.first);
  }

  Future<int?> delete(int id) async {
    db ??= await open();
    return await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future update(Inventory inventory, {required String mode}) async {
    db ??= await open();
    inventory.recodeMode = mode;
    inventory.recordTime = DateTime.now();
    return await db!.update(tableName, inventory.toMap(), where: 'good_id = ?', whereArgs: [inventory.goodId]);
  }

  ///比較原有商品與新商品的庫存變化，並且更新庫存<br>
  ///@param originalGoods 原有商品的庫存，key為貨物ID，value為原有訂單的數量 <br>
  ///@param newGoods 新商品的庫存，key為貨物ID，value為修改後訂的數量
  @Deprecated('use updateWithNewOldOrder instead')
  void compareNewOldOrder({required Map<int, double> originalGoods, required Map<int, double> newGoods}) async {
    updateWithNewOldOrder(originalGoods: originalGoods, newGoods: newGoods);
  }

  ///比較原有商品與新商品的庫存變化，並且更新庫存<br>
  ///@param originalGoods 原有商品的庫存，key為貨物ID，value為原有訂單的數量 <br>
  ///@param newGoods 新商品的庫存，key為貨物ID，value為修改後訂的數量
  void updateWithNewOldOrder({required Map<int, double> originalGoods, required Map<int, double> newGoods}) async {
    //比較原有商品與新商品的庫存變化
    for (var item in newGoods.entries) {
      int key = item.key;
      double value = item.value;
      if (originalGoods.containsKey(key)) {
        double changeQuantity = value - originalGoods[key]!;
        if (changeQuantity != 0) {
          Inventory? inventory = await getInventoryByGoodId(key);
          if (inventory != null) {
            inventory.quantity = inventory.quantity - changeQuantity;
            await update(inventory, mode: Inventory.COMPUTE_MODE);
          } else {
            insert(Inventory(goodId: key, quantity: changeQuantity, recodeMode: Inventory.CREATE_MODE, recordTime: DateTime.now()));
          }
        }
        originalGoods.remove(key);
      } else {
        //如果新商品中有原有商品沒有的商品，則新增庫存
        Inventory? inventory = await getInventoryByGoodId(key);
        if (inventory != null) {
          inventory.quantity -= value;
          await update(inventory, mode: Inventory.COMPUTE_MODE);
        } else {
          await insert(Inventory(goodId: key, quantity: value, recodeMode: Inventory.CREATE_MODE, recordTime: DateTime.now()));
        }
      }
    }
    //將剩下的原有商品加回庫存
    for (var item in originalGoods.entries) {
      int key = item.key;
      double value = item.value;
      Inventory? inventory = await getInventoryByGoodId(key);
      if (inventory != null) {
        inventory.quantity += value;
        await update(inventory, mode: Inventory.COMPUTE_MODE);
      } else {
        await insert(Inventory(goodId: key, quantity: value, recodeMode: Inventory.CREATE_MODE, recordTime: DateTime.now()));
      }
    }
  }
}
