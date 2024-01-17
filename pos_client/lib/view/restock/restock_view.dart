import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/restock.dart';
import 'package:pos/template/number_input_with_Increment_Decrement.dart';

class RestockView extends StatefulWidget {
  const RestockView({super.key});

  @override
  State<RestockView> createState() => _RestockViewState();
}

class _RestockViewState extends State<RestockView> {
  PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  ValueNotifier<List<Restock>> restockItemsNotifier = ValueNotifier<List<Restock>>([]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('進貨')),
      body: FutureBuilder(
          future: purchasedItemProvider.queryAll(),
          builder: (context, purchasedItemSnapshot) {
            Map<int, PurchasedItem> purchasedItemMap = {for (var e in purchasedItemSnapshot.data!) e.id!: e};
            return Row(
              children: [
                Flexible(
                  flex: 1,
                  child: purchasedItemSnapshot.hasData
                      ? ListView.builder(
                          itemCount: purchasedItemSnapshot.data!.length,
                          itemBuilder: (context, index) {
                            PurchasedItem purchasedItem = purchasedItemSnapshot.data![index];
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
                              child: Card(
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Column(
                                    children: [
                                      Text(purchasedItem.name),
                                      Text(purchasedItem.unit),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                Flexible(
                  flex: 5,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 50,
                        child: Placeholder(),
                      ),
                      Container(
                        height: 50,
                        margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        padding: const EdgeInsets.all(0),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text('品項'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('單位'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('數量'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('單價'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('金額'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('備註'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: ValueListenableBuilder(
                            valueListenable: restockItemsNotifier,
                            builder: (context, restockItems, child) {
                              return ListView.builder(
                                itemCount: restockItems.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(purchasedItemMap[restockItems[index].purchasedItemId]!.name),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(purchasedItemMap[restockItems[index].purchasedItemId]!.unit),
                                        ),
                                        const Expanded(
                                          flex: 1,
                                          child: NumberInputWithIncrementDecrement(),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(restockItems[index].price.toString()),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(restockItems[index].amount.toString()),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(restockItems[index].note ?? ''),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}
