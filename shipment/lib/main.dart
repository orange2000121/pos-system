import 'package:flutter/material.dart';
import 'package:shipment/sample.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ReceiptSample(
        userName: '一朵花',
        customName: '中正店',
        phone: '0908811233',
        contactPerson: '許子霆',
        address: '中正路',
        data: [
          SaleItemData(id: '001', name: '湯包', num: 10, price: 500, unit: '組', note: ''),
          SaleItemData(id: '002', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '003', name: '四顆裝梅餅', num: 20, price: 50, unit: '包', note: ''),
          SaleItemData(id: '004', name: '單顆梅餅', num: 50, price: 15, unit: '顆', note: ''),
          SaleItemData(id: '005', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '006', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '007', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '008', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '009', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '010', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '011', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
          SaleItemData(id: '012', name: '大吸管', num: 3, price: 200, unit: '包', note: ''),
        ],
      ),
    );
  }
}
