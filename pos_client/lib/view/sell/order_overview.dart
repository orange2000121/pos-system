import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/store/model/sell/customer.dart';
import 'package:pos/store/model/sell/order.dart';
import 'package:pos/store/model/sell/sell.dart';
import 'package:pos/template/charts/pie_chart_and_detail.dart';
import 'package:pos/template/date_picker.dart';
import 'package:pos/view/sell/order_history.dart';

class OrderOverview extends StatefulWidget {
  const OrderOverview({super.key});

  @override
  State<OrderOverview> createState() => _OrderOverviewState();
}

class _OrderOverviewState extends State<OrderOverview> {
  final CustomerProvider customerProvider = CustomerProvider();
  final OrderProvider orderProvider = OrderProvider();
  final SellProvider sellProvider = SellProvider();
  final ValueNotifier<DateTime?> startDateNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> endDateNotifier = ValueNotifier(null);
  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    //這個月的起始日期與結束日期
    startDateNotifier.value = DateTime(now.year, now.month, 1);
    endDateNotifier.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('訂單總覽'),
        flexibleSpace: Center(
          child: filterBar(
            startDateNotifier: startDateNotifier,
            endDateNotifier: endDateNotifier,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
      body: Column(
        children: [
          FutureBuilder(
              future: customerProvider.getAll(),
              builder: (context, AsyncSnapshot<List<Customer>> customersSnapshot) {
                if (customersSnapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customerOrderHorList(customersSnapshot),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FutureBuilder(
                          future: () async {
                            return await orderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
                          }(),
                          builder: (context, ordersSnapshot) {
                            if (ordersSnapshot.hasData) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height - 200 - 138,
                                child: ListView(
                                  children: [
                                    Wrap(
                                      children: [
                                        customerChartCard(ordersSnapshot, customersSnapshot),
                                        FutureBuilder(
                                          future: productChartCard(ordersSnapshot),
                                          initialData: const SizedBox(),
                                          builder: (BuildContext context, AsyncSnapshot productChartSnapshot) {
                                            return productChartSnapshot.data ?? const SizedBox();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }),
        ],
      ),
    );
  }

  SizedBox customerOrderHorList(AsyncSnapshot<List<Customer>> allCustomerSnapshot) {
    //列出所有的客戶，並顯示他們的訂單數量與總金額，點擊後進入訂單紀錄
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: allCustomerSnapshot.data!.length + 1,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          try {
            return SizedBox(
              width: 200,
              child: customerInfoCard(context, allCustomerSnapshot.data![index]),
            );
          } catch (e) {
            return SizedBox(
              width: 200,
              child: customerInfoCard(context, Customer('未選擇客戶', '', '', '')),
            );
          }
        },
      ),
    );
  }

  Card customerInfoCard(BuildContext context, Customer customer) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OrderHistory(
                        customerId: customer.id,
                        startDate: startDateNotifier.value ?? DateTime(2000),
                        endDate: endDateNotifier.value ?? DateTime(2100),
                      )));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  customer.phone,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            Text(
              customer.address,
              style: const TextStyle(fontSize: 20),
            ),
            FutureBuilder(
              future: () async {
                return await orderProvider.getAllFromCustomerIdAndDateRange(customer.id, startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
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
  }

  Widget customerChartCard(AsyncSnapshot<List<OrderItem>> ordersSnapshot, AsyncSnapshot<List<Customer>> allCustomerSnapshot) {
    //包含圓餅圖與客戶資訊的卡片
    List<String> customerNames = [];
    List<double> customerValues = [];
    List<Customer> customers = [];
    customers += allCustomerSnapshot.data!;
    customers.add(Customer('未選擇客戶', '', '', ''));
    customers.asMap().forEach((index, customer) {
      double customerTotal = 0;
      for (OrderItem order in ordersSnapshot.data!) {
        if (order.customerId == customer.id) {
          customerTotal += order.totalPrice;
        }
      }
      customerNames.add(customer.name);
      customerValues.add(customerTotal);
    });
    return PieChartAndDetail(title: '客戶', itemNames: customerNames, itemValues: customerValues);
  }

  Future<Widget> productChartCard(AsyncSnapshot<List<OrderItem>> orderSnapshot) async {
    Map<String, double> productSales = {};
    for (OrderItem order in orderSnapshot.data!) {
      List<SellItem> sellItems = await sellProvider.getItemByOrderId(order.id!);
      for (SellItem sellItem in sellItems) {
        if (productSales.containsKey(sellItem.name)) {
          productSales[sellItem.name] = productSales[sellItem.name]! + sellItem.price * sellItem.quantity;
        } else {
          productSales[sellItem.name] = sellItem.price * sellItem.quantity;
        }
      }
    }
    final productSort = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return PieChartAndDetail(title: '產品銷售', itemNames: productSort.map((e) => e.key).toList(), itemValues: productSort.map((e) => e.value).toList());
  }

  // List<PieChartSectionData> showSections(AsyncSnapshot<List<OrderItem>> ordersSnapshot, AsyncSnapshot<List<Customer>> allCustomerSnapshot, ValueNotifier<dynamic> touchedIndexNotifier) {
  //   List<PieChartSectionData> pieChartSectionDataList = [];
  //   List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink, Colors.teal, Colors.indigo, Colors.lime];
  //   double total = ordersSnapshot.data!.fold(0, (previousValue, element) => (previousValue + element.totalPrice));
  //   allCustomerSnapshot.data!.asMap().forEach((index, customer) {
  //     double customerTotal = 0;
  //     for (OrderItem order in ordersSnapshot.data!) {
  //       if (order.customerId == customer.id) {
  //         customerTotal += order.totalPrice;
  //       }
  //     }
  //     pieChartSectionDataList.add(PieChartSectionData(
  //       color: colors[index % colors.length],
  //       value: customerTotal,
  //       title: '${customer.name} ${(customerTotal / total * 100).toStringAsFixed(2)}%',
  //       radius: index == touchedIndexNotifier.value ? 100 : 80,
  //       titleStyle: const TextStyle(fontSize: 20),
  //     ));
  //   });
  //   return pieChartSectionDataList;
  // }
}
