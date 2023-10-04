import 'package:flutter/material.dart';
import 'package:pos/store/model/customer.dart';
import 'package:pos/store/model/order.dart';
import 'package:pos/view/order_history.dart';

class OrderOverview extends StatefulWidget {
  const OrderOverview({super.key});

  @override
  State<OrderOverview> createState() => _OrderOverviewState();
}

class _OrderOverviewState extends State<OrderOverview> {
  final CustomerProvider customerProvider = CustomerProvider();
  final OrderProvider orderProvider = OrderProvider();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Overview'),
      ),
      body: FutureBuilder(
          future: customerProvider.getAll(),
          builder: (context, AsyncSnapshot<List<Customer>> allCustomerSnapshot) {
            if (allCustomerSnapshot.hasData) {
              return GridView.builder(
                itemCount: allCustomerSnapshot.data!.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                ),
                itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OrderHistory(
                                      customerId: allCustomerSnapshot.data![index].id,
                                      startDate: DateTime(2000),
                                      endDate: DateTime(2100),
                                    )));
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                allCustomerSnapshot.data![index].name,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                allCustomerSnapshot.data![index].phone,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                          Text(
                            allCustomerSnapshot.data![index].address,
                            style: const TextStyle(fontSize: 20),
                          ),
                          FutureBuilder(
                            future: () async {
                              if (allCustomerSnapshot.data![index].id == null) {
                                return null;
                              }
                              return await orderProvider.getAllFromCustomerIdandDateRange(allCustomerSnapshot.data![index].id!, DateTime(2000), DateTime(2100));
                            }(),
                            builder: (context, ordersSnapshot) {
                              if (ordersSnapshot.hasData) {
                                return Column(
                                  children: [
                                    Text(
                                      '訂單數: ${ordersSnapshot.data!.length.toString()}',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    Text(
                                      '總金額: ${ordersSnapshot.data!.fold(0, (previousValue, element) => (previousValue + element.totalPrice).toInt())}',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ],
                                );
                              } else {
                                return const SizedBox();
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}