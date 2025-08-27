import 'package:flutter/material.dart';
import 'package:pos/logic/restock/purchased_logic.dart';
import 'package:pos/store/model/good/inventory.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/restock.dart';
import 'package:pos/store/model/restock/restock_order.dart';
import 'package:pos/store/model/restock/vendor.dart';
import 'package:pos/template/charts/pie_chart_and_detail.dart';
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
  final InventoryProvider inventoryProvider = InventoryProvider();
  final PurchasedLogic purchasedLogic = PurchasedLogic();
  ValueNotifier<Map<int, PurchasedItemAndGood>> purchasedItemsNotifier = ValueNotifier({}); //Map<purchasedItemId, PurchasedItem>
  ValueNotifier<List<RestockOrder>> restockOrdersNotifier = ValueNotifier([]);
  ValueNotifier<Map<int, List<Restock>>> allRestocksNotifier = ValueNotifier({}); //Map<restockOrderId, List<Restock>>
  ValueNotifier<Map<int, Vendor>> vendorsNotifier = ValueNotifier({}); //Map<vendorId, Vendor>

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    startDateNotifier.value = DateTime(now.year, now.month, 1);
    endDateNotifier.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    asyncInit();
  }

  @override
  Widget build(BuildContext context) {
    getRestockData();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('進貨總覽'),
        flexibleSpace: Center(
          child: filterBar(
            startDateNotifier: startDateNotifier,
            endDateNotifier: endDateNotifier,
            onChanged: () {
              setState(() {});
            },
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //   crossAxisCount: 2,
            // ),
            children: [
              Wrap(children: [
                vendorPieChart(),
                purchasePieChart(),
              ])
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
              valueListenable: restockOrdersNotifier,
              // future: restockOrderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime.now(), endDateNotifier.value ?? DateTime.now()),
              builder: (context, restockOrders, child) {
                return ListView.builder(
                  itemCount: restockOrders.length,
                  itemBuilder: (context, index) {
                    RestockOrder order = restockOrders[index];
                    return ValueListenableBuilder(
                        valueListenable: allRestocksNotifier,
                        // future: restockProvider.getAllByRestockOrderId(order.id!),
                        builder: (context, allRestocks, child) {
                          List<Restock> restocks = allRestocks[order.id!] ?? [];
                          return SimplAndDetailInfoCard(
                            title: Text('訂單時間  ${order.date.toString().split('.')[0]}'),
                            subtitle: [
                              Text('總金額：${order.total}'),
                            ],
                            simpleInfo: [
                              ValueListenableBuilder(
                                  valueListenable: vendorsNotifier,
                                  builder: (context, vendors, child) {
                                    return Text('訂購廠商：${vendors[order.vendorId]?.name ?? '未知廠商'}');
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
                              allRestocksNotifier.value.isNotEmpty
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: restocks.length,
                                      itemBuilder: (context, index) {
                                        Restock restock = restocks[index];
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: ValueListenableBuilder(
                                                    valueListenable: purchasedItemsNotifier,
                                                    builder: (context, purchasedItems, child) {
                                                      if (purchasedItems.isEmpty) {
                                                        return const SizedBox();
                                                      }
                                                      return Text(purchasedItems[restock.goodId]?.name ?? '已刪除貨物');
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
                                                for (Restock restock in restocks) {
                                                  await restockProvider.delete(restock.id!);
                                                  Inventory? inventory = await inventoryProvider.getInventoryByGoodId(restock.goodId);
                                                  if (inventory == null) continue;
                                                  inventory.quantity -= restock.quantity;
                                                  await inventoryProvider.update(inventory, mode: Inventory.COMPUTE_MODE);
                                                }

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
  Widget vendorPieChart() {
    return ValueListenableBuilder(
        valueListenable: restockOrdersNotifier,
        builder: (context, restockOrders, child) {
          return ValueListenableBuilder(
              valueListenable: vendorsNotifier,
              builder: (context, vendors, child) {
                if (restockOrders.isEmpty || vendors.isEmpty) {
                  return const SizedBox();
                }
                Map<String, double> vendorTotal = {};
                for (RestockOrder restockOrder in restockOrders) {
                  vendorTotal[vendors[restockOrder.vendorId]?.name ?? '未知廠商'] = (vendorTotal[vendors[restockOrder.vendorId]?.name ?? '未知廠商'] ?? 0) + restockOrder.total;
                }

                return PieChartAndDetail(title: '廠商', itemNames: vendorTotal.keys.toList(), itemValues: vendorTotal.values.toList());
              });
        });
  }

  Widget purchasePieChart() {
    return ValueListenableBuilder(
        valueListenable: allRestocksNotifier,
        builder: (context, allRestocks, child) {
          return ValueListenableBuilder(
              valueListenable: purchasedItemsNotifier,
              builder: (context, purchasedItem, child) {
                if (allRestocks.isEmpty || purchasedItem.isEmpty) {
                  return const SizedBox();
                }
                Map<String, double> purchaseTotal = {};
                for (List<Restock> restocks in allRestocks.values.toList()) {
                  for (Restock restock in restocks) {
                    purchaseTotal[purchasedItem[restock.goodId]?.name ?? '已刪除貨物'] = (purchaseTotal[purchasedItem[restock.goodId]?.name ?? '已刪除貨物'] ?? 0) + restock.amount;
                  }
                }

                return PieChartAndDetail(
                  title: '進貨',
                  itemNames: purchaseTotal.keys.toList(),
                  itemValues: purchaseTotal.values.toList(),
                  showPercentages: true,
                );
              });
        });
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Function                                  */
  /* -------------------------------------------------------------------------- */
  void asyncInit() async {
    var purchasedItems = await purchasedItemProvider.queryAll();
    var convertedItems = await purchasedLogic.convertPurchasedItems2PurchasedItemAndGoods(purchasedItems);
    purchasedItemsNotifier.value = {for (var purchasedItem in convertedItems) purchasedItem.goodId: purchasedItem};
    vendorsNotifier.value = {for (var vendor in await VendorProvider().getAll()) vendor.id!: vendor};
  }

  void getRestockData() async {
    restockOrdersNotifier.value = await restockOrderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime.now(), endDateNotifier.value ?? DateTime.now());
    var restocksTemp = <int, List<Restock>>{};
    for (RestockOrder restockOrder in restockOrdersNotifier.value) {
      restocksTemp[restockOrder.id!] = await restockProvider.getAllByRestockOrderId(restockOrder.id!);
    }
    allRestocksNotifier.value = restocksTemp;
  }
}
