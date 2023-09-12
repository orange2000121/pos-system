import 'package:flutter/material.dart';
import 'package:pos/template/goods.dart';

class Receipt extends StatefulWidget {
  const Receipt({super.key});

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  @override
  Widget build(BuildContext context) {
    GoodsTemplate choseGoods = GoodsTemplate(context: context);
    return Scaffold(
      appBar: AppBar(title: const Text('開立收據')),
      body: Row(children: [
        const Expanded(child: Placeholder()),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              choseGoods.groupList(),
              const Divider(),
              choseGoods.goodsList(),
            ],
          ),
        ),
      ]),
    );
  }
}
