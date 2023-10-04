import 'package:flutter/material.dart';
import 'package:pos/store/model/order.dart';
import 'package:pos/store/model/sell.dart';
import 'package:pos/template/data_retrieval_widget.dart';
import 'package:pos/template/date_picker.dart';

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
  OrderProvider orderProvider = OrderProvider();
  SellProvider sellProvider = SellProvider();
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
        title: const Text('Order History'),
      ),
      body: Column(
        children: [
          filterBar(),
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

  Widget filterBar() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
              onPressed: () {
                setState(() {
                  DateTime now = DateTime.now();
                  startDateNotifier.value = DateTime(now.year, now.month, now.day, 0, 0, 0);
                  endDateNotifier.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              },
              child: const Text('今天')),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  DateTime now = DateTime.now();
                  startDateNotifier.value = DateTime(now.year, now.month, 1);
                  endDateNotifier.value = DateTime(now.year, now.month + 1, 0);
                });
              },
              child: const Text('這個月')),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  DateTime now = DateTime.now();
                  startDateNotifier.value = DateTime(now.year, 1, 1);
                  endDateNotifier.value = DateTime(now.year, 12, 31);
                });
              },
              child: const Text('今年')),
          ValueListenableBuilder(
              valueListenable: startDateNotifier,
              builder: (context, startDate, child) {
                return DatePickerfield(
                  selectedDate: startDate,
                  onChanged: (date) {
                    startDateNotifier.value = date;
                  },
                );
              }),
          const SizedBox(
            width: 10,
            child: Text('~'),
          ),
          ValueListenableBuilder(
              valueListenable: endDateNotifier,
              builder: (context, endDate, child) {
                return DatePickerfield(
                  selectedDate: endDate,
                  onChanged: (date) {
                    endDateNotifier.value = date;
                  },
                );
              }),
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget sellOverview(List<List<SellItem>> sellItems) {
    Map<String, Map<String, int>> sellMap = {};
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
    return ListView(
      scrollDirection: Axis.horizontal,
      children: sellMap.keys.map((e) {
        return Card(
          child: SizedBox(
            width: (MediaQuery.of(context).size.width * 0.2) > 200 ? MediaQuery.of(context).size.width * 0.2 : 200,
            child: Column(
              children: [
                Text(e),
                Expanded(
                  child: ListView(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    // crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  // Widget orderContent(int orderId) {
  //   return AlertDialog(
  //     title: const Text('Order Content'),
  //     content: SizedBox(
  //       width: MediaQuery.of(context).size.height * 0.8,
  //       height: MediaQuery.of(context).size.height * 0.8,
  //       child: FutureBuilder(
  //         future: sellProvider.getItemByOrderId(orderId),
  //         builder: (context, snapshot) {
  //           if (snapshot.hasData) {
  //             return ListView.builder(
  //               itemCount: snapshot.data!.length,
  //               itemBuilder: (context, index) {
  //                 return ListTile(
  //                   title: Text(snapshot.data![index].name),
  //                   subtitle: Text('${snapshot.data![index].sugar} ${snapshot.data![index].ice}'),
  //                   trailing: Text(snapshot.data![index].quantity.toString()),
  //                 );
  //               },
  //             );
  //           } else {
  //             return const Center(child: CircularProgressIndicator());
  //           }
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget ordersListView(Map<OrderItem, List<SellItem>> orderMap) {
    return ListView.builder(
      itemCount: orderMap.length,
      itemBuilder: (context, index) {
        List<SellItem> sellitems = orderMap.values.toList()[index];
        OrderItem order = orderMap.keys.toList()[index];
        ValueNotifier editSwitchNotifier = ValueNotifier(false);
        return SmallItemCard(
          title: ValueListenableBuilder(
              valueListenable: editSwitchNotifier,
              builder: (context, value, child) {
                return value
                    ? DatePickerfield(
                        selectedDate: order.createAt,
                        onChanged: (date) => order.createAt = date,
                      )
                    : Text(
                        order.createAt.toString(),
                        textAlign: TextAlign.center,
                      );
              }),
          simpleInfo: sellitems.map((e) {
            return Text('${e.name} x${e.quantity}');
          }).toList(),
          detailedInfo: sellitems.map((e) {
            return ValueListenableBuilder(
                valueListenable: editSwitchNotifier,
                builder: (context, value, child) {
                  return ListTile(
                    leading: value
                        ? IconButton(
                            onPressed: () {
                              showDialog(context: context, builder: (context) => editSellItem(context, e));
                            },
                            icon: const Icon(Icons.edit),
                          )
                        : null,
                    title: Text(e.name),
                    subtitle: Text('${e.sugar} ${e.ice}'),
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
                });
          }).toList(),
          dialogAction: [
            ValueListenableBuilder(
              valueListenable: editSwitchNotifier,
              builder: (context, value, child) => Switch(
                value: editSwitchNotifier.value,
                onChanged: (value) => editSwitchNotifier.value = value,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                orderProvider.delete(order.id!);
                setState(() {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
            ),
            ValueListenableBuilder(
              valueListenable: editSwitchNotifier,
              builder: (context, value, child) => ElevatedButton(
                onPressed: value
                    ? () {
                        orderProvider.update(order.id!, order);
                        for (var element in sellitems) {
                          sellProvider.update(element.id!, element);
                        }
                        setState(() {
                          Navigator.of(context).pop();
                        });
                      }
                    : () {
                        Navigator.of(context).pop();
                      },
                child: Text(value ? '確認' : '關閉'),
              ),
            ),
          ],
        );
      },
    );
  }

  AlertDialog editSellItem(BuildContext context, SellItem e) {
    return AlertDialog(
      title: const Text('編輯商品紀錄'),
      content: SizedBox(
        width: MediaQuery.of(context).size.height * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: GridView(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: MediaQuery.of(context).size.width * 0.2,
          ),
          children: [
            editcard(context, '商品名稱', e.name, (value) => e.name = value),
            editcard(context, '糖度', e.sugar, (value) => e.sugar = value),
            editcard(context, '冰塊', e.ice, (value) => e.ice = value),
            editcard(context, '數量', e.quantity.toString(), (value) => e.quantity = int.parse(value)),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // sellProvider.update(e.id!, e);
            setState(() {
              Navigator.of(context).pop();
            });
          },
          child: const Text('確認'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('關閉'),
        ),
      ],
    );
  }

  Card editcard(BuildContext context, String hint, String initialvalue, Function(String value) onChanged) {
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
                initialValue: initialvalue,
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

    if (customerId != null) {
      orders = await orderProvider.getAllFromCustomerIdandDateRange(customerId!, startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
    } else {
      orders = await orderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
    }
    Map<OrderItem, List<SellItem>> orderMap = {};
    for (var i = 0; i < orders.length; i++) {
      orderMap[orders[i]] = await sellProvider.getItemByOrderId(orders[i].id!);
    }
    return orderMap;
  }
}
