import 'package:flutter/material.dart';
import 'package:pos/logic/sell/cashier_logic.dart';
import 'package:pos/logic/sell/order_history_logic.dart';
import 'package:pos/store/model/sell/customer.dart';
import 'package:pos/store/model/sell/order.dart';
import 'package:pos/store/model/sell/sell.dart';
import 'package:pos/template/small_item_card.dart';
import 'package:pos/template/date_picker.dart';
import 'package:pos/view/sell/cashier.dart';

class OrderHistory extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? customerId;
  const OrderHistory({
    super.key,
    this.startDate,
    this.endDate,
    this.customerId,
  });

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  final OrderHistoryLogic orderHistoryLogic = OrderHistoryLogic();
  SellProvider sellProvider = SellProvider();
  CustomerProvider customerProvider = CustomerProvider();
  ValueNotifier<DateTime?> startDateNotifier = ValueNotifier(null);
  ValueNotifier<DateTime?> endDateNotifier = ValueNotifier(null);
  int? customerId;
  @override
  void initState() {
    super.initState();
    startDateNotifier.value = widget.startDate;
    endDateNotifier.value = widget.endDate;
    customerId = widget.customerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FutureBuilder(
                future: customerId != null ? customerProvider.getItem(customerId!) : Future(() => Customer('', '', '', '')),
                builder: (context, AsyncSnapshot<Customer> snapshot) {
                  if (snapshot.hasData) {
                    return Text('『${snapshot.data!.name}』歷史訂單');
                  } else {
                    return const Text('歷史訂單');
                  }
                }),
            filterBar(
              startDateNotifier: startDateNotifier,
              endDateNotifier: endDateNotifier,
              onChanged: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
                future: getOrders(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2,
                          child: sellOverview(snapshot.data!.values.toList()),
                        ),
                        Expanded(child: ordersListView(snapshot.data!)),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
          ),
        ],
      ),
    );
  }

  Widget sellOverview(List<List<SellItem>> sellItems) {
    Map<String, Map<String, int>> sellMap = {};
    final scrollController = ScrollController();

    for (var element in sellItems) {
      for (var element in element) {
        if (sellMap.containsKey(element.name)) {
          sellMap[element.name] = {
            'quantity': sellMap[element.name]!['quantity']! + element.quantity,
            'totalPrice': sellMap[element.name]!['totalPrice']! + element.price.toInt() * element.quantity,
          };
        } else {
          sellMap[element.name] = {
            'quantity': element.quantity,
            'totalPrice': element.price.toInt() * element.quantity,
          };
        }
      }
    }
    int totalQuantity = 0;
    int totalPrice = 0;
    for (var element in sellMap.values) {
      totalQuantity += element['quantity']!;
      totalPrice += element['totalPrice']!;
    }
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        scrollController.jumpTo(scrollController.offset - details.delta.dx);
      },
      child: Scrollbar(
        controller: scrollController,
        child: ListView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          children: sellMap.keys.map((e) {
            return Card(
              child: SizedBox(
                width: (MediaQuery.of(context).size.width * 0.2) > 200 ? MediaQuery.of(context).size.width * 0.2 : 200,
                child: Column(
                  children: [
                    Text(e),
                    Expanded(
                      child: ListView(
                        children: [
                          Text('${(sellMap[e]!['quantity']! / totalQuantity * 100).toStringAsFixed(2)}%' '  ' '銷售數量：${sellMap[e]?['quantity']}'),
                          Text('${(sellMap[e]!['totalPrice']! / totalPrice * 100).toStringAsFixed(2)}%' '  ' '總銷售額：${sellMap[e]?['totalPrice']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget ordersListView(Map<OrderItem, List<SellItem>> orderMap) {
    return ListView.builder(
      itemCount: orderMap.length,
      itemBuilder: (context, index) {
        List<SellItem> sellItems = orderMap.values.toList()[index];
        OrderItem order = orderMap.keys.toList()[index];
        return SimplAndDetailInfoCard(
          title: Text(
            order.createAt.toString().split('.')[0],
            textAlign: TextAlign.center,
          ),
          subtitle: [
            Text('總金額：${order.totalPrice}'),
          ],
          simpleInfo: sellItems.map((e) {
            return Text('${e.name} x${e.quantity}');
          }).toList(),
          detailedInfo: sellItems.map((e) {
            return ListTile(
              title: Text(e.name),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${e.price} x${e.quantity}'),
                    Text('${e.price * e.quantity}'),
                  ],
                ),
              ),
            );
          }).toList(),
          dialogAction: [
            ElevatedButton(
              onPressed: () async {
                List<ShopItem> shopItems = [];
                for (var element in sellItems) {
                  shopItems.add(ShopItem(
                    element.goodId,
                    element.name,
                    element.price,
                    element.quantity,
                    '',
                  ));
                }
                ShopItemEditData shopItemEditData = ShopItemEditData(
                  customerId: order.customerId ?? 0,
                  orderId: order.id!,
                  createAt: order.createAt ?? DateTime.now(),
                  shopItems: shopItems,
                );
                Navigator.of(context).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Cashier(
                      isEditMode: true,
                      editShopItems: shopItemEditData,
                    ),
                  ),
                );
                setState(() {});
              },
              child: const Text('編輯'),
            ),
            ElevatedButton(
              onPressed: () {
                orderHistoryLogic.deleteOrder(order.id!, sellItems: sellItems);
                setState(() {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  Card editCard(BuildContext context, String hint, String initialValue, Function(String value) onChanged) {
    return Card(
      color: const Color.fromARGB(188, 184, 156, 184),
      child: Column(
        children: [
          Flexible(
            flex: 2,
            child: Center(child: Text(hint)),
          ),
          Flexible(
            flex: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.08,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Color.fromARGB(255, 130, 107, 107),
                ),
                initialValue: initialValue,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<OrderItem, List<SellItem>>> getOrders() async {
    List orders;

    orders = await orderHistoryLogic.orderProvider.getAllFromCustomerIdAndDateRange(customerId, startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
    Map<OrderItem, List<SellItem>> orderMap = {};
    for (var i = 0; i < orders.length; i++) {
      orderMap[orders[i]] = await sellProvider.getItemByOrderId(orders[i].id!);
    }
    return orderMap;
  }
}
