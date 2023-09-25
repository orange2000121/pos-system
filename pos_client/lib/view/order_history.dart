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
            width: MediaQuery.of(context).size.width * 0.2,
            child: Column(
              children: [
                Text(e),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('銷售數：${sellMap[e]?['quantity']}'),
                    const SizedBox(width: 10),
                    Text('${(sellMap[e]!['quantity']! / totalQuantity * 100).toStringAsFixed(2)}%'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('總銷售額：${sellMap[e]?['totalPrice']}'),
                    const SizedBox(width: 10),
                    Text('${(sellMap[e]!['totalPrice']! / totalPrice * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget orderContent(int orderId) {
    return AlertDialog(
      title: const Text('Order Content'),
      content: SizedBox(
        width: MediaQuery.of(context).size.height * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: FutureBuilder(
          future: sellProvider.getItemByOrderId(orderId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data![index].name),
                    subtitle: Text('${snapshot.data![index].sugar} ${snapshot.data![index].ice}'),
                    trailing: Text(snapshot.data![index].quantity.toString()),
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget ordersListView(Map<OrderItem, List<SellItem>> orderMap) {
    return ListView.builder(
      itemCount: orderMap.length,
      itemBuilder: (context, index) {
        List<SellItem> sellitems = orderMap.values.toList()[index];
        var orders = orderMap.keys.toList()[index];
        return SmallItemCard(
          title: Column(
            children: [
              Text(orders.createAt.toString()),
            ],
          ),
          simpleInfo: sellitems.map((e) => Text('${e.name} x${e.quantity}')).toList(),
          detailedInfo: sellitems.map((e) {
            return ListTile(
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
          }).toList(),
          dialogAction: [
            ElevatedButton(
              onPressed: () {
                orderProvider.delete(orders.id!);
                setState(() {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('關閉'),
            ),
          ],
        );
      },
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
