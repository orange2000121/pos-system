import 'package:sqflite/sqflite.dart';

///廠商，包含廠商編號、廠商名稱、廠商地址、廠商電話、廠商傳真、廠商聯絡人、廠商聯絡人電話、廠商聯絡人Email、廠商狀態、備註

class Vendor {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String fax;
  final String contactPerson;
  final String contactPersonPhone;
  final String contactPersonEmail;
  final String status;
  final String? note;

  Vendor({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.fax,
    required this.contactPerson,
    required this.contactPersonPhone,
    required this.contactPersonEmail,
    required this.status,
    this.note,
  });
  factory Vendor.initial() {
    return Vendor(
      id: 0,
      name: '',
      address: '',
      phone: '',
      fax: '',
      contactPerson: '',
      contactPersonPhone: '',
      contactPersonEmail: '',
      status: '',
      note: '',
    );
  }
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      fax: json['fax'],
      contactPerson: json['contactPerson'],
      contactPersonPhone: json['contactPersonPhone'],
      contactPersonEmail: json['contactPersonEmail'],
      status: json['status'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'fax': fax,
      'contactPerson': contactPerson,
      'contactPersonPhone': contactPersonPhone,
      'contactPersonEmail': contactPersonEmail,
      'status': status,
      if (note != null) 'note': note,
    };
  }

  static Vendor empty() {
    return Vendor(
      name: '',
      address: '',
      phone: '',
      fax: '',
      contactPerson: '',
      contactPersonPhone: '',
      contactPersonEmail: '',
      status: '',
    );
  }
}

class VendorProvider {
  // ignore: avoid_init_to_null
  late Database? db = null;
  String tableName = 'vendor';
  String dbName = 'pos.db';
  Future open() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + dbName;
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          create table $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            address text not null,
            phone text not null,
            fax text not null,
            contactPerson text not null,
            contactPersonPhone text not null,
            contactPersonEmail text not null,
            status text not null,
            note text
          )
          ''');
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    await db!.execute('''
          create table if not exists $tableName ( 
            id integer primary key autoincrement, 
            name text not null,
            address text not null,
            phone text not null,
            fax text not null,
            contactPerson text not null,
            contactPersonPhone text not null,
            contactPersonEmail text not null,
            status text not null,
            note text
          )
          ''');
    return db;
  }

  Future<int> insert(Vendor item) async {
    db ??= await open();
    int id = await db!.insert(tableName, item.toMap());
    return id;
  }

  Future<Vendor> getItem(int id) async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    return Vendor.fromJson(maps.first);
  }

  Future<List<Vendor>> getAll() async {
    db ??= await open();
    List<Map<String, dynamic>> maps = await db!.query(tableName);
    List<Vendor> items = [];
    for (var map in maps) {
      items.add(Vendor.fromJson(map));
    }
    return items;
  }

  Future update(int id, Vendor item) async {
    db ??= await open();
    await db!.update(tableName, item.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future delete(int id) async {
    db ??= await open();
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
