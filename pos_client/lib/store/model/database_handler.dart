import 'dart:async';

import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/sell/good_providers/goods.dart';
import 'package:sqflite/sqflite.dart';

abstract class DatabaseHandler {
  Database? db;
  DatabaseHandler();
  Future<Database> open() async {
    String dbName = 'pos.db';
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + dbName;
    db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) => _onCreate(db, version),
      onUpgrade: (db, oldVersion, newVersion) => _onUpgrade(db, oldVersion, newVersion),
    );
    return db!;
  }

  Future _onCreate(Database db, int version) async {}

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion; version < newVersion; version++) {
      switch (version) {
        case 1:
          // 新增 amount 欄位，在 GoodsProvider 和 PurchasedItemProvider 中
          print('update database case 1');
          if (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='${GoodsProvider().tableName}';").then((value) => value.isNotEmpty)) {
            if (!await columnExists(db, GoodsProvider().tableName, 'amount')) {
              await db.execute("ALTER TABLE ${GoodsProvider().tableName} ADD COLUMN amount real not null DEFAULT 0;");
            }
          }

          if (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='${PurchasedItemProvider().tableName}';").then((value) => value.isNotEmpty)) {
            if (!await columnExists(db, PurchasedItemProvider().tableName, 'amount')) {
              await db.execute("ALTER TABLE ${PurchasedItemProvider().tableName} ADD COLUMN amount real not null DEFAULT 0;");
            }
          }
          break;
        case 2:
          // 假設 restock 表的名稱是 restockTableName
          print('update database case 2');
          String restockTableName = "restock";
          String tempTableName = "temp_restock";
          if (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$restockTableName';").then((value) => value.isEmpty)) {
            break;
          }
          // 1. 創建一個新的臨時表
          await db.execute("""
          CREATE TABLE $tempTableName (
            id integer primary key autoincrement, 
            restockOrderId integer not null,
            purchasedItemId integer not null,
            quantity real not null,
            price real not null,
            amount real not null,
            restockDate TIMESTAMP not null,
            note text
          );
        """);

          // 2. 將原表的數據轉移到新的臨時表中
          await db.execute("""
            INSERT INTO $tempTableName (id, restockOrderId, purchasedItemId, quantity, price, amount, restockDate, note)
            SELECT id, restockOrderId, purchasedItemId, CAST(quantity AS REAL), price, amount, restockDate, note
            FROM $restockTableName;
          """);

          // 3. 刪除原表
          await db.execute("DROP TABLE $restockTableName;");

          // 4. 將臨時表重命名為原表的名稱
          await db.execute("ALTER TABLE $tempTableName RENAME TO $restockTableName;");
          break;
      }
    }
  }

  Future<bool> columnExists(Database db, String tableName, String columnName) async {
    var result = await db.rawQuery("PRAGMA table_info($tableName);");
    return result.any((element) => element['name'] == columnName);
  }
}
