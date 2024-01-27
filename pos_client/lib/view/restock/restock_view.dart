import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/purchased_items_tag.dart';
import 'package:pos/store/model/restock/restock.dart';
import 'package:pos/store/model/restock/restock_order.dart';
import 'package:pos/store/model/restock/tag_purchased_item_relationship.dart';
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
  ValueNotifier<List<Restock>> restockItemsNotifier = ValueNotifier<List<Restock>>([]);
  ValueNotifier<List<PurchasedItem>> purchasedItemsNotifier = ValueNotifier<List<PurchasedItem>>([]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('進貨')),
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
          const Row(
            children: [
              Expanded(flex: 5, child: SizedBox()),
              Expanded(
                flex: 2,
                child: Text('總計', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 5,
                child: Text('備註'),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder(
                    valueListenable: restockItemsNotifier,
                    builder: (context, restockItems, child) {
                      return Text(
                        '${restockItemsNotifier.value.fold(0.0, (previousValue, element) {
                          return previousValue + element.amount;
                        })}',
                        textAlign: TextAlign.center,
                      );
                    }),
              ),
              Expanded(
                flex: 4,
                child: TextFormField(
                  textAlign: TextAlign.start,
                  controller: restockOrderNoteController,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () async {
                    RestockOrderProvider restockOrderProvider = RestockOrderProvider();
                    int orderId = await restockOrderProvider.insert(RestockOrder(
                      vendorId: 1,
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
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget searchBar(Map<int, PurchasedItem> purchasedItemSnapshot) {
    return FutureBuilder(
        future: PurchasedItemsTagProvider().getAll(),
        builder: (context, purchasedItemsTagsSnapshot) {
          List<TagsGridViewTag> gridViewTags = [];
          Future<List<TagPurchasedItemRelationship>> tagPurchasedItemRelationships = Future.value([]);
          tagPurchasedItemRelationships = TagPurchasedItemRelationshipProvider().getAll();
          gridViewTags.add(TagsGridViewTag(
            name: '全部',
            color: Colors.grey,
            onTap: () {
              purchasedItemsNotifier.value = purchasedItemSnapshot.values.toList();
            },
            showDeleteIcon: false,
          ));
          for (var purchasedItemsTag in purchasedItemsTagsSnapshot.data!) {
            gridViewTags.add(TagsGridViewTag(
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

  ListView purchasedItemList(List<PurchasedItem> purchasedItems) {
    return ListView.builder(
      itemCount: purchasedItems.length,
      itemBuilder: (context, index) {
        PurchasedItem purchasedItem = purchasedItems[index];
        return InkWell(
          onTap: () {
            restockItemsNotifier.value.add(
              Restock(
                purchasedItemId: purchasedItem.id!,
                quantity: 1,
                price: 0,
                amount: 0,
                restockDate: DateTime.now(),
              ),
            );
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
  }

  Container tableTitle() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      padding: const EdgeInsets.all(0),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('品項'),
          ),
          Expanded(
            flex: 1,
            child: Text('單位'),
          ),
          Expanded(
            flex: 2,
            child: Text('數量'),
          ),
          Expanded(
            flex: 2,
            child: Text('單價'),
          ),
          Expanded(
            flex: 2,
            child: Text('小計', textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 4,
            child: Text('備註'),
          ),
          Expanded(
            flex: 1,
            child: SizedBox(),
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
                restockItemsNotifier.value[index].amount = restockItemsNotifier.value[index].quantity * restockItemsNotifier.value[index].price;
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
                          initialNumber: restockItems[index].quantity,
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
                          '${restockItems[index].quantity * restockItems[index].price}',
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
