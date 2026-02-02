import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/sell/product_providers/product.dart';
import 'package:sqflite/sqflite.dart';

abstract class DatabaseHandler {
  Database? db;
  DatabaseHandler();
  static Future<String> getDBFilePath() async {
    String dbName = 'pos.db';
    var databasesPath = await getDatabasesPath();
    return p.join(databasesPath, dbName);
  }

  Future<Database> open() async {
    if (db != null) return db!;
    db = await openDatabase(
      await getDBFilePath(),
      version: 5,
      onCreate: (db, version) => _onCreate(db, version),
      onUpgrade: (db, oldVersion, newVersion) async => await _onUpgrade(db, oldVersion, newVersion),
    );
    return db!;
  }

  Future _onCreate(Database db, int version) async {}

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // print('new version $newVersion');
    // print('old version $oldVersion');
    for (int version = oldVersion; version < newVersion; version++) {
      switch (version) {
        case 1:
          // 新增 amount 欄位，在 GoodsProvider 和 PurchasedItemProvider 中
          if (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='${ProductProvider().tableName}';").then((value) => value.isNotEmpty)) {
            if (!await columnExists(db, ProductProvider().tableName, 'amount')) {
              await db.execute("ALTER TABLE ${ProductProvider().tableName} ADD COLUMN amount real not null DEFAULT 0;");
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
        case 3:
          String goodsTableName = "good";
          String productTableName = "product";
          String goodTableName = "good";
          String sellTableName = "sell";
          String restockTableName = "restock";
          String purchaseItemTableName = "purchased_item";
          /* --------------------------- migrate goods to product --------------------------- */
          // 1. goods改名爲old_goods
          await db.execute("ALTER TABLE goods RENAME TO old_$goodsTableName;");
          // 2. 創建新的goods表
          await db.execute('''
              create table if not exists $goodsTableName ( 
                id integer primary key autoincrement, 
                name text not null,
                unit text not null,
                image blob,
                status integer not null DEFAULT 1
              )
              ''');
          // 3. 從old_goods表中插入數據到新產品表
          await db.execute("""
              INSERT INTO $goodsTableName (name, unit, image)
              SELECT name, unit, image
              FROM old_$goodsTableName;
            """);
          // 4. 創建新的product表
          await db.execute('''
          create table if not exists $productTableName (
            name text not null,
            group_id integer not null,
            good_id integer not null,
            price real not null,
            auto_create INTEGER NOT NULL DEFAULT 0,
            foreign key (group_id) references product_group(id) on delete cascade on update cascade)
          ''');
          // 5. 從old_goods表中插入數據到新產品表
          await db.execute("""
              INSERT INTO $productTableName (group_id, good_id, price, name)
              SELECT group_id, id, price, name
              FROM old_$goodsTableName;
          """);
          // 6. 更新product表中的good_id
          await db.execute("""
              UPDATE $productTableName
              SET good_id = (
                SELECT id FROM $goodsTableName
                WHERE $goodsTableName.name = $productTableName.name
                LIMIT 1
              )
              WHERE EXISTS (
                SELECT 1 FROM $goodsTableName
                WHERE $goodsTableName.name = $productTableName.name
              );
            """);
          // 7. 刪除product.name
          await db.execute("ALTER TABLE $productTableName DROP COLUMN name;");
          // 8. 刪除old_goods表
          await db.execute("DROP TABLE old_$goodsTableName;");
          /* -------------------------- migrate restock table ------------------------- */
          // add column name unit
          await db.execute("ALTER TABLE $restockTableName ADD COLUMN name text;");
          await db.execute("ALTER TABLE $restockTableName ADD COLUMN unit text;");
          //update name unit from purchased_item
          await db.execute("""
            UPDATE $restockTableName
            SET name = (
              SELECT name FROM $purchaseItemTableName
              WHERE $purchaseItemTableName.id = $restockTableName.purchasedItemId
              LIMIT 1
            ),
            unit = (
              SELECT unit FROM $purchaseItemTableName
              WHERE $purchaseItemTableName.id = $restockTableName.purchasedItemId
              LIMIT 1
            )
            WHERE EXISTS (
              SELECT 1 FROM $purchaseItemTableName
              WHERE $purchaseItemTableName.id = $restockTableName.purchasedItemId
            );
          """);
          //rename column purchasedItemId
          await db.execute("ALTER TABLE $restockTableName RENAME COLUMN purchasedItemId TO goodId;");
          //update goodId
          await db.execute("""
            UPDATE $restockTableName
            SET goodId = COALESCE((
              SELECT id FROM $goodsTableName
              WHERE $goodsTableName.name = $restockTableName.name AND
              $goodsTableName.unit = $restockTableName.unit
              LIMIT 1
            ), 0)
            WHERE EXISTS (
              SELECT 1 FROM $goodsTableName
              WHERE $goodsTableName.name = $restockTableName.name AND
              $goodsTableName.unit = $restockTableName.unit
            );
          """);
          //drop restock.name restock.unit
          await db.execute("ALTER TABLE $restockTableName DROP COLUMN name;");
          await db.execute("ALTER TABLE $restockTableName DROP COLUMN unit;");
          /* --------------------- purchase item import into good --------------------- */
          // import purchased_item to good
          await db.execute("""
              INSERT INTO $goodTableName (name, unit)
              SELECT name, unit
              FROM $purchaseItemTableName;
          """);
          // 1. purchased_item rename to old_purchased_item
          await db.execute("ALTER TABLE $purchaseItemTableName RENAME TO old_$purchaseItemTableName;");
          // 2. create new purchased_item table
          await db.execute('''
              create table if not exists $purchaseItemTableName ( 
                goodId integer not null,
                vendorId integer not null,
                name text,
                unit text
              )
              ''');
          // 3. insert data from old_purchased_item to new purchased_item
          await db.execute("""
              INSERT INTO $purchaseItemTableName (goodId, vendorId, name, unit)
              SELECT id, vendorId, name, unit
              FROM old_$purchaseItemTableName;
            """);
          // 4. get good id from good
          await db.execute("""
            UPDATE $purchaseItemTableName
            SET goodId = (
              SELECT id FROM $goodsTableName
              WHERE $goodsTableName.name = $purchaseItemTableName.name AND
              $goodsTableName.unit = $purchaseItemTableName.unit
              LIMIT 1
            )
            WHERE EXISTS (
              SELECT 1 FROM $goodsTableName
              WHERE $goodsTableName.name = $purchaseItemTableName.name AND
              $goodsTableName.unit = $purchaseItemTableName.unit
            );
          """);
          // drop purchased_item name unit
          await db.execute("ALTER TABLE $purchaseItemTableName DROP COLUMN name;");
          await db.execute("ALTER TABLE $purchaseItemTableName DROP COLUMN unit;");
          // 4. delete old_purchased_item table
          await db.execute("DROP TABLE old_$purchaseItemTableName;");
          /* ------------------- rename goods_group to product_group ------------------- */
          await db.execute("ALTER TABLE goods_group RENAME TO product_group;");
          /* --------------------------- migrate sell table --------------------------- */
          //drop ice sugar
          await db.execute("ALTER TABLE $sellTableName DROP COLUMN ice;");
          await db.execute("ALTER TABLE $sellTableName DROP COLUMN sugar;");
          //add column goodId
          await db.execute("ALTER TABLE $sellTableName ADD COLUMN goodId INTEGER NOT NULL DEFAULT 0;");
          //update goodId
          await db.execute("""
            UPDATE $sellTableName
            SET goodId = (
              SELECT id FROM good
              WHERE good.name = $sellTableName.name
              LIMIT 1
            )
            WHERE EXISTS (
              SELECT 1 FROM good
              WHERE good.name = $sellTableName.name
            );
          """);
          break;
        case 4:
          /* ---------------- tag_purchased_item_relationship migration --------------- */
          await db.execute("ALTER TABLE tag_purchased_item_relationship ADD COLUMN good_id INTEGER NOT NULL DEFAULT 0;");
          await db.execute("ALTER TABLE tag_purchased_item_relationship DROP COLUMN purchased_item_id;");
          await db.execute("ALTER TABLE product ADD COLUMN status INTEGER NOT NULL DEFAULT 1;");
          await db.execute("ALTER TABLE purchased_item ADD COLUMN status INTEGER NOT NULL DEFAULT 1;");
      }
    }
  }

  Future<bool> columnExists(Database db, String tableName, String columnName) async {
    var result = await db.rawQuery("PRAGMA table_info($tableName);");
    return result.any((element) => element['name'] == columnName);
  }
}
