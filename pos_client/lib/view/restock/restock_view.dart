import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/purchased_items_tag.dart';
import 'package:pos/store/model/restock/restock.dart';
import 'package:pos/store/model/restock/restock_order.dart';
import 'package:pos/store/model/restock/tag_purchased_item_relationship.dart';
import 'package:pos/store/model/restock/vendor.dart';
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
  PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  ValueNotifier<List<Restock>> restockItemsNotifier = ValueNotifier<List<Restock>>([]); //訂貨清單
  ValueNotifier<List<PurchasedItem>> purchasedItemsNotifier = ValueNotifier<List<PurchasedItem>>([]); //可進貨的商品
  ValueNotifier<Vendor> restockOrderVendorNotifier = ValueNotifier<Vendor>(Vendor.initial()); //此次進貨的供應商
  @override
  void initState() {
    super.initState();
    restockItemsNotifier.addListener(() {
      if (restockItemsNotifier.value.isEmpty) {
        restockOrderVendorNotifier.value = Vendor.initial();
      }
    });
  }

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
          future: purchasedItemProvider.queryAll(),
          builder: (context, purchasedItemSnapshot) {
            if (purchasedItemSnapshot.hasData) {
              Map<int, PurchasedItem> purchasedItemMap = {for (var e in purchasedItemSnapshot.data!) e.id!: e};
              purchasedItemsNotifier.value = purchasedItemSnapshot.data!;
              return Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120), // 限制最大寬度為 80
                      child: purchasedItemSnapshot.hasData
                          ? ValueListenableBuilder(
                              valueListenable: purchasedItemsNotifier,
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
                      valueListenable: restockOrderVendorNotifier,
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
                        valueListenable: restockItemsNotifier,
                        builder: (context, restockItems, child) {
                          return Text(
                            '${restockItemsNotifier.value.fold(0.0, (previousValue, element) {
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
                      onPressed: () async {
                        RestockOrderProvider restockOrderProvider = RestockOrderProvider();
                        int orderId = await restockOrderProvider.insert(RestockOrder(
                          vendorId: restockOrderVendorNotifier.value.id!,
                          date: DateTime.now(),
                          total: restockItemsNotifier.value.fold(0.0, (previousValue, element) {
                            return previousValue + element.amount;
                          }),
                          note: restockOrderNoteController.text,
                        ));
                        RestockProvider restockProvider = RestockProvider();
                        for (var restock in restockItemsNotifier.value) {
                          restock.restockOrderId = orderId;
                          restock.restockDate = DateTime.now();
                          await restockProvider.insert(restock);
                        }
                        restockItemsNotifier.value = [];
                        restockOrderNoteController.text = '';
                      },
                      icon: const Icon(Icons.save),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Row(
          //   children: [
          //     const Expanded(flex: 5, child: SizedBox()),
          //     Expanded(
          //       flex: 2,
          //       child: ValueListenableBuilder(
          //           valueListenable: restockItemsNotifier,
          //           builder: (context, restockItems, child) {
          //             return Text(
          //               '${restockItemsNotifier.value.fold(0.0, (previousValue, element) {
          //                 return previousValue + element.amount;
          //               })}',
          //               textAlign: TextAlign.center,
          //             );
          //           }),
          //     ),
          //     Expanded(
          //       flex: 4,
          //       child: TextFormField(
          //         textAlign: TextAlign.start,
          //         controller: restockOrderNoteController,
          //       ),
          //     ),
          //     Expanded(
          //       flex: 1,
          //       child: IconButton(
          //         onPressed: () async {
          //           RestockOrderProvider restockOrderProvider = RestockOrderProvider();
          //           int orderId = await restockOrderProvider.insert(RestockOrder(
          //             vendorId: 1,
          //             date: DateTime.now(),
          //             total: restockItemsNotifier.value.fold(0.0, (previousValue, element) {
          //               return previousValue + element.amount;
          //             }),
          //             note: restockOrderNoteController.text,
          //           ));
          //           RestockProvider restockProvider = RestockProvider();
          //           for (var restock in restockItemsNotifier.value) {
          //             restock.restockOrderId = orderId;
          //             restock.restockDate = DateTime.now();
          //             await restockProvider.insert(restock);
          //           }
          //           restockItemsNotifier.value = [];
          //           restockOrderNoteController.text = '';
          //         },
          //         icon: const Icon(Icons.save),
          //       ),
          //     ),
          //   ],
          // )
        ],
      ),
    );
  }

  Widget searchBar(Map<int, PurchasedItem> purchasedItemSnapshot) {
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
              purchasedItemsNotifier.value = purchasedItemSnapshot.values.toList();
            },
            showDeleteIcon: false,
          ));
          for (var purchasedItemsTag in purchasedItemsTagsSnapshot.data!) {
            gridViewTags.add(TagsGridViewTag(
              id: purchasedItemsTag.id!,
              name: purchasedItemsTag.name,
              color: Color(purchasedItemsTag.color),
              onTap: () async {
                List<PurchasedItem> purchasedItems = [];
                await tagPurchasedItemRelationships.then((value) {
                  for (var tagPurchasedItemRelationship in value) {
                    if (tagPurchasedItemRelationship.tagId == purchasedItemsTag.id) {
                      purchasedItems.add(purchasedItemSnapshot[tagPurchasedItemRelationship.purchasedItemId]!);
                    }
                  }
                });
                purchasedItemsNotifier.value = purchasedItems;
              },
              showDeleteIcon: false,
            ));
          }
          return TagsGridView(tags: gridViewTags);
        });
  }

  Widget purchasedItemList(List<PurchasedItem> purchasedItems) {
    return ValueListenableBuilder(
        valueListenable: restockOrderVendorNotifier,
        builder: (context, vendor, child) {
          List<PurchasedItem> purchasedItemsCopy = [];
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
              PurchasedItem purchasedItem = purchasedItemsCopy[index];
              return InkWell(
                onTap: () async {
                  restockItemsNotifier.value.add(
                    Restock(
                      purchasedItemId: purchasedItem.id!,
                      quantity: 1,
                      price: 0,
                      amount: 0,
                      restockDate: DateTime.now(),
                    ),
                  );
                  if (restockItemsNotifier.value.length == 1) {
                    restockOrderVendorNotifier.value = await VendorProvider().getItem(purchasedItem.vendorId);
                  }
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  restockItemsNotifier.notifyListeners();
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
                restockItemsNotifier.value = [];
                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                restockItemsNotifier.notifyListeners();
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Expanded restockItemsTable(Map<int, PurchasedItem> purchasedItemMap) {
    return Expanded(
      child: ValueListenableBuilder(
          valueListenable: restockItemsNotifier,
          builder: (context, restockItems, child) {
            return ListView.builder(
              itemCount: restockItems.length,
              itemBuilder: (context, index) {
                restockItemsNotifier.value[index].amount = double.parse((restockItemsNotifier.value[index].quantity * restockItemsNotifier.value[index].price).toStringAsFixed(2));
                return Container(
                  margin: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                  child: Row(
                    children: [
                      //name
                      Expanded(flex: 2, child: Text(purchasedItemMap[restockItems[index].purchasedItemId]!.name)),
                      //unit
                      Expanded(flex: 1, child: Text(purchasedItemMap[restockItems[index].purchasedItemId]!.unit)),
                      //quantity
                      Expanded(
                        flex: 2,
                        child: NumberInputWithIncrementDecrement(
                          key: ValueKey(restockItems[index]),
                          initialNumber: restockItems[index].quantity.toDouble(),
                          onChanged: (number) {
                            restockItemsNotifier.value[index].quantity = number;
                            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                            restockItemsNotifier.notifyListeners();
                          },
                          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                          onEditingComplete: () => restockItemsNotifier.notifyListeners(),
                        ),
                      ),
                      //price
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: ValueKey(restockItems[index]),
                          initialValue: restockItems[index].price.toString(),
                          onChanged: (value) {
                            restockItemsNotifier.value[index].price = double.parse(value);
                            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                            restockItemsNotifier.notifyListeners();
                          },
                          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                          onEditingComplete: () => restockItemsNotifier.notifyListeners(),
                        ),
                      ),
                      //amount
                      Expanded(
                        flex: 2,
                        child: Text(
                          restockItemsNotifier.value[index].amount.toString(),
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
                            onChanged: (value) => restockItemsNotifier.value[index].note = value,
                          )),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          onPressed: () {
                            restockItemsNotifier.value.removeAt(index);
                            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                            restockItemsNotifier.notifyListeners();
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
