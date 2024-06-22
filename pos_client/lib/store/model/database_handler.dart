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
      version: 2,
      onCreate: (db, version) => _onCreate(db, version),
      onUpgrade: (db, oldVersion, newVersion) => _onUpgrade(db, oldVersion, newVersion),
    );
    return db!;
  }

  Future _onCreate(Database db, int version) async {
    print('on create');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('on upgrade');
    for (int version = oldVersion; version < newVersion; version++) {
      switch (version) {
        case 1:
          await db.execute("ALTER TABLE ${GoodsProvider().tableName} ADD COLUMN amount real not null DEFAULT 0;");
          await db.execute("ALTER TABLE ${PurchasedItemProvider().tableName} ADD COLUMN amount real not null DEFAULT 0;");
          break;
      }
    }
  }
}
