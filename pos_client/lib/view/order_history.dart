import 'package:flutter/material.dart';
import 'package:pos/store/model/order.dart';
import 'package:pos/store/model/sell.dart';
import 'package:pos/template/data_retrieval_widget.dart';
import 'package:pos/template/date_picker.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  OrderProvider orderProvider = OrderProvider();
  SellProvider sellProvider = SellProvider();
  ValueNotifier<DateTime?> startDateNotifier = ValueNotifier(null);
  ValueNotifier<DateTime?> endDateNotifier = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: Column(
        children: [
          filterBar(),
          Expanded(child: orders()),
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
                  startDateNotifier.value = DateTime.now().subtract(const Duration(days: 1));
                  endDateNotifier.value = DateTime.now();
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

  FutureBuilder<List<OrderItem>> orders() {
    return FutureBuilder(
      future: orderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100)),
      builder: (context, ordersSnapshot) {
        if (ordersSnapshot.hasData) {
          return ListView.builder(
            itemCount: ordersSnapshot.data!.length,
            itemBuilder: (context, index) {
              return FutureBuilder(
                  future: sellProvider.getItemByOrderId(ordersSnapshot.data![index].id!),
                  builder: (context, sellItemsSnapshot) {
                    List<SellItem> sellitems = sellItemsSnapshot.data ?? [];
                    return SmallItemCard(
                      title: Column(
                        children: [
                          Text(ordersSnapshot.data![index].createAt.toString()),
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
                            orderProvider.delete(ordersSnapshot.data![index].id!);
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
                  });
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
