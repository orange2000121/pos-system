import 'package:flutter/material.dart';
import 'package:pos/logic/restock/purchased_logic.dart';
import 'package:pos/store/model/good/inventory.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/purchased_items_tag.dart';
import 'package:pos/store/model/restock/restock.dart';
import 'package:pos/store/model/restock/restock_order.dart';
import 'package:pos/store/model/restock/tag_purchased_item_relationship.dart';
import 'package:pos/store/model/restock/vendor.dart';
import 'package:pos/store/model/sell/order.dart';
import 'package:pos/template/date_picker.dart';
import 'package:pos/template/number_input_with_increment_decrement.dart';
import 'package:pos/template/product_card.dart';
import 'package:pos/template/tags_grid_view.dart';
import 'package:pos/tool/calculate_text_size.dart';

class RestockView extends StatefulWidget {
  const RestockView({super.key});

  @override
  State<RestockView> createState() => _RestockViewState();
}

class _RestockViewState extends State<RestockView> {
  RestockViewLogic restockViewLogic = RestockViewLogic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('進貨'),
        actions: [
          DatePickerField(
            initialDate: DateTime.now(),
          ),
        ],
      ),
      body: FutureBuilder(
          future: restockViewLogic.getAllPurchasedAndGoods(),
          builder: (context, purchasedItemSnapshot) {
            if (purchasedItemSnapshot.hasData) {
              Map<int, PurchasedItemAndGood> purchasedItemMap = {for (var e in purchasedItemSnapshot.data!) e.goodId: e};
              restockViewLogic.purchasedItemsNotifier.value = purchasedItemSnapshot.data!;
              return Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120), // 限制最大寬度為 80
                      child: purchasedItemSnapshot.hasData
                          ? ValueListenableBuilder(
                              valueListenable: restockViewLogic.purchasedItemsNotifier,
                              builder: (context, purchasedItems, child) {
                                return purchasedItemList(purchasedItems);
                              })
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        SizedBox(height: 50, child: searchBar(purchasedItemMap)),
                        tableTitle(),
                        restockItemsTable(purchasedItemMap),
                        restockOrderSave(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget restockOrderSave() {
    TextEditingController restockOrderNoteController = TextEditingController();
    return SizedBox(
      height: calculateTextSize(context, '總計', style: Theme.of(context).textTheme.titleLarge).height + 100,
      child: Column(
        children: [
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                flex: 2,
                child: Column(children: [
                  const Text('廠商', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ValueListenableBuilder(
                      valueListenable: restockViewLogic.restockOrderVendorNotifier,
                      builder: (context, vendor, child) {
                        return Text(
                          vendor.name,
                          textAlign: TextAlign.center,
                        );
                      }),
                ]),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const Text('總計', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ValueListenableBuilder(
                        valueListenable: restockViewLogic.restockItemsNotifier,
                        builder: (context, restockItems, child) {
                          return Text(
                            '${restockItems.fold(0.0, (previousValue, element) {
                              return previousValue + element.amount;
                            })}',
                            textAlign: TextAlign.center,
                          );
                        }),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    const Text('備註'),
                    TextFormField(
                      textAlign: TextAlign.start,
                      controller: restockOrderNoteController,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      //todo 進貨時會更新錯誤的庫存
                      onPressed: () => restockViewLogic.saveRestockOrder(),
                      icon: const Icon(Icons.save),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget searchBar(Map<int, PurchasedItemAndGood> purchasedItemSnapshot) {
    return FutureBuilder(
        future: PurchasedItemsTagProvider().getAll(),
        builder: (context, purchasedItemsTagsSnapshot) {
          if (!purchasedItemsTagsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          List<TagsGridViewTag> gridViewTags = [];
          Future<List<TagPurchasedItemRelationship>> tagPurchasedItemRelationships = Future.value([]);
          tagPurchasedItemRelationships = TagPurchasedItemRelationshipProvider().getAll();
          gridViewTags.add(TagsGridViewTag(
            id: 0,
            name: '全部',
            color: Colors.grey,
            onTap: () {
              restockViewLogic.purchasedItemsNotifier.value = purchasedItemSnapshot.values.toList();
            },
            showDeleteIcon: false,
          ));
          for (var purchasedItemsTag in purchasedItemsTagsSnapshot.data!) {
            gridViewTags.add(TagsGridViewTag(
              id: purchasedItemsTag.id!,
              name: purchasedItemsTag.name,
              color: Color(purchasedItemsTag.color),
              onTap: () async {
                List<PurchasedItemAndGood> purchasedItems = [];
                await tagPurchasedItemRelationships.then((value) {
                  for (var tagPurchasedItemRelationship in value) {
                    if (tagPurchasedItemRelationship.tagId == purchasedItemsTag.id) {
                      purchasedItems.add(purchasedItemSnapshot[tagPurchasedItemRelationship.goodId]!);
                    }
                  }
                });
                restockViewLogic.purchasedItemsNotifier.value = purchasedItems;
              },
              showDeleteIcon: false,
            ));
          }
          return TagsGridView(tags: gridViewTags);
        });
  }

  Widget purchasedItemList(List<PurchasedItemAndGood> purchasedItems) {
    return ValueListenableBuilder(
        valueListenable: restockViewLogic.restockOrderVendorNotifier,
        builder: (context, vendor, child) {
          List<PurchasedItemAndGood> purchasedItemsCopy = [];
          if (vendor.id != Vendor.initial().id) {
            for (var purchasedItem in purchasedItems) {
              if (purchasedItem.vendorId == vendor.id) {
                purchasedItemsCopy.add(purchasedItem);
              }
            }
          } else {
            purchasedItemsCopy = purchasedItems;
          }
          return ListView.builder(
            itemCount: purchasedItemsCopy.length,
            itemBuilder: (context, index) {
              PurchasedItemAndGood purchasedItem = purchasedItemsCopy[index];
              return InkWell(
                onTap: () async {
                  restockViewLogic.restockItemsNotifier.value.add(
                    Restock(
                      goodId: purchasedItem.goodId,
                      quantity: 1,
                      price: 0,
                      amount: 0,
                      restockDate: DateTime.now(),
                    ),
                  );
                  if (restockViewLogic.restockItemsNotifier.value.length == 1) {
                    Vendor vendor;
                    vendor = await VendorProvider()
                        .getItem(purchasedItem.vendorId)
                        .then((value) => value ?? Vendor(id: 0, name: '未知廠商', address: '', phone: '', fax: '', contactPerson: '', contactPersonPhone: '', contactPersonEmail: '', status: ''));
                    restockViewLogic.restockOrderVendorNotifier.value = vendor;
                  }
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  restockViewLogic.restockItemsNotifier.notifyListeners();
                },
                child: ProductCard(
                  width: 100,
                  height: 100,
                  title: purchasedItem.name,
                  subtitle: '(${purchasedItem.unit})',
                ),
              );
            },
          );
        });
  }

  Container tableTitle() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text('品項'),
          ),
          const Expanded(
            flex: 1,
            child: Text('單位'),
          ),
          const Expanded(
            flex: 2,
            child: Text('數量'),
          ),
          const Expanded(
            flex: 2,
            child: Text('單價'),
          ),
          const Expanded(
            flex: 2,
            child: Text('小計', textAlign: TextAlign.center),
          ),
          const Expanded(
            flex: 4,
            child: Text('備註'),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () {
                restockViewLogic.restockItemsNotifier.value = [];
                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                restockViewLogic.restockItemsNotifier.notifyListeners();
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Expanded restockItemsTable(Map<int, PurchasedItemAndGood> purchasedItemMap) {
    return Expanded(
      child: ValueListenableBuilder(
          valueListenable: restockViewLogic.restockItemsNotifier,
          builder: (context, restockItems, child) {
            return ListView.builder(
              itemCount: restockItems.length,
              itemBuilder: (context, index) {
                restockItems[index].amount = double.parse((restockItems[index].quantity * restockItems[index].price).toStringAsFixed(2));
                return Container(
                  margin: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                  child: Row(
                    children: [
                      //name
                      Expanded(flex: 2, child: Text(purchasedItemMap[restockItems[index].goodId]!.name)),
                      //unit
                      Expanded(flex: 1, child: Text(purchasedItemMap[restockItems[index].goodId]!.unit)),
                      //quantity
                      Expanded(
                        flex: 2,
                        child: NumberInputWithIncrementDecrement(
                          key: ValueKey(restockItems[index]),
                          initialNumber: restockItems[index].quantity,
                          onChanged: (number) {
                            restockItems[index].quantity = number;
                            restockViewLogic.restockItemsNotifier.value = List.from(restockItems);
                          },
                          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                          onEditingComplete: (number) => restockViewLogic.restockItemsNotifier.notifyListeners(),
                        ),
                      ),
                      //price
                      Expanded(
                        flex: 2,
                        child: NumberInputWithIncrementDecrement(
                          key: ValueKey(restockItems[index]),
                          initialNumber: restockItems[index].price,
                          onChanged: (value) {
                            restockItems[index].price = value;
                            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                            restockViewLogic.restockItemsNotifier.notifyListeners();
                          },
                          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                          onEditingComplete: (number) => restockViewLogic.restockItemsNotifier.notifyListeners(),
                        ),
                      ),
                      //amount
                      Expanded(
                        flex: 2,
                        child: Text(
                          restockItems[index].amount.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      //note
                      Expanded(
                          flex: 4,
                          child: TextFormField(
                            key: ValueKey(restockItems[index]),
                            textAlign: TextAlign.start,
                            initialValue: restockItems[index].note,
                            onChanged: (value) => restockItems[index].note = value,
                          )),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          onPressed: () {
                            restockItems.removeAt(index);
                            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                            restockViewLogic.restockItemsNotifier.notifyListeners();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }),
    );
  }
}

class RestockViewLogic {
  OrderProvider orderProvider = OrderProvider();
  RestockOrderProvider restockOrderProvider = RestockOrderProvider();
  RestockProvider restockProvider = RestockProvider();
  PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  InventoryProvider inventoryProvider = InventoryProvider();

  ValueNotifier<List<Restock>> restockItemsNotifier = ValueNotifier<List<Restock>>([]); //訂貨清單
  ValueNotifier<List<PurchasedItemAndGood>> purchasedItemsNotifier = ValueNotifier<List<PurchasedItemAndGood>>([]); //可進貨的商品
  ValueNotifier<Vendor> restockOrderVendorNotifier = ValueNotifier<Vendor>(Vendor.initial()); //此次進貨的供應商

  TextEditingController restockOrderNoteController = TextEditingController();

  RestockViewLogic() {
    addListener();
  }

  void addListener() {
    restockItemsNotifier.addListener(() {
      if (restockItemsNotifier.value.isEmpty) {
        restockOrderVendorNotifier.value = Vendor.initial();
      }
    });
  }

  void saveRestockOrder() async {
    Map<int, double> newGoods = {};

    int orderId = await restockOrderProvider.insert(RestockOrder(
      vendorId: restockOrderVendorNotifier.value.id!,
      date: DateTime.now(),
      total: restockItemsNotifier.value.fold(0.0, (previousValue, element) {
        return previousValue + element.amount;
      }),
      note: restockOrderNoteController.text,
    ));
    for (Restock restock in restockItemsNotifier.value) {
      restock.restockOrderId = orderId;
      restock.restockDate = DateTime.now();
      newGoods[restock.goodId] = restock.quantity;
      await restockProvider.insert(restock);
      //更新庫存
      Inventory? inventory = await inventoryProvider.getInventoryByGoodId(restock.goodId);
      if (inventory != null) {
        inventory.quantity += restock.quantity;
        await inventoryProvider.update(inventory, mode: Inventory.COMPUTE_MODE);
      } else {
        //如果庫存不存在，則新增庫存
        await inventoryProvider.insert(Inventory(goodId: restock.goodId, quantity: restock.quantity, recodeMode: Inventory.CREATE_MODE, recordTime: DateTime.now()));
      }
    }
    // 清空UI訂貨清單資訊
    restockItemsNotifier.value = [];
    restockOrderNoteController.text = '';
  }

  Future<List<PurchasedItemAndGood>> getAllPurchasedAndGoods() async {
    var purchasedItems = await purchasedItemProvider.queryByStatus(true);
    var purchasedItemAndGoods = PurchasedLogic().convertPurchasedItems2PurchasedItemAndGoods(purchasedItems);
    return purchasedItemAndGoods;
  }
}
