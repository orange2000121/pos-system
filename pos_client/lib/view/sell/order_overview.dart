import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/store/model/sell/customer.dart';
import 'package:pos/store/model/sell/order.dart';
import 'package:pos/template/date_picker.dart';
import 'package:pos/tool/calculate_text_size.dart';
import 'package:pos/view/sell/order_history.dart';

class OrderOverview extends StatefulWidget {
  const OrderOverview({super.key});

  @override
  State<OrderOverview> createState() => _OrderOverviewState();
}

class _OrderOverviewState extends State<OrderOverview> {
  final CustomerProvider customerProvider = CustomerProvider();
  final OrderProvider orderProvider = OrderProvider();
  final ValueNotifier<DateTime?> startDateNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> endDateNotifier = ValueNotifier(null);
  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    //這個月的起始日期與結束日期
    startDateNotifier.value = DateTime(now.year, now.month, 1);
    endDateNotifier.value = DateTime(now.year, now.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單總覽'),
      ),
      body: Column(
        children: [
          filterBar(
            startDateNotifier: startDateNotifier,
            endDateNotifier: endDateNotifier,
            onChanged: () => setState(() {}),
          ),
          FutureBuilder(
              future: customerProvider.getAll(),
              builder: (context, AsyncSnapshot<List<Customer>> allCustomerSnapshot) {
                if (allCustomerSnapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: allCustomerSnapshot.data!.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 200,
                              child: Card(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => OrderHistory(
                                                  customerId: allCustomerSnapshot.data![index].id,
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
                                          return await orderProvider.getAllFromCustomerIdAndDateRange(
                                              allCustomerSnapshot.data![index].id!, startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
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
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FutureBuilder(
                          future: () async {
                            return await orderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
                          }(),
                          builder: (context, ordersSnapshot) {
                            ValueNotifier touchedIndexNotifier = ValueNotifier(-1);
                            if (ordersSnapshot.hasData) {
                              return Wrap(
                                children: [
                                  ValueListenableBuilder(
                                      valueListenable: touchedIndexNotifier,
                                      builder: (context, touchedIndex, child) {
                                        return customerChartCard(touchedIndexNotifier, ordersSnapshot, allCustomerSnapshot);
                                      }),
                                ],
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

  Widget customerChartCard(ValueNotifier<dynamic> touchedIndexNotifier, AsyncSnapshot<List<OrderItem>> ordersSnapshot, AsyncSnapshot<List<Customer>> allCustomerSnapshot) {
    List<PieChartSectionData> pieChartSectionDataList = [];
    List<Widget> customerInfo = [];
    double w = MediaQuery.of(context).size.width;
    double maxTextWidth = 0;
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink, Colors.teal, Colors.indigo, Colors.lime];
    double total = ordersSnapshot.data!.fold(0, (previousValue, element) => (previousValue + element.totalPrice));
    allCustomerSnapshot.data!.asMap().forEach((index, customer) {
      double customerTotal = 0;
      for (OrderItem order in ordersSnapshot.data!) {
        if (order.customerId == customer.id) {
          customerTotal += order.totalPrice;
        }
      }
      pieChartSectionDataList.add(PieChartSectionData(
        color: colors[index % colors.length],
        value: customerTotal,
        title: '${(customerTotal / total * 100).toStringAsFixed(2)}%',
        radius: index == touchedIndexNotifier.value ? 100 : 80,
        titleStyle: const TextStyle(fontSize: 20),
      ));
      customerInfo.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              color: colors[index % colors.length],
            ),
            Text('${customer.name}：\$$customerTotal'),
          ],
        ),
      ));
      maxTextWidth = min(max(maxTextWidth, calculateTextSize(context, '${customer.name}：\$$customerTotal').width), w * 0.3) + 50;
    });
    return SizedBox(
      width: w * 0.5,
      height: w * 0.5 * 9 / 16,
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            touchedIndexNotifier.value = -1;
                            return;
                          }
                          touchedIndexNotifier.value = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        },
                      ),
                      // centerSpaceRadius: w * 0.05,
                      sectionsSpace: 3,
                      sections: pieChartSectionDataList,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: w * 0.20,
              width: maxTextWidth,
              child: ListView(
                children: customerInfo,
              ),
            )
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showSections(AsyncSnapshot<List<OrderItem>> ordersSnapshot, AsyncSnapshot<List<Customer>> allCustomerSnapshot, ValueNotifier<dynamic> touchedIndexNotifier) {
    List<PieChartSectionData> pieChartSectionDataList = [];
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink, Colors.teal, Colors.indigo, Colors.lime];
    double total = ordersSnapshot.data!.fold(0, (previousValue, element) => (previousValue + element.totalPrice));
    allCustomerSnapshot.data!.asMap().forEach((index, customer) {
      double customerTotal = 0;
      for (OrderItem order in ordersSnapshot.data!) {
        if (order.customerId == customer.id) {
          customerTotal += order.totalPrice;
        }
      }
      pieChartSectionDataList.add(PieChartSectionData(
        color: colors[index % colors.length],
        value: customerTotal,
        title: '${customer.name} ${(customerTotal / total * 100).toStringAsFixed(2)}%',
        radius: index == touchedIndexNotifier.value ? 100 : 80,
        titleStyle: const TextStyle(fontSize: 20),
      ));
    });
    return pieChartSectionDataList;
  }
}
