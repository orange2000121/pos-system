import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/vendor.dart';

class PurchasedItemsManage extends StatefulWidget {
  const PurchasedItemsManage({super.key});

  @override
  State<PurchasedItemsManage> createState() => _PurchasedItemsManageState();
}

class _PurchasedItemsManageState extends State<PurchasedItemsManage> {
  PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('貨物管理'),
      ),
      body: FutureBuilder(
          future: purchasedItemProvider.queryAll(),
          builder: (context, snapshot) {
            return GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
              ),
              children: [
                Card(
                  child: SizedBox(
                    child: InkWell(
                      onTap: () async {
                        PurchasedItem? result = await showDialog(
                          context: context,
                          builder: (context) {
                            return purchasedDetail(context);
                          },
                        );
                        if (result != null && result.name != '') {
                          purchasedItemProvider.insert(result);
                          setState(() {});
                        }
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          Text('新增品項'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (snapshot.hasData)
                  ...snapshot.data!.map((e) {
                    return Card(
                      child: SizedBox(
                        child: InkWell(
                          onTap: () {
                            showDialog(context: context, builder: (context) => purchasedDetail(context, purchasedItem: e)).then((value) {
                              if (value != null) {
                                purchasedItemProvider.update(e.id!, value);
                                setState(() {});
                              }
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('貨物名稱：${e.name}'),
                              Text('進貨單位：${e.unit}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          }),
    );
  }

  AlertDialog purchasedDetail(BuildContext context, {PurchasedItem? purchasedItem}) {
    VendorProvider vendorProvider = VendorProvider();
    ValueNotifier<int> vendorIdNotifier = ValueNotifier(0);
    String name = '';
    String unit = '';
    if (purchasedItem != null) {
      vendorIdNotifier.value = purchasedItem.vendorId;
      name = purchasedItem.name;
      unit = purchasedItem.unit;
    }
    return AlertDialog(
      title: const Text('新增品項'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder(
              future: vendorProvider.getAll(),
              initialData: const [],
              builder: (context, snapshot) {
                if (purchasedItem == null) {
                  vendorIdNotifier.value = snapshot.data!.first.id!;
                }
                return ValueListenableBuilder<int>(
                    valueListenable: vendorIdNotifier,
                    builder: (context, value, child) {
                      return DropdownButton(
                        value: vendorIdNotifier.value,
                        onChanged: (value) {
                          setState(() {
                            vendorIdNotifier.value = value!;
                          });
                        },
                        items: snapshot.data!.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.name),
                          );
                        }).toList(),
                      );
                    });
              }),
          TextFormField(
            decoration: const InputDecoration(
              labelText: '品項名稱',
            ),
            initialValue: name,
            onChanged: (value) => name = value,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: '單位',
            ),
            initialValue: unit,
            onChanged: (value) => unit = value,
          ),
        ],
      ),
      actions: [
        if (purchasedItem != null)
          TextButton(
            onPressed: () {
              setState(() {
                purchasedItemProvider.delete(purchasedItem.id!);
                Navigator.of(context).pop();
              });
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              PurchasedItem(vendorId: vendorIdNotifier.value, name: name, unit: unit),
            );
          },
          child: purchasedItem == null ? const Text('新增') : const Text('修改'),
        ),
      ],
    );
  }
}
