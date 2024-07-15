import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos/tool/calculate_text_size.dart';
import 'package:intl/intl.dart';

class PieChartAndDetail extends StatefulWidget {
  final String title;
  final List<String> itemNames;
  final List<double> itemValues;
  final bool showPercentages;
  const PieChartAndDetail({
    super.key,
    required this.title,
    required this.itemNames,
    required this.itemValues,
    this.showPercentages = true,
  });

  @override
  State<PieChartAndDetail> createState() => _PieChartAndDetailState();
}

class _PieChartAndDetailState extends State<PieChartAndDetail> {
  int touchedIndex = -1;
  @override
  Widget build(BuildContext context) {
    //包含圓餅圖與客戶資訊的卡片
    List<PieChartSectionData> pieChartSectionDataList = [];
    List<Widget> customerInfo = [];
    double w = MediaQuery.of(context).size.width;
    double maxTextWidth = 0;
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink, Colors.teal, Colors.indigo, Colors.lime];
    double total = widget.itemValues.fold(0, (previousValue, element) => previousValue + element);
    for (int index = 0; index < widget.itemNames.length; index++) {
      double customerTotal = widget.itemValues[index];

      pieChartSectionDataList.add(PieChartSectionData(
        color: colors[index % colors.length],
        value: customerTotal,
        title: '${(customerTotal / total * 100).toStringAsFixed(2)}%',
        radius: index == touchedIndex ? 100 : 80,
        titleStyle: const TextStyle(fontSize: 20),
        showTitle: widget.showPercentages && (customerTotal / total * 100) > 5,
      ));
      customerInfo.add(MouseRegion(
        onHover: (event) {
          setState(() {
            touchedIndex = index;
          });
        },
        onExit: (event) {
          setState(() {
            touchedIndex = -1;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: colors[index % colors.length],
              ),
              Text('${widget.itemNames[index]}：\$${formatCurrency(customerTotal)}'),
            ],
          ),
        ),
      ));
      maxTextWidth = max(maxTextWidth, calculateTextSize(context, '${widget.itemNames[index]}：\$$customerTotal').width);
    }
    return Card(
      child: Column(
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 20)),
          Wrap(
            children: [
              SizedBox(
                width: max(250, w * 0.25),
                height: max(250, w * 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: max(250, w * 0.25) * 0.2,
                      pieTouchData: total != 0
                          ? PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                setState(() {
                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            )
                          : null,
                      sectionsSpace: 3,
                      sections: pieChartSectionDataList,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: max(250, w * 0.25) - 60,
                    width: maxTextWidth * 1.4,
                    child: ListView(
                      children: customerInfo,
                    ),
                  ),
                  SizedBox(
                    width: maxTextWidth * 1.4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            color: Colors.grey,
                          ),
                          Text('總金額：\$${formatCurrency(total)}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Function                                  */
  /* -------------------------------------------------------------------------- */
  String formatCurrency(double amount) {
    final format = NumberFormat("#,##0.00", "en_US");
    return format.format(amount);
  }
}
