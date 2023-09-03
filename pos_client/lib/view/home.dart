import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:pos/model/goods.dart';
import 'package:pos/model/inventory.dart';
import 'package:pos/template/add_item.dart';
import 'package:pos/view/cashier.dart';
import 'package:pos/view/create_product.dart';
import 'package:pos/view/order_history.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        children: [
          Card(
            child: SizedBox(
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Cashier()));
                },
                child: const Column(
                  children: [
                    Icon(Icons.add),
                    Text('cashier'),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: SizedBox(
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProduct()));
                },
                child: const Column(
                  children: [
                    Icon(Icons.add),
                    Text('商品'),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddItem(item: InventoryItem('', 0), itemProvider: InventoryProvider(), title: '庫存')));
              },
              child: const Column(
                children: [
                  Icon(Icons.add),
                  Text('庫存'),
                ],
              ),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistory()));
              },
              child: const Column(
                children: [
                  Icon(Icons.add),
                  Text('銷售紀錄'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
