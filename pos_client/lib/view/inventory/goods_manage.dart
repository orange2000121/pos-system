import 'package:flutter/material.dart';

class GoodsManage extends StatefulWidget {
  const GoodsManage({super.key});

  @override
  State<GoodsManage> createState() => _GoodsManageState();
}

class _GoodsManageState extends State<GoodsManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('商品管理'),
      ),
      body: Center(
        child: Text('商品管理頁面'),
      ),
    );
  }
}
