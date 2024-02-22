import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/restock.dart';
import 'package:pos/store/model/restock/restock_order.dart';
import 'package:pos/store/model/restock/vendor.dart';
import 'package:pos/template/small_item_card.dart';
import 'package:pos/template/date_picker.dart';

class RestockHistory extends StatefulWidget {
  const RestockHistory({super.key});

  @override
  State<RestockHistory> createState() => _RestockHistoryState();
}

class _RestockHistoryState extends State<RestockHistory> {
  final ValueNotifier<DateTime?> startDateNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> endDateNotifier = ValueNotifier(null);
  final RestockOrderProvider restockOrderProvider = RestockOrderProvider();
  final RestockProvider restockProvider = RestockProvider();
  final PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  Future<Map<int, PurchasedItem>> purchasedItems = Future.value({});
  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    startDateNotifier.value = DateTime(now.year, now.month, 1);
    endDateNotifier.value = DateTime(now.year, now.month + 1, 0);
    purchasedItems = getPurchasedItemsToMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('進貨總覽')),
      body: Column(children: [
        filterBar(
          startDateNotifier: startDateNotifier,
          endDateNotifier: endDateNotifier,
          onChanged: () {
            setState(() {});
          },
        ),
        Expanded(
          child: FutureBuilder(
              future: restockOrderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime.now(), endDateNotifier.value ?? DateTime.now()),
              builder: (context, restockOrdersSnapshot) {
                if (!restockOrdersSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: restockOrdersSnapshot.data!.length,
                  itemBuilder: (context, index) {
                    RestockOrder order = restockOrdersSnapshot.data![index];
                    return FutureBuilder(
                        future: restockProvider.getAllByRestockOrderId(order.id!),
                        builder: (context, AsyncSnapshot<List<Restock>> restocksSnapshot) {
                          return SimplAndDetailInfoCard(
                            title: Text('訂單時間  ${order.date.toString().split('.')[0]}'),
                            subtitle: [
                              Text('總金額：${order.total}'),
                            ],
                            simpleInfo: [
                              FutureBuilder(
                                  future: VendorProvider().getItem(order.vendorId),
                                  builder: (context, AsyncSnapshot<Vendor> vendorSnapshot) {
                                    return Text('訂購廠商：${vendorSnapshot.hasData ? vendorSnapshot.data!.name : '未知廠商'}');
                                  }),
                              Text('備註：${order.note}'),
                            ],
                            detailedInfo: [
                              const Row(
                                children: [
                                  Expanded(flex: 2, child: Text('商品名稱')),
                                  Expanded(flex: 1, child: Text('數量')),
                                  Expanded(flex: 1, child: Text('單價')),
                                  Expanded(flex: 1, child: Text('總價')),
                                  Expanded(flex: 4, child: Text('備註')),
                                ],
                              ),
                              restocksSnapshot.hasData
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: restocksSnapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        Restock restock = restocksSnapshot.data![index];
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: FutureBuilder(
                                                    future: purchasedItems,
                                                    builder: (context, AsyncSnapshot<Map<int, PurchasedItem>> purchasedItemsSnapshot) {
                                                      if (!purchasedItemsSnapshot.hasData) {
                                                        return const SizedBox();
                                                      }
                                                      return Text('${purchasedItemsSnapshot.data![restock.purchasedItemId]?.name ?? restock.purchasedItemId}');
                                                    },
                                                  ),
                                                ),
                                                Expanded(flex: 1, child: Text('${restock.quantity}')),
                                                Expanded(flex: 1, child: Text('${restock.price}')),
                                                Expanded(flex: 1, child: Text('${restock.amount}')),
                                                Expanded(flex: 4, child: Text(restock.note ?? '')),
                                              ],
                                            ),
                                            const Divider(),
                                          ],
                                        );
                                      })
                                  : const Center(child: CircularProgressIndicator()),
                            ],
                            dialogAction: [
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('刪除確認'),
                                          content: const Text('確定要刪除此筆進貨紀錄嗎？'),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                await restockOrderProvider.delete(order.id!);
                                                if (!context.mounted) return;
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                                setState(() {});
                                              },
                                              child: const Text('確定'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('取消'),
                                            ),
                                          ],
                                        );
                                      });
                                },
                                child: const Text('刪除'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('關閉'),
                              ),
                            ],
                          );
                        });
                  },
                );
              }),
        ),
      ]),
    );
  }
  /* -------------------------------------------------------------------------- */
  /*                                   WIDGET                                   */
  /* -------------------------------------------------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  Function                                  */
  /* -------------------------------------------------------------------------- */
  Future<Map<int, PurchasedItem>> getPurchasedItemsToMap() async {
    var purchasedItems = await purchasedItemProvider.queryAll();
    return {for (var purchasedItem in purchasedItems) purchasedItem.id!: purchasedItem};
  }
}
