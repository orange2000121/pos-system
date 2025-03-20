import 'dart:math';

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
          data: List.generate(
            20,
            (index) => SaleItemData(
              id: '00$index',
              name: '商品$index',
              num: Random().nextInt(10),
              price: Random().nextInt(1000),
              unit: '組',
              note: '',
            ),
          )),
    );
  }
}
