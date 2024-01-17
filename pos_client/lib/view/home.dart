import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:pos/store/model/sell/goods.dart';
import 'package:pos/tool/upgrade_app.dart';
import 'package:pos/view/restock/restock_view.dart';
import 'package:pos/view/restock/vendor_manage.dart';
import 'package:pos/view/sell/cashier.dart';
import 'package:pos/view/sell/create_product.dart';
import 'package:pos/view/sell/order_overview.dart';
import 'package:pos/view/restock/purchased_items_manage.dart';
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
          entryCard(
            context,
            title: '商品',
            icon: const Icon(Icons.add),
            page: const CreateProduct(),
          ),
          entryCard(
            context,
            title: '銷售紀錄',
            icon: const Icon(Icons.history),
            page: const OrderOverview(),
          ),
          entryCard(
            context,
            title: '進貨',
            icon: const Icon(Icons.trolley),
            page: const RestockView(),
          ),
          entryCard(
            context,
            title: '貨物管理',
            icon: const Icon(Icons.trolley),
            page: const PurchasedItemsManage(),
          ),
          entryCard(
            context,
            title: '廠商管理',
            icon: const Icon(Icons.factory),
            page: const VendorManage(),
          ),
          entryCard(
            context,
            title: '設定',
            icon: const Icon(Icons.settings),
            page: const Setting(),
          ),
        ],
      ),
    );
  }

  Card entryCard(BuildContext context, {required String title, required Widget icon, required Widget page}) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
        child: Column(
          children: [
            icon,
            Text(title),
          ],
        ),
      ),
    );
  }
}
