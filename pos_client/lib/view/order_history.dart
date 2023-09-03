import 'package:flutter/material.dart';
import 'package:pos/model/order.dart';
import 'package:pos/model/sell.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  OrderProvider orderProvider = OrderProvider();
  Widget orderContent(int orderId) {
    SellProvider orderProvider = SellProvider();
    return AlertDialog(
      title: const Text('Order Content'),
      content: SizedBox(
        width: MediaQuery.of(context).size.height * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: FutureBuilder(
          future: orderProvider.getItemByOrderId(orderId),
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
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => orderContent(snapshot.data![index].id!),
                    );
                  },
                  child: ListTile(
                    title: Text(snapshot.data![index].createAt.toString()),
                    subtitle: Text(snapshot.data![index].totalPrice.toString()),
                  ),
                );
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
