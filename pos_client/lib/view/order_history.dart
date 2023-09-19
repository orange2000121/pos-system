import 'package:flutter/material.dart';
import 'package:pos/store/model/order.dart';
import 'package:pos/store/model/sell.dart';
import 'package:pos/template/data_retrieval_widget.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  OrderProvider orderProvider = OrderProvider();
  SellProvider sellProvider = SellProvider();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: FutureBuilder(
        future: orderProvider.getAll(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.hasData) {
            return ListView.builder(
              itemCount: ordersSnapshot.data!.length,
              itemBuilder: (context, index) {
                // return InkWell(
                //   onTap: () {
                //     showDialog(
                //       context: context,
                //       builder: (context) => orderContent(snapshot.data![index].id!),
                //     );
                //   },
                //   child: ListTile(
                //     title: Text(snapshot.data![index].createAt.toString()),
                //     subtitle: Text(snapshot.data![index].totalPrice.toString()),
                //   ),
                // );
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
                      );
                    });
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
