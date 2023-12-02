import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:pos/store/model/goods.dart';
import 'package:pos/tool/upgrade_app.dart';
import 'package:pos/view/cashier.dart';
import 'package:pos/view/create_product.dart';
import 'package:pos/view/order_overview.dart';
import 'package:pos/view/setting.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void showUpgrade() async {
    UpgradeApp upgradeAppHelper = UpgradeApp();
    if (await upgradeAppHelper.isNeedUpgrade() == false) return;
    if (await upgradeAppHelper.isUpgradeExeExist() == false) return;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('更新'),
          content: const Text('請更新至最新版本'),
          actions: [
            ElevatedButton(
              onPressed: () {
                upgradeAppHelper.upgradeApp(executeSetup: true);
                Navigator.pop(context);
              },
              child: const Text('更新'),
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消更新', style: TextStyle(color: Colors.red)))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    showUpgrade();
    return Scaffold(
      appBar: AppBar(title: const Text('POS系統')),
      body: GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
        ),
        children: [
          Card(
            child: SizedBox(
              child: InkWell(
                onTap: () {
                  CashierInit(context).init();
                },
                child: const Column(
                  children: [
                    Icon(Icons.attach_money),
                    Text('收銀台'),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: SizedBox(
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateProduct()));
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
          // Card(
          //   child: InkWell(
          //     onTap: () {
          //       Navigator.push(context, MaterialPageRoute(builder: (context) => AddItem(item: InventoryItem('', 0), itemProvider: InventoryProvider(), title: '庫存')));
          //     },
          //     child: const Column(
          //       children: [
          //         Icon(Icons.add),
          //         Text('庫存'),
          //       ],
          //     ),
          //   ),
          // ),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderOverview()));
              },
              child: const Column(
                children: [
                  Icon(Icons.history),
                  Text('銷售紀錄'),
                ],
              ),
            ),
          ),
          // Card(
          //   child: InkWell(
          //     onTap: () {
          //       Navigator.push(context, MaterialPageRoute(builder: (context) => const Receipt()));
          //     },
          //     child: const Column(
          //       children: [
          //         Icon(Icons.local_shipping_outlined),
          //         Text('開立收據'),
          //       ],
          //     ),
          //   ),
          // ),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Setting()));
              },
              child: const Column(
                children: [
                  Icon(Icons.settings),
                  Text('設定'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
