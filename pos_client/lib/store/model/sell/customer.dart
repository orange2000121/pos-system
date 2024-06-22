/// 顧客資料，包含名稱、電話、聯絡人、地址

import 'package:flutter/material.dart';
import 'package:pos/store/model/database_handler.dart';
import 'package:sqflite/sqflite.dart';

class Customer {
  late int? id;
  String name;
  String phone;
  String contactPerson;
  String address;
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'contactPerson': contactPerson,
      'address': address,
    };
  }

  static Customer fromMapStatic(Map<String, dynamic> map) {
    return Customer(
      map['name'],
      map['phone'],
      map['contactPerson'],
      map['address'],
      id: map['id'],
    );
  }

  Customer fromMap(Map<String, dynamic> map) {
    return Customer(
      map['name'],
      map['phone'],
      map['contactPerson'],
      map['address'],
      id: map['id'],
    );
  }

  Customer copy() {
    return Customer(name, phone, contactPerson, address, id: id);
  }

  Customer(this.name, this.phone, this.contactPerson, this.address, {this.id});
}

class CustomerProvider extends DatabaseHandler {
  String tableName = 'customer';
  @override
  Future<Database> open() async {
    db = await super.open();
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            phone text not null,
            contactPerson text not null,
            address text not null,
            createAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
          ''');
    return db!;
  }

  Future<Customer> insert(Customer item) async {
    db ??= await open();
    int newid = await db!.insert(tableName, item.toMap());
    item.id = newid;
    return item;
  }

  Future update(int id, Customer item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future<Customer> getItem(int? id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return Customer.fromMapStatic(maps.first);
  }

  Future<List<Customer>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<Customer> items = [];
    for (var map in maps) {
      try {
        items.add(Customer.fromMapStatic(map));
        // ignore: empty_catches
      } catch (e) {}
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

  Future<bool> isExist(String name) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'name = ?', whereArgs: [name]);
    return maps.isNotEmpty;
  }

  Future close() async => db!.close();
}
